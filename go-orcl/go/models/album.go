package models

import (
	"database/sql"
	"fmt"
)

// Album represents an album in the database
type Album struct {
	ID     int    `json:"id"`
	Title  string `json:"title"`
	Artist string `json:"artist"`
	Price  int    `json:"price"`
}

// GetAlbums retrieves all albums from the database
func GetAlbums(db *sql.DB) ([]Album, error) {
	var albums []Album

	rows, err := db.Query("SELECT * FROM albums")
	if err != nil {
		return nil, fmt.Errorf("error executing query: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var album Album
		err := rows.Scan(&album.ID, &album.Title, &album.Artist, &album.Price)
		if err != nil {
			return nil, fmt.Errorf("error scanning row: %w", err)
		}
		albums = append(albums, album)
	}

	err = rows.Err()
	if err != nil {
		return nil, fmt.Errorf("error iterating rows: %w", err)
	}

	return albums, nil
}

// GetAlbumByID retrieves an album by its ID from the database
func GetAlbumByID(db *sql.DB, id int) (*Album, error) {
	var album Album

	row := db.QueryRow("SELECT * FROM albums WHERE id = :id", sql.Named("id", id))
	err := row.Scan(&album.ID, &album.Title, &album.Artist, &album.Price)
	if err != nil {
		return nil, fmt.Errorf("error executing query: %w", err)
	}

	return &album, nil
}

// CreateAlbum creates a new album in the database
func CreateAlbum(db *sql.DB, album *Album) (*Album, error) {
	result, err := db.Exec("INSERT INTO albums(title, artist, price) VALUES(:title, :artist, :price) RETURNING id INTO :id",
		sql.Named("title", album.Title),
		sql.Named("artist", album.Artist),
		sql.Named("price", album.Price),
		sql.Named("id", sql.Out{Dest: &album.ID}),
	)
	result.RowsAffected()
	if err != nil {
		return nil, fmt.Errorf("error executing query: %w", err)
	}
	return album, nil
}

// DeleteAlbum deletes an album from the database by its ID
func DeleteAlbum(db *sql.DB, id int) error {
	_, err := db.Exec("DELETE FROM albums WHERE id = :id", sql.Named("id", id))
	if err != nil {
		return fmt.Errorf("error executing query: %w", err)
	}

	return nil
}
