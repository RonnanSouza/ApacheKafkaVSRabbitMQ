# ApacheKafkaVSRabbitMQ

This repository is a benchmark of two most used pub/sub platforms: Apache Kafka and RabbitMQ

## Kafka

### Running Performance Tests

To setup the docker enviroment, run:
```
make kafka-setup
```

To run the example perf test with no replication, run:
```
make kakfa-perf-1
```


To run the example perf test with replication factor 3, run:
```
make kakfa-perf-3
```

To stop the containers, run:
```
make docker-stop
```