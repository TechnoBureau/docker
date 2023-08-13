package routes

import (
	"os"
	"tgo/common"
	"tgo/controllers"

	"github.com/gin-gonic/gin"
)

// SetupAlbumRoutes sets up the album routes.
func SetupJira(router *gin.Engine) {
	JIRA_URL, ok := os.LookupEnv("JIRA_URL")
	if !ok {
		return
	}
	JIRA_PAT, ok := os.LookupEnv("JIRA_TOKEN")
	if !ok {
		return
	}
	common.InitJiraClient(JIRA_PAT, JIRA_URL)

	router.GET("/jira", func(c *gin.Context) {
		controllers.GetiTracData(c)
	})

}
