package controllers

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"tgo/common"
	"tgo/models"
	"time"

	jira "github.com/andygrunwald/go-jira/v2/onpremise"
	"github.com/avast/retry-go"
	"github.com/gin-gonic/gin"
)

// Declare a mutex to guard access to the processedIssues slice
var processedIssuesMu sync.Mutex

// Declare a slice to collect processed issues
var processedIssues []models.Issue

// GetiTracData retrieves data from Jira using the provided JQL query
func GetiTracData(c *gin.Context) {
	JQL := c.Query("jql")

	if JQL == "" {
		common.HandleLog(c, http.StatusBadRequest, "JQL parameter is missing", nil)
		return
	}

	jiraClient := common.GetJiraClient()
	if jiraClient == nil {
		common.HandleLog(c, http.StatusInternalServerError, "Jira client not initialized", nil)
		return
	}

	// Get the list of issues using JQL
	issues, err := getAllIssues(jiraClient, JQL)
	if err != nil {
		c.Error(err)
		common.HandleLog(c, http.StatusInternalServerError, "Failed to search for issues", nil)
		return
	}

	// Define batch size for processing
	batchSize := 10

	// Create a buffered channel to limit the number of concurrent goroutines
	concurrency := 5
	issueChan := make(chan jira.Issue, concurrency)

	// Use WaitGroup to wait for all workers to finish
	var wg sync.WaitGroup

	// Process issues in batches
	for i := 0; i < len(issues); i += batchSize {
		endIndex := i + batchSize
		if endIndex > len(issues) {
			endIndex = len(issues)
		}
		batch := issues[i:endIndex]

		// Start worker Goroutines
		for j := 0; j < concurrency; j++ {
			wg.Add(1)
			go processIssueWorker(jiraClient, issueChan, &wg, c)
		}

		// Send issues to worker Goroutines
		for _, issue := range batch {
			issueChan <- issue
		}
	}

	// Close the issue channel after sending all issues
	close(issueChan)

	// Wait for all workers to finish
	wg.Wait()

	// Respond with the consolidated response
	common.HandleLog(c, http.StatusOK, "Request processed", processedIssues)
}

func getAllIssues(client *jira.Client, jql string) ([]jira.Issue, error) {
	pageSize := 50
	startAt := 0
	var allIssues []jira.Issue

	for {
		options := &jira.SearchOptions{
			StartAt:    startAt,
			MaxResults: pageSize,
			Fields:     []string{"key"},
		}

		issues, _, err := client.Issue.Search(context.Background(), jql, options)
		if err != nil {
			return nil, err
		}

		if len(issues) == 0 {
			break
		}

		allIssues = append(allIssues, issues...)
		startAt += pageSize
	}

	return allIssues, nil
}

func processIssueWorker(client *jira.Client, issueChan <-chan jira.Issue, wg *sync.WaitGroup, c *gin.Context) {
	defer wg.Done() // Mark worker as done when finished

	for issue := range issueChan {
		processSingleIssue(client, issue, c)
	}
}

func processSingleIssue(client *jira.Client, issue jira.Issue, c *gin.Context) {
	db := c.MustGet("db").(*sql.DB)

	retryErr := retry.Do(
		func() error {
			fieldNames := []string{"created", "updated", "summary", "status", "components", "fixVersions", "assignee", "comment"}
			fieldNamesStr := strings.Join(fieldNames, ",")

			options := &jira.GetQueryOptions{
				Fields: fieldNamesStr,
			}

			// Get detailed issue information
			issueDetail, _, err := client.Issue.Get(context.Background(), issue.Key, options)
			if err != nil {
				c.Error(err)
				//	common.HandleLog(c, http.StatusInternalServerError, "Failed to get issue", nil)
				return err
			}

			// Process and format issue details
			updated, _, totalSpent, _, err := processIssueDetails(client, issueDetail)
			if err != nil {
				c.Error(err)
				//common.HandleLog(c, http.StatusInternalServerError, "Failed to process issue details", nil)
				return err
			}

			if common.IsTeamMember(issueDetail.Fields.Assignee.DisplayName) && isUpdatedThisWeek(updated) {

				// Insert the formatted issue into the database using models.CreateIssue
				issueModel := models.Issue{
					Date:        updated,
					TicketID:    issue.Key,
					Summary:     issueDetail.Fields.Summary,
					Status:      issueDetail.Fields.Status.Name,
					Components:  common.GetIssueFieldValues(issueDetail.Fields.Components),
					FixVersions: common.GetIssueFieldValues(issueDetail.Fields.FixVersions),
					Assignee:    issueDetail.Fields.Assignee.DisplayName,
					TimeSpent:   totalSpent,
					//	Comment:     comment, // Set the Comment field with the extracted value
					//Worklogs: worklogEntries,
				}

				_, err = models.CreateIssue(db, &issueModel)
				if err != nil {
					c.Error(err)
					//common.HandleLog(c, http.StatusInternalServerError, "Failed to insert issue into the database", nil)
					return err
				}
				// Lock mutex to access the processedIssues slice
				processedIssuesMu.Lock()
				processedIssues = append(processedIssues, issueModel)
				processedIssuesMu.Unlock()
			}
			return nil // Return nil on success
		},
		retry.Attempts(3),        // Number of retry attempts
		retry.Delay(time.Second), // Delay between retries
		retry.DelayType(retry.FixedDelay),
		retry.OnRetry(func(n uint, err error) {
			fmt.Printf("Retry attempt %d failed with error: %s\n", n, err)
		}),
	)

	if retryErr != nil {
		// Handle the error after retries
		fmt.Printf("Failed after retries: %s\n", retryErr)
	}
}

func processIssueDetails(client *jira.Client, issueDetail *jira.Issue) (time.Time, []models.WorklogEntry, int, string, error) {
	// Process created and updated timestamps
	updatedTime, err := processTimeFields(&issueDetail.Fields.Updated)
	if err != nil {
		// Handle error
		return time.Time{}, nil, 0, "", err
	}

	// Fetch worklogs
	worklogs, _, err := client.Issue.GetWorklogs(context.Background(), issueDetail.Key)
	if err != nil {
		return time.Time{}, nil, 0, "", err
	}

	// Process worklog entries
	var worklogEntries []models.WorklogEntry
	var totalSpent int

	for _, worklog := range worklogs.Worklogs {
		// Parse worklog.Created using the formatJiraTime function
		tmp, err := formatJiraTime(worklog.Created)
		if err != nil {
			// Handle error
			return time.Time{}, nil, 0, "", err
		}
		tmpFormatted := models.Time{Time: tmp}.FormatForDB()

		worklogEntry := models.WorklogEntry{
			Author:    worklog.Author.DisplayName,
			Comment:   worklog.Comment,
			TimeSpent: worklog.TimeSpentSeconds,
			Created:   tmpFormatted,
		}
		totalSpent += worklog.TimeSpentSeconds
		worklogEntries = append(worklogEntries, worklogEntry)
	}

	// Find the last team member from worklog entries
	worklogMember, worklogComment, worklogDate := common.GetLastTeamMemberFromWorklogs(worklogEntries)

	// If no worklog entries or no team member comments, use the last commenter from the ticket
	if worklogMember == "" {
		lastTeamMember, lastTeamMemberComment, lastCommentDate := common.GetLastTeamMemberComment(issueDetail)
		worklogMember = lastTeamMember
		worklogComment = lastTeamMemberComment
		if lastCommentDate != "" {
			tmp, err := time.Parse("2006-01-02T15:04:05.000-0700", lastCommentDate)
			if err != nil {
				// Handle error
				return time.Time{}, nil, 0, "", err
			}
			worklogDate = models.Time{Time: tmp}.FormatForDB()
		}
	}

	// If no team member comments found in the ticket, use the original assignee name
	if worklogMember == "" {
		worklogMember = issueDetail.Fields.Assignee.DisplayName
	}

	if worklogDate.IsZero() {
		worklogDate = updatedTime
	}

	// Assign the last team member's comment to the 'Comment' field
	comment := worklogComment
	updatedTime = worklogDate

	// Check if the current assignee is in the team member's list
	if !common.IsTeamMember(issueDetail.Fields.Assignee.DisplayName) {
		// Use the last team member as the AssigneeName
		issueDetail.Fields.Assignee.DisplayName = worklogMember
	}

	return updatedTime, worklogEntries, totalSpent, comment, nil
}

func convertToWorklogList(records []jira.WorklogRecord) []models.WorklogEntry {
	var worklogEntries []models.WorklogEntry

	for _, record := range records {
		tmp, err := formatJiraTime(record.Created)
		if err != nil {
			//	c.Error(err)
			return nil
		}
		tmp = models.Time{Time: tmp}.FormatForDB()
		//updated = tmp // Store formatted time
		worklogEntry := models.WorklogEntry{
			Author:    record.Author.DisplayName, // Replace with actual field name
			Comment:   record.Comment,            // Replace with actual field name
			TimeSpent: record.TimeSpentSeconds,   // Replace with actual field name
			Created:   tmp,                       // Replace with actual field name
		}

		worklogEntries = append(worklogEntries, worklogEntry)
	}

	return worklogEntries
}

func processTimeFields(updatedTime *jira.Time) (time.Time, error) {
	// // Process and format created and updated timestamps
	// created, err := formatJiraTime(createdTime)
	// if err != nil {
	// 	return time.Time{}, time.Time{}, err
	// }

	updated, err := formatJiraTime(updatedTime)
	if err != nil {
		return time.Time{}, err
	}

	return updated, nil
}

func formatJiraTime(jiraTime *jira.Time) (time.Time, error) {
	if jiraTime == nil {
		return time.Time{}, nil
	}

	t, err := time.Parse("2006-01-02T15:04:05.000-0700", time.Time(*jiraTime).Format("2006-01-02T15:04:05.000-0700"))
	if err != nil {
		return time.Time{}, err
	}

	return t, nil
}

func processWorklogs(worklogEntries []models.WorklogEntry) ([]models.WorklogEntry, int, error) {
	var totalSpent int

	// Process each worklog entry and calculate totalSpent
	for i := range worklogEntries {
		totalSpent += worklogEntries[i].TimeSpent
	}
	return worklogEntries, totalSpent, nil
}

// Function to check if a time is within the previous week
func isUpdatedThisWeek(updated time.Time) bool {
	// Calculate the desired previous week's start and end dates
	desiredWeekStart := time.Date(updated.Year(), 8, 7, 0, 0, 0, 0, updated.Location())
	// If the updated time is before the desired week start, set it to the previous year
	if updated.Before(desiredWeekStart) {
		desiredWeekStart = desiredWeekStart.AddDate(-1, 0, 0)
	}
	desiredWeekEnd := desiredWeekStart.AddDate(0, 0, 7)

	// Check if the "updated" time is within the previous week
	isUpdatedThisWeek := updated.After(desiredWeekStart) && updated.Before(desiredWeekEnd)

	return isUpdatedThisWeek
}
