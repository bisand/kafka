# Use Alpine 3.18 as the base image
FROM alpine:3.18

# Set environment variables for Kafka version and Scala version
ENV KAFKA_VERSION=3.7.0
ENV SCALA_VERSION=2.13
ENV KAFKA_HOME=/opt/kafka
ENV PATH=${PATH}:${KAFKA_HOME}/bin

# Set the working directory inside the container
WORKDIR /opt/kafka

# Install necessary dependencies
RUN apk add --no-cache openjdk17-jre bash

# Download and extract Kafka
ADD https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz /opt/kafka
RUN tar -xzf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz --strip-components=1

# Cleanup downloaded archive
RUN ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} ${KAFKA_HOME} \
    && rm -rf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz

ADD bin/* /opt/kafka/bin/

# Expose Kafka's default port (change if necessary)
EXPOSE 9092

# Start Kafka server
# CMD ["custom/bin/kafka-start.sh"]

COPY ./entrypoint.sh /
RUN ["chmod", "+x", "/entrypoint.sh"]
ENTRYPOINT ["/entrypoint.sh"]
