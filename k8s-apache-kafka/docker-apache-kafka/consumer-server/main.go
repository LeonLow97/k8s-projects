package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/segmentio/kafka-go"
)

func main() {
	// Read from config
	topic := os.Getenv("KAFKA_TOPIC")
	broker := os.Getenv("KAFKA_BROKER")
	groupID := os.Getenv("KAFKA_GROUP_ID")

	// Configure the consumer
	reader := kafka.NewReader(kafka.ReaderConfig{
		Brokers:  []string{broker},
		Topic:    topic,
		MinBytes: 1,   // smallest batch size
		MaxBytes: 1e6, // 1MB batch max

		// Critical: Same group for partition balancing
		// In Apache Kafka, a consumer group allows multiple consumers to work together to read from a topic.
		// Each consumer group has a unique ID (i.e., "Group ID")
		// When multiple consumers share the same group ID, Kafka distributes the topic's partitions among them,
		// ensuring that each partition is consumed by only 1 consumer within that group.
		// This mechanism enables parallel processing of messages from a topic.
		// Reference: https://codingharbour.com/apache-kafka/what-is-a-consumer-group-in-kafka/
		GroupID: groupID,
	})
	defer reader.Close()

	// Graceful shutdown
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	sigchan := make(chan os.Signal, 1)
	signal.Notify(sigchan, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-sigchan
		cancel()
	}()

	log.Printf("Consumer started (Group: %s). Waiting for messages...\n", groupID)

	for {
		msg, err := reader.ReadMessage(ctx)
		if err != nil {
			if ctx.Err() != nil {
				break // Shutdown gracefully
			}
			log.Printf("Error: %v\n", err)
			continue
		}

		log.Printf(
			"Partition %d | Offset %d | Key: %s | Value: %s\n",
			msg.Partition,
			msg.Offset,
			string(msg.Key),
			string(msg.Value),
		)
	}
}
