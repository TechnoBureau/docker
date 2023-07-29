package controllers

import (
	"database/sql"
	"net/http"
	"strconv"

	"tgo/models"

	"github.com/gin-gonic/gin"
	ginlogrus "github.com/sirupsen/logrus"
)

// GetAlbums retrieves all albums from the database
func GetAlbums(c *gin.Context) {
	db := c.MustGet("db").(*sql.DB)

	albums, err := models.GetAlbums(db)
	if err != nil {
		ginlogrus.WithFields(ginlogrus.Fields{
			"error": err,
		}).Error("Failed to get albums")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get albums"})
		return
	}

	c.JSON(http.StatusOK, albums)
}

// GetAlbumByID retrieves a single album from the database based on the provided ID
func GetAlbumByID(c *gin.Context) {
	db := c.MustGet("db").(*sql.DB)

	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		ginlogrus.WithFields(ginlogrus.Fields{
			"error": err,
		}).Error("Invalid album ID")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid album ID"})
		return
	}

	album, err := models.GetAlbumByID(db, id)
	if err != nil {
		ginlogrus.WithFields(ginlogrus.Fields{
			"error": err,
		}).Errorf("Failed to get album with ID %d", id)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get album"})
		return
	}

	if album == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Album not found"})
		return
	}

	c.JSON(http.StatusOK, album)
}

// PostAlbum creates a new album in the database
func PostAlbum(c *gin.Context) {
	db := c.MustGet("db").(*sql.DB)

	var album models.Album
	if err := c.ShouldBindJSON(&album); err != nil {
		ginlogrus.WithFields(ginlogrus.Fields{
			"error": err,
		}).Error("Invalid album data")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid album data"})
		return
	}

	a1, err := models.CreateAlbum(db, &album)
	if err != nil {
		ginlogrus.WithFields(ginlogrus.Fields{
			"error": err,
		}).Error("Failed to create album")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create album"})
		return
	}

	c.JSON(http.StatusOK, a1)
}

// DeleteAlbum deletes an album from the database based on ID
func DeleteAlbum(c *gin.Context) {
	db := c.MustGet("db").(*sql.DB)

	// Check if the ID is valid
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid album ID"})
		return
	}

	// Delete the album
	if err := models.DeleteAlbum(db, id); err != nil {
		ginlogrus.WithFields(ginlogrus.Fields{
			"error": err,
			"id":    id,
		}).Error("Failed to delete album")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete album"})
		return
	}

	c.Status(http.StatusNoContent)
}
