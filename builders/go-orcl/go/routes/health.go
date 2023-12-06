package routes

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// SetupAlbumRoutes sets up the album routes.
func SetupHealthRoutes(router *gin.Engine) {
	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "ok",
		})
	})
}
