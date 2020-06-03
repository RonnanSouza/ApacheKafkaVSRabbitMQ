PROJECTNAME := $(shell basename "$(PWD)")

partitions = 1
replication = 1

help: Makefile
	@echo " Choose a command run in "$(PROJECTNAME)":"
	@echo ""
	@find . -maxdepth 1 -type f \( -name Makefile -or -name "*.mk" \) -exec cat {} \+ | sed -n 's/^##//p' | column -t -s ':' |  sed -e 's/^/ /'

kafka-setup:
	@echo "Setting up Kafka instances in "$(PROJECTNAME)
	@docker-compose -f kafka/docker-compose.yaml up -d --scale kafka=2
	@sh kafka/app/bin/kafka-topics.sh --create --bootstrap-server localhost:9092\
		--replication-factor 1 --partitions 1 --topic test1
	@sh kafka/app/bin/kafka-topics.sh --create --bootstrap-server localhost:9092\
		--replication-factor 3 --partitions 1 --topic test3

kafka-perf-1:
	@sh kafka/app/bin/kafka-producer-perf-test.sh --topic test1 --num-records 500\
	 --record-size 100 --throughput -1 --producer-props acks=0 bootstrap.servers=localhost:9092\
	 buffer.memory=67108864 batch.size=8196

kafka-perf-3:
	@sh kafka/app/bin/kafka-producer-perf-test.sh --topic test3 --num-records 500\
	 --record-size 100 --throughput -1 --producer-props acks=0 bootstrap.servers=localhost:9092\
	 buffer.memory=67108864 batch.size=8196

kafka-perf-consumer:
	@sh kafka/app/bin/kafka-consumer-perf-test.sh --topic test1 \
	 --bootstrap-server=localhost:9092 --messages 100

rabbitmq-setup:
	@echo "Setting up Kafka instances in "$(PROJECTNAME)
	@docker-compose -f rabbitmq/docker-compose.yaml up -d

rabbitmq-perf:

docker-stop:
	@docker-compose -f ./kafka/docker-compose.yaml down
	@docker-compose -f ./rabbitmq/docker-compose.yaml down