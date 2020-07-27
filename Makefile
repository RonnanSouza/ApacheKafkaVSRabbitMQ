#!make
UNAME := $(shell uname)


HOST_IP=`ifconfig | grep --color=none -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep --color=none -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1`
# HOST_IP=$(shell hostname -I | cut -d' ' -f1)


include rabbitmq/cluster/.env
export $(shell sed 's/=.*//' rabbitmq/cluster/.env)

PROJECTNAME := $(shell basename "$(PWD)")

help: Makefile
	@echo " Choose a command run in "$(PROJECTNAME)":"
	@echo ""
	@find . -maxdepth 1 -type f \( -name Makefile -or -name "*.mk" \) -exec cat {} \+ | sed -n 's/^##//p' | column -t -s ':' |  sed -e 's/^/ /'

kafka-setup:
	@echo "Setting up Kafka instances in "$(PROJECTNAME)
	@HOST_IP=$(HOST_IP) docker-compose -f kafka/docker-compose.yaml up -d --scale kafka=2
	@sh kafka/app/bin/kafka-topics.sh --create --bootstrap-server localhost:9092\
		--replication-factor 1 --partitions 1 --topic test1
	@sh kafka/app/bin/kafka-topics.sh --create --bootstrap-server localhost:9092\
		--replication-factor 3 --partitions 1 --topic test3

kafka-stop:
	@@docker-compose -f kafka/docker-compose.yaml down

kafka-latency:
	@echo "Running latency test"
	@sh kafka/app/bin/kafka-run-class.sh kafka.tools.EndToEndLatency localhost:9092 test1 5000 1 1024

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

rabbitmq-deps:
	@echo "Setting up RabbitMQ cluster in "$(PROJECTNAME)
	@docker network create $(RABBITMQ_DEFAULT_NETWORK)
	@docker-compose -f rabbitmq/cluster/docker-compose.yml --env-file rabbitmq/cluster/.env up -d

rabbitmq-cluster:
	@docker exec rmq2 bash -c "rabbitmqctl stop_app;rabbitmqctl reset;rabbitmqctl join_cluster rabbit@rabbitmq1;rabbitmqctl start_app"
	@docker exec rmq3 bash -c "rabbitmqctl stop_app;rabbitmqctl reset;rabbitmqctl join_cluster rabbit@rabbitmq1;rabbitmqctl start_app"

rabbitmq-stop:
	@echo "Stopping RabbitMQ cluster"
	@docker-compose -f rabbitmq/cluster/docker-compose.yml down
	@docker network rm $(RABBITMQ_DEFAULT_NETWORK)

rabbitmq-latency:
	@timeout 10s docker run --rm --network rabbit-net pivotalrabbitmq/perf-test:latest --uri amqp://proxy