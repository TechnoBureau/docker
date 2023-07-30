package common

import (
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
)

var (
	log        *logrus.Logger
	traceIDKey = "traceID"
)

// SetLogger sets the logrus logger instance to be used in the controllers and models package
func SetLogger(logger *logrus.Logger) {
	log = logger
	//logrus.StandardLogger().Out = ioutil.Discard

	// Set log format to JSON in release mode
	if Environment, ok := os.LookupEnv("GIN_MODE"); ok && Environment == "release" {
		log.SetFormatter(&logrus.JSONFormatter{})
	}

	// Set log level based on the LOG_LEVEL environment variable
	logLevelEnv, ok := os.LookupEnv("LOG_LEVEL")
	if !ok {
		// Default log level is set to "info" if LOG_LEVEL is not provided
		logLevelEnv = "error"
	}

	// Parse the log level from the environment variable
	logLevel, err := logrus.ParseLevel(logLevelEnv)
	if err != nil {
		log.WithError(err).Warnf("Invalid log level '%s'. Defaulting to 'info'.", logLevelEnv)
		logLevel = logrus.InfoLevel
	}

	log.SetLevel(logLevel)
}

// CustomLoggingMiddleware is a middleware that logs request information
func CustomLoggingMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Generate a new trace ID for each request
		traceID := generateTraceID()
		c.Set(string(traceIDKey), traceID)
		//c.Writer.Header().Set("Content-Type", "application/json")

		// Process the request
		c.Next()

		// logEntry := log.WithFields(logrus.Fields{
		// 	"traceID":  c.GetString(string(traceIDKey)), // Get the traceID from the context
		// 	"status":   c.Writer.Status(),
		// 	"method":   c.Request.Method,
		// 	"path":     c.Request.URL.Path,
		// 	"ip":       c.ClientIP(),
		// 	"proto":    c.Request.Proto,
		// 	"remoteIP": c.RemoteIP(),
		// })
		// Message, exists := c.Get("msg")
		// // Include the error field only if there are errors in the context or status code is not 200
		// if len(c.Errors) > 0 || c.Writer.Status() != http.StatusOK {
		// 	// Get the error string from c.Errors if it's not empty
		// 	errString := c.Errors.String()
		// 	if errString != "" {
		// 		logEntry = logEntry.WithField("error", errString)
		// 		if !exists {
		// 			Message = "Request failed"
		// 		}
		// 		logEntry.Error(Message)
		// 	}
		// } else {
		// 	if !exists {
		// 		Message = "Request processed"
		// 	}
		// 	logEntry.Info(Message)
		// }
		return
	}
}

func generateTraceID() string {
	// Generate a new UUID as the trace ID for each request
	return uuid.New().String()
}

// HandleError handles the common error cases and sends JSON response
func HandleLog(c *gin.Context, statusCode int, Msg string, obj any) {
	//traceID := c.GetString(traceIDKey) // Get the traceID from the context
	logEntry := log.WithFields(logrus.Fields{
		"traceID":  c.GetString(string(traceIDKey)), // Get the traceID from the context
		"status":   c.Writer.Status(),
		"method":   c.Request.Method,
		"path":     c.Request.URL.Path,
		"ip":       c.ClientIP(),
		"proto":    c.Request.Proto,
		"remoteIP": c.RemoteIP(),
	})
	if len(c.Errors) > 0 || c.Writer.Status() != http.StatusOK {
		// Get the error string from c.Errors if it's not empty
		errString := c.Errors.String()
		if errString != "" {
			logEntry = logEntry.WithField("error", errString)
			logEntry.Error(Msg)
		}
	} else {
		logEntry.Info(Msg)
	}
	if obj == nil {
		obj = gin.H{"msg": Msg}
	}
	c.JSON(statusCode, obj)
}
