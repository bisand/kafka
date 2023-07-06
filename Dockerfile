# Use Alpine 3.18 as the base image
FROM alpine:3.18

# Set environment variables for Kafka version and Scala version
ARG KAFKA_VERSION=3.5.0
ARG SCALA_VERSION=2.13

# Set the working directory inside the container
WORKDIR /opt/kafka

# Install necessary dependencies
RUN apk add --no-cache openjdk11-jre bash

# Download and extract Kafka
ADD https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz /opt/kafka
RUN tar -xzf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz --strip-components=1

# Cleanup downloaded archive
RUN rm kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz

ADD bin/* /opt/kafka/custom/bin/

# Expose Kafka's default port (change if necessary)
EXPOSE 9092

# Start Kafka server
CMD ["custom/bin/kafka-start.sh"]
