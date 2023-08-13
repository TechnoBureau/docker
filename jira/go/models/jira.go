package models

import (
	"database/sql"
	"os"
	"strings"
	"time"
)

// Define a struct to hold the selective issue fields
type Issue struct {
	Date        time.Time      `json:"Date"`
	TicketID    string         `json:"TicketID"`
	Summary     string         `json:"Summary"`
	Assignee    string         `json:"Assignee"`
	TimeSpent   int            `json:"TimeSpent"`
	Status      string         `json:"Status"`
	Components  string         `json:"Components"`
	FixVersions string         `json:"FixVersions"`
	Comment     string         `json:"Comment"`
	Worklogs    []WorklogEntry `json:"Worklogs"`
}

// Define a struct to hold the worklog entry details
type WorklogEntry struct {
	Author    string    `json:"Author"`
	Comment   string    `json:"Comment"`
	TimeSpent int       `json:"timeSpent"`
	Created   time.Time `json:"Created"`
}

var TeamMembers []string

func init() {
	// Retrieve the value of the environment variable
	teamMembersStr := os.Getenv("TEAM_MEMBERS")

	if teamMembersStr != "" {
		members := strings.Split(teamMembersStr, "|")
		for _, member := range members {
			// Trim spaces from each member
			normalizedMember := strings.TrimSpace(member)
			TeamMembers = append(TeamMembers, normalizedMember)
		}
	}
}

//var Issue common.Issue

// GetIssues retrieves all issues from the database
func GetIssues(db *sql.DB) ([]Issue, error) {
	var issues []Issue

	rows, err := db.Query("SELECT * FROM worklogs")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var issue Issue
		err := rows.Scan(&issue.Date, &issue.TicketID, &issue.Summary, &issue.Assignee, &issue.TimeSpent, &issue.Status, &issue.Components, &issue.FixVersions)
		if err != nil {
			return nil, err
		}
		issues = append(issues, issue)
	}

	err = rows.Err()
	if err != nil {
		return nil, err
	}

	return issues, nil
}

// GetIssueByID retrieves an issue by its ID from the database
func GetIssueByID(db *sql.DB, key string) (*Issue, error) {
	var issue Issue

	row := db.QueryRow("SELECT * FROM worklogs WHERE TicketID = $1", key)
	err := row.Scan(&issue.Date, &issue.TicketID, &issue.Summary)
	if err != nil {
		return nil, err
	}

	return &issue, nil
}

// CreateIssue creates a new issue in the database
func CreateIssue(db *sql.DB, issue *Issue) (*Issue, error) {

	_, err := db.Exec(`
		INSERT INTO worklogs (Date, TicketID, summary, status, components, fixversions, assignee,timespent)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		ON CONFLICT (TicketID, DATE(Date)) DO UPDATE
		SET
			Date = EXCLUDED.Date,
			TicketID = EXCLUDED.TicketID,
			summary = EXCLUDED.summary,
			status = EXCLUDED.status,
			components = EXCLUDED.components,
			fixversions = EXCLUDED.fixversions,
			assignee = EXCLUDED.assignee,
			timespent = EXCLUDED.timespent
		RETURNING TicketID`,
		issue.Date, issue.TicketID, issue.Summary, issue.Status, issue.Components, issue.FixVersions,
		issue.Assignee, issue.TimeSpent)
	if err != nil {
		return nil, err
	}
	return issue, nil
}

// DeleteIssue deletes an issue from the database by its ID
func DeleteIssue(db *sql.DB, key string) error {
	_, err := db.Exec("DELETE FROM worklogs WHERE TicketID = $1", key)
	if err != nil {
		return err
	}
	return nil
}
