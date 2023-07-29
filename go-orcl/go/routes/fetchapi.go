package routes

import (
	"tgo/controllers"

	"github.com/gin-gonic/gin"
)

// SetupAlbumRoutes sets up the album routes.
func SetupFetchAPIRoutes(router *gin.Engine) {
	router.GET("/fetchapi", func(c *gin.Context) {
		controllers.GetAPIData(c)
	})

}
