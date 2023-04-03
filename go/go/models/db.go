package models

import (
	"database/sql"
	"fmt"
	"os"
)

// NewDB creates a new instance of sql.DB.
func NewDB() (*sql.DB, error) {
	var db *sql.DB
	var err error
	dbParams := map[string]string{
		"username": func() string {
			if u := os.Getenv("DB_USERNAME"); u != "" {
				return u
			}
			return "ADMIN"
		}(),
		"password": os.Getenv("DB_PASSWORD"),
		"server": func() string {
			if u := os.Getenv("DB_SERVER"); u != "" {
				return u
			}
			return "adb.ap-hyderabad-1.oraclecloud.com"
		}(),
		"port": func() string {
			if u := os.Getenv("DB_PORT"); u != "" {
				return u
			}
			return "1522"
		}(),
		"db": func() string {
			if u := os.Getenv("DB_NAME"); u != "" {
				return u
			}
			return "ADMIN"
		}(),
		"service": os.Getenv("DB_SERVICE"),
		"walletLocation": func() string {
			if u := os.Getenv("DB_WALLET"); u != "" {
				return u
			}
			return "/opt/technobureau/oracle/lib/network/admin"
		}(),
	}

	if val, ok := dbParams["walletLocation"]; ok && val != "" {
		db, err = sql.Open("godror", fmt.Sprintf(`user="%s" password="%s"
		connectString="tcps://%s:%s/%s/?wallet_location=%s"
		   `, dbParams["username"], dbParams["password"], dbParams["server"], dbParams["port"], dbParams["service"], dbParams["walletLocation"]))
	}
	if val, ok := dbParams["walletLocation"]; !ok || val == "" {
		connectionString := "oracle://" + dbParams["username"] + ":" + dbParams["password"] + "@" + dbParams["server"] + ":" + dbParams["port"] + "/" + dbParams["db"] + "/" + dbParams["service"]
		db, err = sql.Open("oracle", connectionString)
	}

	if err != nil {
		return nil, fmt.Errorf("error in sql.Open: %w", err)
	}

	// Set the maximum number of open connections
	db.SetMaxOpenConns(25)
	// Set the maximum number of idle connections
	db.SetMaxIdleConns(25)

	err = db.Ping()
	if err != nil {
		return nil, fmt.Errorf("error pinging db: %w", err)
	}
	return db, nil
}
