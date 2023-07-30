package models

import (
	"database/sql"
	"fmt"
	"os"

	_ "github.com/go-sql-driver/mysql"
	//_ "github.com/godror/godror"
	_ "github.com/lib/pq"
)

func NewDB() (*sql.DB, error) {
	var db *sql.DB
	var err error
	dbType := os.Getenv("DB_TYPE")
	if dbType == "" {
		return nil, fmt.Errorf("DB_TYPE environment variable not set")
	}

	dbParams := map[string]string{
		"username": func() string {
			if u := os.Getenv("DB_USERNAME"); u != "" {
				return u
			}
			return "admin"
		}(),
		"password": os.Getenv("DB_PASSWORD"),
		"server": func() string {
			if u := os.Getenv("DB_SERVER"); u != "" {
				return u
			}
			return "localhost"
		}(),
		"port": func() string {
			if u := os.Getenv("DB_PORT"); u != "" {
				return u
			}
			switch dbType {
			case "mysql":
				return "3306"
			case "postgres":
				return "5432"
			case "oracle":
				return "1521"
			default:
				return "0"
			}
		}(),
		"db": func() string {
			if u := os.Getenv("DB_NAME"); u != "" {
				return u
			}
			return "admin"
		}(),
		"service": os.Getenv("DB_SERVICE"),
		"walletLocation": func() string {
			if u := os.Getenv("DB_WALLET"); u != "" {
				return u
			}
			return "/opt/technobureau/oracle/lib/network/admin"
		}(),
	}

	var driverName string
	var connectionString string

	switch dbType {
	case "oracle":
		driverName = "godror"
		connectionString = fmt.Sprintf(`user="%s" password="%s" connectString="%s:%s/%s"`, dbParams["username"], dbParams["password"], dbParams["server"], dbParams["port"], dbParams["service"])
		if val, ok := dbParams["walletLocation"]; ok && val != "" {
			connectionString += fmt.Sprintf(" wallet_location=%s", dbParams["walletLocation"])
		}
	case "mysql":
		driverName = "mysql"
		connectionString = fmt.Sprintf("%s:%s@tcp(%s:%s)/%s", dbParams["username"], dbParams["password"], dbParams["server"], dbParams["port"], dbParams["db"])
	case "postgres":
		driverName = "postgres"
		connectionString = fmt.Sprintf("postgres://%s:%s@%s:%s/%s", dbParams["username"], dbParams["password"], dbParams["server"], dbParams["port"], dbParams["db"])
	default:
		return nil, fmt.Errorf("unsupported database type: %s", dbType)
	}

	// Use the blank import to load the database driver dynamically
	db, err = sql.Open(driverName, connectionString)
	if err != nil {
		return nil, fmt.Errorf("failed to open %s driver: %w", dbType, err)
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
