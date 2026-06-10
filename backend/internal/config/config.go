package config

import (
	"os"
)

type Config struct {
	Port  string
	DBURL string

	DanaEnv          string
	DanaMerchantID   string
	DanaXPartnerID   string
	DanaChannelID    string
	DanaPrivateKey   string
	DanaPublicKey    string
	DanaClientID     string
	DanaClientSecret string
	DanaOrigin       string
}

func LoadConfig() *Config {
	return &Config{
		Port:             os.Getenv("PORT"),
		DBURL:            os.Getenv("DATABASE_URL"),
		DanaEnv:          os.Getenv("DANA_ENV"),
		DanaMerchantID:   os.Getenv("DANA_MERCHANT_ID"),
		DanaXPartnerID:   os.Getenv("DANA_X_PARTNER_ID"),
		DanaChannelID:    os.Getenv("DANA_CHANNEL_ID"),
		DanaPrivateKey:   os.Getenv("DANA_PRIVATE_KEY"),
		DanaPublicKey:    os.Getenv("DANA_PUBLIC_KEY"),
		DanaClientID:     os.Getenv("DANA_CLIENT_ID"),
		DanaClientSecret: os.Getenv("DANA_CLIENT_SECRET"),
		DanaOrigin:       os.Getenv("DANA_ORIGIN"),
	}
}
