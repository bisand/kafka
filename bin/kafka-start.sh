#!/bin/bash

file_path="/tmp/clusterID/clusterID"
interval=5  # wait interval in seconds

while [ ! -e "$file_path" ] || [ ! -s "$file_path" ]; do
  echo "Waiting for $file_path to be created..."
  sleep $interval
done

cat "$file_path"

# Path to the config.properties file
config_file="config/kraft/server.properties"

# Iterate over all environment variables
for var in "${!KAFKA_@}"; do
    # Extract the key and value from the environment variable
    key="${var#KAFKA_}"
    value="${!var}"

    # Convert the key to lowercase and replace underscores with dots
    key=$(echo "$key" | tr '[:upper:]' '[:lower:]' | tr '_' '.')

    # Append or update the key-value pair in the config.properties file
    if grep -q "^$key=" "$config_file"; then
        sed -i "s|^$key=.*|$key=$value|" "$config_file"
    else
        echo "$key=$value" >> "$config_file"
    fi
done

# KRaft required step: Format the storage directory with a new cluster ID
bin/kafka-storage.sh format --ignore-formatted -t $(cat "$file_path") -c $config_file
bin/kafka-server-start.sh $config_file
