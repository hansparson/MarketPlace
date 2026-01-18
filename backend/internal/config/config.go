package config

import (
	"os"
)

type Config struct {
	Port  string
	DBURL string
}

func LoadConfig() *Config {
	return &Config{
		Port:  os.Getenv("PORT"),
		DBURL: os.Getenv("DATABASE_URL"),
	}
}
