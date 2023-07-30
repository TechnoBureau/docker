package controllers

import (
	"database/sql"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"tgo/common"
	"tgo/models"
)

// GetAlbums retrieves all albums from the database
func GetAlbums(c *gin.Context) {
	db := c.MustGet("db").(*sql.DB)

	albums, err := models.GetAlbums(db)
	if err != nil {
		common.HandleLog(c, http.StatusInternalServerError, "Failed to get albums", nil)
		return
	}
	common.HandleLog(c, http.StatusOK, "Request processed", albums)
}

// GetAlbumByID retrieves a single album from the database based on the provided ID
func GetAlbumByID(c *gin.Context) {
	db := c.MustGet("db").(*sql.DB)

	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		common.HandleLog(c, http.StatusBadRequest, "Invalid album ID", nil)
		return
	}

	album, err := models.GetAlbumByID(db, id)
	if err != nil {
		c.Error(err)
		common.HandleLog(c, http.StatusInternalServerError, "Failed to get album", nil)
		return
	}

	if album == nil {
		common.HandleLog(c, http.StatusNotFound, "Album not found", nil)
		return
	}
	common.HandleLog(c, http.StatusOK, "Request processed", album)
}

// PostAlbum creates a new album in the database
func PostAlbum(c *gin.Context) {
	db := c.MustGet("db").(*sql.DB)

	var album models.Album
	if err := c.ShouldBindJSON(&album); err != nil {
		c.Error(err)
		common.HandleLog(c, http.StatusBadRequest, "Invalid album data", nil)
		return
	}

	a1, err := models.CreateAlbum(db, &album)
	if err != nil {
		c.Error(err)
		common.HandleLog(c, http.StatusInternalServerError, "Failed to create album", nil)
		return
	}
	common.HandleLog(c, http.StatusOK, "Request processed", a1)
}

// DeleteAlbum deletes an album from the database based on ID
func DeleteAlbum(c *gin.Context) {
	db := c.MustGet("db").(*sql.DB)

	// Check if the ID is valid
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.Error(err)
		common.HandleLog(c, http.StatusBadRequest, "Invalid album ID", nil)
		return
	}

	// Delete the album
	if err := models.DeleteAlbum(db, id); err != nil {
		c.Error(err)
		common.HandleLog(c, http.StatusInternalServerError, "Failed to delete album", nil)
		return
	}
	common.HandleLog(c, http.StatusNoContent, "Album Deleted", nil)
}
