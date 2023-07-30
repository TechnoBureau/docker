package main

import (
	"net/http"
	"os"
	"tgo/models"
	"tgo/routes"

	"github.com/gin-gonic/gin"

	"github.com/sirupsen/logrus"
	ginlogrus "github.com/toorop/gin-logrus"
)

var (
	log *logrus.Logger
)

func main() {
	// Set up logger
	setupLogger()

	// Create a new Gin router
	router := gin.New()

	// Add logrus Logger middleware to Gin
	router.Use(ginlogrus.Logger(log), gin.Recovery())

	// Set up router
	//setupRouter(router)

	// Set up db
	db, err := models.NewDB()
	log.Print(err)
	defer db.Close()

	// Inject DB into router
	router.Use(func(c *gin.Context) {
		if db == nil {
			// Handle the error gracefully, for example, log it and send an error response
			log.Errorln("Database connection is nil")
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
			c.Abort() // This will stop the execution of subsequent middleware and handlers
			return
		}
		c.Set("db", db)
		c.Next()
	})

	// Set up the album routes
	routes.SetupAlbumRoutes(router)

	// Set up the Health routes
	routes.SetupHealthRoutes(router)

	//Fetch API
	routes.SetupFetchAPIRoutes(router)

	// Run the server
	if err := router.Run(":8081"); err != nil {
		log.WithError(err).Fatal("Failed to start server")
	}
}

func setupLogger() {
	var ok bool
	Environment, ok := os.LookupEnv("GIN_MODE")

	// Create a new instance of logrus.Logger
	log = logrus.New()

	if ok {
		if Environment == "release" {
			// Set log format to JSON
			log.SetFormatter(&logrus.JSONFormatter{
				TimestampFormat:   "2023-04-02T15:04:05.000Z05:30",
				DisableHTMLEscape: true,
				PrettyPrint:       false,
				FieldMap: logrus.FieldMap{
					logrus.FieldKeyTime:  "timestamp",
					logrus.FieldKeyLevel: "level",
					logrus.FieldKeyMsg:   "message",
				},
			})
		}
	}

	// Set log level to info
	log.SetLevel(logrus.InfoLevel)
}

// func setupRouter(router) *gin.Engine {

// 	return router
// }
