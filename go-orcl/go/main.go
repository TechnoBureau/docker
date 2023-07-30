package main

import (
	"tgo/common"
	"tgo/models"
	"tgo/routes"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

// Define a custom context key for the trace ID
type contextKey string

const (
	traceIDKey contextKey = "traceID"
)

var log *logrus.Logger

func main() {
	// Set up logger
	logger := logrus.New()
	common.SetLogger(logger)

	// Create a new Gin router
	router := gin.New()

	// Set up custom logging middleware
	router.Use(common.CustomLoggingMiddleware())

	// Set up db
	db, err := models.NewDB()
	if err != nil {
		log.WithError(err).Fatal("Failed to connect to the database")
	}
	defer db.Close()

	// Inject DB into router middleware
	router.Use(func(c *gin.Context) {
		c.Set("db", db)
		//c.Set("log", log)
		c.Next()
	})

	// Set up routes
	routes.SetupAlbumRoutes(router)
	routes.SetupHealthRoutes(router)
	routes.SetupFetchAPIRoutes(router)

	// Run the server
	if err := router.Run(":8081"); err != nil {
		log.WithError(err).Fatal("Failed to start server")
	}

}
