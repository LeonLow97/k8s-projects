package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	http.HandleFunc("/users", usersHandler)

	// Start the server on port 8000
	port := 8000
	log.Printf("Users service is listening on port %d\n", port)
	http.ListenAndServe(fmt.Sprintf(":%d", port), nil)
}
