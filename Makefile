PROJECTNAME := $(shell basename "$(PWD)")

partitions = 1
replication = 1

help: Makefile
	@echo " Choose a command run in "$(PROJECTNAME)":"
	@echo ""
	@find . -maxdepth 1 -type f \( -name Makefile -or -name "*.mk" \) -exec cat {} \+ | sed -n 's/^##//p' | column -t -s ':' |  sed -e 's/^/ /'


## start-kafka starts Zookeeper and Kafka containers.
##    args - replicas (default = 1)
kafka-start:
	@echo "Starting Zookeeper and Kafka containers in "$(PROJECTNAME)
	@docker-compose -f kafka/docker-compose.yaml up -d zookeeper kafka-leader

kafka-setup:
	@sh kafka/app/bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1 --topic test

kafka-perf-producer:
	@sh kafka/app/bin/kafka-producer-perf-test.sh --topic test --num-records 500\
	 --record-size 100 --throughput -1 --producer-props acks=1 bootstrap.servers=localhost:9092\
	 buffer.memory=67108864 batch.size=8196 --print-metrics