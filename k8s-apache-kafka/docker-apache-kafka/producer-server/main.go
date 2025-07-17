package main

import (
	"log"
	"net/http"
	"os"

	"github.com/segmentio/kafka-go"
)

var writer *kafka.Writer

func main() {
	// Read from config
	broker := os.Getenv("KAFKA_BROKER")
	topic := os.Getenv("KAFKA_TOPIC")

	if broker == "" {
		broker = "localhost:9092"
	}
	if topic == "" {
		topic = "NBA-Games"
	}

	log.Printf("Topic: %s, Broker: %s\n", topic, broker)

	// High-level connection to Kafka Broker with more additional features
	// with Connection Pooling, Partition discovery, retry logic and batching

	// Make a Writer that produces to topic "NBA-Games" using the least bytes distribution
	writer = &kafka.Writer{
		Addr:     kafka.TCP(broker),
		Topic:    topic,
		Balancer: &kafka.Hash{},
	}
	defer writer.Close()

	http.HandleFunc("/score", handleScoreUpdate)

	log.Println("Server started on port 7000!")
	log.Fatal(http.ListenAndServe(":7000", nil))
}
