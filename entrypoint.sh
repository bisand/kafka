#!/bin/sh

    CONTAINER_FIRST_STARTUP="CONTAINER_FIRST_STARTUP"

    if [ ! -e /$CONTAINER_FIRST_STARTUP ]; then

    touch /$CONTAINER_FIRST_STARTUP

    bin/kafka-storage.sh random-uuid > kafka-cluster-id

    && KAFKA_CLUSTER_ID="${KAFKA_CLUSTER_ID:=$(cat kafka-cluster-id)}"

    && echo ${KAFKA_CLUSTER_ID}

    && rm kafka-cluster-id

    && bin/kafka-storage.sh format -t ${KAFKA_CLUSTER_ID} -c config/kraft/server.properties

    else

    bin/kafka-server-start.sh config/kraft/server.properties

    fi
