#!/bin/bash

# Path to the config.properties file
SOURCE_CONFIG_FILE="config/kraft/server.properties"
CONFIG_FILE="custom/server.properties"

cp $SOURCE_CONFIG_FILE $CONFIG_FILE

# Iterate over all environment variables
for var in "${!KAFKA_@}"; do
    # Extract the key and value from the environment variable
    key="${var#KAFKA_}"
    value="${!var}"

    # Convert the key to lowercase and replace underscores with dots
    key=$(echo "$key" | tr '[:upper:]' '[:lower:]' | tr '_' '.')

    # Append or update the key-value pair in the config.properties file
    if grep -q "^$key=" "$CONFIG_FILE"; then
        sed -i "s|^$key=.*|$key=$value|" "$CONFIG_FILE"
    else
        echo "$key=$value" >> "$CONFIG_FILE"
    fi
done

# KRaft required step: Format the storage directory with a new cluster ID
bin/kafka-storage.sh format --ignore-formatted -t $CLUSTER_ID -c $CONFIG_FILE
bin/kafka-server-start.sh $CONFIG_FILE
