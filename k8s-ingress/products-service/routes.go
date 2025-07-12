package main

import (
	"encoding/json"
	"net/http"
)

type Product struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

func productsHandler(w http.ResponseWriter, r *http.Request) {
	products := []Product{
		{ID: 1, Name: "Adidas"},
		{ID: 2, Name: "Nike"},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(products)
}
