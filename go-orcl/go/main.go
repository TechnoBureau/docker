package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"tgo/common"
	"tgo/models"
	"tgo/routes"
	"time"

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
	log = logrus.New() // Initialize the global log variable
	common.SetLogger(log)

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

	// Run the server in a separate goroutine
	server := &http.Server{
		Addr:    ":8081",
		Handler: router,
	}

	go func() {
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.WithError(err).Fatal("Failed to start server")
		}
	}()

	// Set up signal handling for graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt)

	// Block until a signal is received
	<-quit
	log.Info("graceful shutdown initiated")

	// Set a deadline for the graceful shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 500*time.Second)
	defer cancel()

	// Attempt to gracefully close the server
	if err := server.Shutdown(ctx); err != nil {
		// Use the logger that was set up before graceful shutdown
		log.WithError(err).Fatal("failed to do graceful shutdown")
	}

	log.Info("graceful shutdown completed")

}
