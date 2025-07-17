docker_up:
	# Spin up Zookeeper and Kafka broker in Docker containers
	docker-compose build --no-cache
	docker-compose up -d

	# Create Kafka topic and 3 partitions
	docker exec kafka /opt/bitnami/kafka/bin/kafka-topics.sh --create \
		--bootstrap-server localhost:9092 \
		--topic NBA-Games \
		--partitions 3 \
		--replication-factor 1

	# Check that kafka topic and partitions were created
	docker exec kafka /opt/bitnami/kafka/bin/kafka-topics.sh \
		--describe \
		--bootstrap-server localhost:9092 \
		--topic NBA-Games

docker_down:
	docker-compose down
