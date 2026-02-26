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
	//  Check for an explicit override (e.g., NOTARE_PROVIDER=chalk)
	provider := ProviderType(os.Getenv("NOTARE_PROVIDER"))

	//  Logic to "Auto-Detect" if no override is provided
	if provider == "" {
		username := os.Getenv("NOTARE_USERNAME")
		if username == "" {
			provider = Chalk
		} else {
			provider = Confluence
		}
	}

	//  Return the correct "Actor"
	switch provider {
	case Chalk:
		return &ChalkClient{
			BaseURL:  os.Getenv("NOTARE_URL"),
			APIToken: os.Getenv("NOTARE_API_TOKEN"),
			Client:   &http.Client{},
		}
	default:
		return &ConfluenceClient{
			BaseURL:  os.Getenv("NOTARE_URL"),
			Username: os.Getenv("NOTARE_USERNAME"),
			APIToken: os.Getenv("NOTARE_API_TOKEN"),
			Client:   &http.Client{},
		}
	}
}
