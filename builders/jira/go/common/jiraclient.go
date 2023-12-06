package common

import (
	"reflect"
	"strings"
	"tgo/models"
	"time"

	jira "github.com/andygrunwald/go-jira/v2/onpremise"
)

var jiraClient *jira.Client

func InitJiraClient(token, jiraURL string) {
	tp := jira.BearerAuthTransport{
		Token: token,
	}
	client, err := jira.NewClient(jiraURL, tp.Client())
	if err != nil {
		panic(err)
	}
	jiraClient = client
}

// GetJiraClient returns the initialized Jira client.
func GetJiraClient() *jira.Client {
	return jiraClient
}

// Helper function to extract values from Jira issue fields
func GetIssueFieldValues(fieldList interface{}) string {
	var values []string

	switch reflect.TypeOf(fieldList).Kind() {
	case reflect.Slice:
		s := reflect.ValueOf(fieldList)
		for i := 0; i < s.Len(); i++ {
			field := s.Index(i).Elem().FieldByName("Name").String()
			values = append(values, field)
		}
	}

	return strings.Join(values, ", ")
}

// Check if the given assignee name is in the team member's list
func IsTeamMember(assignee string) bool {
	for _, member := range models.TeamMembers {
		if strings.EqualFold(assignee, member) {
			return true
		}
	}
	return false
}

// Find the last commenter from the ticket
func GetLastTeamMemberComment(issue *jira.Issue) (string, string, string) {
	if issue == nil || issue.Fields == nil || issue.Fields.Comments == nil {
		return "", "", "" // Return empty strings if issue or its fields are nil
	}

	var lastTeamMemberName, lastCommentText, lastCommentDate string

	// Loop through the comments in reverse order to find the last comment by a team member
	for i := len(issue.Fields.Comments.Comments) - 1; i >= 0; i-- {
		if issue.Fields.Comments.Comments[i] != nil {
			commenter := issue.Fields.Comments.Comments[i].Author.DisplayName
			commentText := issue.Fields.Comments.Comments[i].Body
			commentDate := issue.Fields.Comments.Comments[i].Created
			if IsTeamMember(commenter) {
				lastTeamMemberName = commenter
				lastCommentText = commentText
				lastCommentDate = commentDate
				break
			}
		}
	}

	return lastTeamMemberName, lastCommentText, lastCommentDate
}

// Find the last team member from worklog entries
func GetLastTeamMemberFromWorklogs(worklogEntries []models.WorklogEntry) (string, string, time.Time) {
	var lastTeamMember, lastComment string
	var lastCommentDate time.Time
	// for i := len(worklogEntries) - 1; i >= 0; i-- {
	// 	if IsTeamMember(worklogEntries[i].Author) {
	// 		lastTeamMember = worklogEntries[i].Author
	// 		lastComment = worklogEntries[i].Comment
	// 		lastCommentDate = worklogEntries[i].Created
	// 		break
	// 	}
	// }
	if len(worklogEntries) == 0 {
		return "", "", time.Time{}
	}
	lastTeamMember = worklogEntries[len(worklogEntries)-1].Author
	lastComment = worklogEntries[len(worklogEntries)-1].Comment
	lastCommentDate = worklogEntries[len(worklogEntries)-1].Created

	return lastTeamMember, lastComment, lastCommentDate
}
