#!/bin/sh

SOURCE_CONFIG_FILE="/opt/kafka/config/kraft/server.properties"
CONFIG_FILE="/opt/kafka/config/kraft/custom/server.properties"
mkdir -p /opt/kafka/config/kraft/custom
cp $SOURCE_CONFIG_FILE $CONFIG_FILE

export REPLICA="${REPLICA:-1}"
export REPLICAS="${REPLICAS:-1}"

DEFAULT_NODE_ID=$((REPLICA - 1))
echo "###############################################"
echo "Starting kafka node $DEFAULT_NODE_ID, replica $REPLICA of $REPLICAS"
echo "Hostname: ${HOSTNAME}, Replica: ${REPLICA}, Replicas: ${REPLICAS}, Share dir: ${SHARE_DIR}"
echo "###############################################"
if [[ ! $REPLICA = "1" ]]; then
    for i in $(seq 1 $((REPLICA - 1))); do
        while ! nc -z kafka-$i 9092 && ! nc -z kafka-$i 9093; do
            echo "Waiting for kafka-$i to start..."
            sleep 1
        done
    done
fi

DEFAULT_LISTENER_SECURITY_PROTOCOL_MAP="EXTERNAL:PLAINTEXT,CONTROLLER:PLAINTEXT,INTERNAL:PLAINTEXT" #,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL"
DEFAULT_LISTENERS="INTERNAL://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093,EXTERNAL://0.0.0.0:299$(printf "%02d" $REPLICA)"
DEFAULT_ADVERTISED_LISTENERS="INTERNAL://kafka-$REPLICA:9092,EXTERNAL://$PUBLIC_FQDN:299$(printf "%02d" $REPLICA)"
DEFAULT_INTER_BROKER_LISTENER_NAME="INTERNAL"
DEFAULT_CONTROLLER_LISTENER_NAMES="CONTROLLER"
DEFAULT_LOG_DIRS=$SHARE_DIR/$DEFAULT_NODE_ID

DEFAULT_CONTROLLER_QUORUM_VOTERS=""
for i in $( seq 0 $REPLICAS); do
    if [[ $i != $REPLICAS ]]; then
        DEFAULT_CONTROLLER_QUORUM_VOTERS="$DEFAULT_CONTROLLER_QUORUM_VOTERS$i@kafka-$((i+1)):9093,"
    else
        DEFAULT_CONTROLLER_QUORUM_VOTERS=${DEFAULT_CONTROLLER_QUORUM_VOTERS%?}
    fi
done

mkdir -p $SHARE_DIR/$DEFAULT_NODE_ID

if [[ ! -f "$SHARE_DIR/cluster_id" && "$DEFAULT_NODE_ID" = "0" ]]; then
    echo "Initializing cluster id"
    CLUSTER_ID=$(kafka-storage.sh random-uuid)
    echo $CLUSTER_ID > $SHARE_DIR/cluster_id
    echo "Cluster id: $CLUSTER_ID Node ID: $DEFAULT_NODE_ID"
else
    CLUSTER_ID=$(cat $SHARE_DIR/cluster_id)
    echo "Cluster id: $CLUSTER_ID Node ID: $DEFAULT_NODE_ID"
fi

if [[ -f "$SHARE_DIR/$DEFAULT_NODE_ID/__cluster_metadata-0/quorum-state" ]]; then
    echo "Initializing quorum state"
    rm $SHARE_DIR/$DEFAULT_NODE_ID/__cluster_metadata-0/quorum-state
fi

export KAFKA_NODE_ID="${KAFKA_NODE_ID:-$DEFAULT_NODE_ID}"
export KAFKA_LISTENER_SECURITY_PROTOCOL_MAP="${KAFKA_LISTENER_SECURITY_PROTOCOL_MAP:-$DEFAULT_LISTENER_SECURITY_PROTOCOL_MAP}"
export KAFKA_LISTENERS="${KAFKA_LISTENERS:-$DEFAULT_LISTENERS}"
export KAFKA_ADVERTISED_LISTENERS="${KAFKA_ADVERTISED_LISTENERS:-$DEFAULT_ADVERTISED_LISTENERS}"
export KAFKA_INTER_BROKER_LISTENER_NAME="${KAFKA_INTER_BROKER_LISTENER_NAME:-$DEFAULT_INTER_BROKER_LISTENER_NAME}"
export KAFKA_CONTROLLER_LISTENER_NAMES="${KAFKA_CONTROLLER_LISTENER_NAMES:-$DEFAULT_CONTROLLER_LISTENER_NAMES}"
export KAFKA_LOG_DIRS="${KAFKA_LOG_DIRS:-$DEFAULT_LOG_DIRS}"
export KAFKA_CONTROLLER_QUORUM_VOTERS="${KAFKA_CONTROLLER_QUORUM_VOTERS:-$DEFAULT_CONTROLLER_QUORUM_VOTERS}"

# Iterate over all environment variables
for var in $(env | grep '^KAFKA_' | awk -F= '{print $1}'); do
    # Extract the key and value from the environment variable
    key="${var#KAFKA_}"
    value=$(eval echo \$$var)

    # Convert the key to lowercase and replace underscores with dots
    key=$(echo "$key" | tr '[:upper:]' '[:lower:]' | tr '_' '.')

    # Append or update the key-value pair in the config.properties file
    if grep -q "^$key=" "$CONFIG_FILE"; then
        echo "Updating $key=$value"
        sed -i "s|^$key=.*|$key=$value|" "$CONFIG_FILE"
    else
        echo "$key=$value" >> "$CONFIG_FILE"
    fi
done

kafka-storage.sh format --ignore-formatted -t $CLUSTER_ID -c $CONFIG_FILE

# cat $SOURCE_CONFIG_FILE

exec kafka-server-start.sh $CONFIG_FILE
