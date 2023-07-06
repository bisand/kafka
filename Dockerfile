# Dockerfile
FROM alpine:3.18

# Install jdk 
RUN apk update && apk add openjdk8-jre -q

# Unzip kafka zip and rename at kafka
ENV kafka_version=2.13-3.5.0 
ADD ./kafka_${kafka_version}.tgz ./ 
RUN mv kafka_${kafka_version} kafka

