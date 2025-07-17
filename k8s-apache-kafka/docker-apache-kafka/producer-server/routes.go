package main

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/segmentio/kafka-go"
)

// ScoreUpdate represents a score change in an NBA game
type ScoreUpdate struct {
	GameID           string `json:"game_id"` // e.g., "LAL-CHI"
	Score            string `json:"score"`   // e.g., "102-98"
	CreatedTimestamp time.Time
}

func handleScoreUpdate(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Only POST allowed", http.StatusMethodNotAllowed)
		return
	}

	var update ScoreUpdate
	if err := json.NewDecoder(r.Body).Decode(&update); err != nil {
		http.Error(w, "Bad request format", http.StatusBadRequest)
		return
	}

	if update.GameID == "" {
		http.Error(w, "Missing game_id or team", http.StatusBadRequest)
		return
	}

	update.CreatedTimestamp = time.Now()

	message, _ := json.Marshal(update)
	err := writer.WriteMessages(r.Context(),
		kafka.Message{
			Key:   []byte(update.GameID), // partition key
			Value: message,
		},
	)

	if err != nil {
		log.Println(err)
		http.Error(w, "Failed to process update", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("Score updated"))
}
