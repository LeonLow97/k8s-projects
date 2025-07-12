package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	http.HandleFunc("/products", productsHandler)

	// Start the server on port 8001
	port := 8001
	log.Printf("Products service is listening on port %d\n", port)
	http.ListenAndServe(fmt.Sprintf(":%d", port), nil)
}
