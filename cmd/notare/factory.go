package main

import (
	"net/http"
	"os"
)

// ProviderType identifies which service we are talking to
type ProviderType string

const (
	Confluence ProviderType = "cloud"
	Chalk      ProviderType = "chalk"
)

func NewNotareClient() NotareProvider {
	// 1. Check for an explicit override (e.g., NOATARE_PROVIDER=chalk)
	provider := ProviderType(os.Getenv("NOATARE_PROVIDER"))

	// 2. Logic to "Auto-Detect" if no override is provided
	if provider == "" {
		username := os.Getenv("NOATARE_USERNAME")
		if username == "" {
			provider = Chalk
		} else {
			provider = Confluence
		}
	}

	// 3. Return the correct "Actor"
	switch provider {
	case Chalk:
		return &ChalkClient{
			BaseURL:  os.Getenv("NOATARE_URL"),
			APIToken: os.Getenv("NOATARE_API_TOKEN"),
			Client:   &http.Client{},
		}
	default:
		return &ConfluenceClient{
			BaseURL:  os.Getenv("NOATARE_URL"),
			Username: os.Getenv("NOATARE_USERNAME"),
			APIToken: os.Getenv("NOATARE_API_TOKEN"),
			Client:   &http.Client{},
		}
	}
}
