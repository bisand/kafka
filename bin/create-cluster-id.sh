#!/bin/bash

file_path="/tmp/clusterID/clusterID"

if [ ! -f "$file_path" ]; then
  bin/kafka-storage.sh random-uuid > /tmp/clusterID/clusterID
  echo "Cluster id has been created!"
fi
