package models

import (
	"database/sql"
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
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var album Album
		err := rows.Scan(&album.ID, &album.Title, &album.Artist, &album.Price)
		if err != nil {
			return nil, err
		}
		albums = append(albums, album)
	}

	err = rows.Err()
	if err != nil {
		return nil, err
	}

	return albums, nil
}

// GetAlbumByID retrieves an album by its ID from the database
func GetAlbumByID(db *sql.DB, id int) (*Album, error) {
	var album Album

	row := db.QueryRow("SELECT * FROM albums WHERE id = $1", id)
	err := row.Scan(&album.ID, &album.Title, &album.Artist, &album.Price)
	if err != nil {
		return nil, err
	}

	return &album, nil
}

// CreateAlbum creates a new album in the database
func CreateAlbum(db *sql.DB, album *Album) (*Album, error) {
	err := db.QueryRow("INSERT INTO albums(title, artist, price) VALUES($1, $2, $3) RETURNING id",
		album.Title, album.Artist, album.Price).Scan(&album.ID)
	if err != nil {
		return nil, err
	}
	return album, nil
}

// DeleteAlbum deletes an album from the database by its ID
func DeleteAlbum(db *sql.DB, id int) error {
	_, err := db.Exec("DELETE FROM albums WHERE id = $1", id)
	if err != nil {
		return err
	}
	return nil
}
