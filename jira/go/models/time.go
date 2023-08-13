package models

import (
	"time"
)

type Time struct {
	time.Time
}

var DefaultTimeZone *time.Location

func SetDefaultTimeZone(timeZone string) error {
	loc, err := time.LoadLocation(timeZone)
	if err != nil {
		return err
	}
	DefaultTimeZone = loc
	time.Local = loc // Set the default time zone
	return nil
}

func (ct Time) FormatForDB() time.Time {
	return ct.Time.In(DefaultTimeZone)
}
