package routes

import (
	"tgo/controllers"

	"github.com/gin-gonic/gin"
)

// SetupAlbumRoutes sets up the album routes.
func SetupAlbumRoutes(router *gin.Engine) {
	router.GET("/albums", func(c *gin.Context) {
		controllers.GetAlbums(c)
	})
	router.GET("/albums/:id", func(c *gin.Context) {
		controllers.GetAlbumByID(c)
	})
	router.POST("/albums", func(c *gin.Context) {
		controllers.PostAlbum(c)
	})
	router.DELETE("/albums/:id", func(c *gin.Context) {
		controllers.DeleteAlbum(c)
	})
}
