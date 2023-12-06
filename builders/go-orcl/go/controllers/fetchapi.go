package controllers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
	ginlogrus "github.com/sirupsen/logrus"
)

// GetAlbums retrieves all albums from the database
func GetAPIData(c *gin.Context) {

	// Get the API URL from the environment variable
	apiURL := os.Getenv("API_URL")
	if apiURL == "" {
		ginlogrus.WithFields(ginlogrus.Fields{}).Error("API URL not defined")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "API URL not defined"})
		return
	}

	// Make an HTTP GET request to the API
	resp, err := http.Get(apiURL)
	if err != nil {
		ginlogrus.WithFields(ginlogrus.Fields{
			"error": err,
		}).Error("Failed to get data from API URL")
		c.JSON(http.StatusInternalServerError, gin.H{"error": err})
		return
	}
	defer resp.Body.Close()

	// Parse the JSON response
	var response interface{}
	err = json.NewDecoder(resp.Body).Decode(&response)
	if err != nil {
		ginlogrus.WithFields(ginlogrus.Fields{
			"error": err,
		}).Error(fmt.Sprintf("Error: %v", err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": err})
		return
	}

	// Get the fields to select from the environment variable
	fields := os.Getenv("SELECTED_FIELDS")
	selectedFields := make(map[string]bool)
	if fields != "" {
		fieldList := strings.Split(fields, ",")
		for _, field := range fieldList {
			selectedFields[field] = true
		}
	}

	// Create a dynamic response structure based on the selected fields
	responseStruct := selectFields(response, selectedFields)

	c.JSON(http.StatusOK, responseStruct)
}

func selectFields(data interface{}, selectedFields map[string]bool) interface{} {
	switch data := data.(type) {
	case map[string]interface{}:
		selectedData := make(map[string]interface{})
		for key, value := range data {
			if selectedFields[key] {
				selectedData[key] = value
			} else if nestedData, ok := value.(map[string]interface{}); ok {
				selectedData[key] = selectFields(nestedData, selectedFields)
			} else if nestedData, ok := value.([]interface{}); ok {
				selectedData[key] = joinArrayValues(nestedData, selectedFields)
			}
		}
		return selectedData
	case []interface{}:
		return joinArrayValues(data, selectedFields)
	default:
		return data
	}
}

func joinArrayValues(data []interface{}, selectedFields map[string]bool) []interface{} {
	var selectedData []interface{}
	for _, item := range data {
		if nestedData, ok := item.(map[string]interface{}); ok {
			selectedData = append(selectedData, selectFields(nestedData, selectedFields))
		} else if nestedData, ok := item.([]interface{}); ok {
			selectedData = append(selectedData, joinArrayValues(nestedData, selectedFields))
		} else {
			selectedData = append(selectedData, item)
		}
	}
	return selectedData
}
