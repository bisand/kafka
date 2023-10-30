#!/bin/sh

echo "Hostname: ${HOSTNAME}"

NODE_ID=$((REPLICA - 1))

LISTENERS="PLAINTEXT://:9092,CONTROLLER://:9093"
ADVERTISED_LISTENERS="PLAINTEXT://kafka-$((NODE_ID + 1)):9092"

CONTROLLER_QUORUM_VOTERS=""
for i in $( seq 0 $((REPLICAS)) ); do
    if [ $i != $((REPLICAS)) ]; then
        CONTROLLER_QUORUM_VOTERS="$CONTROLLER_QUORUM_VOTERS$i@kafka-$((i+1)):9093,"
    else
        CONTROLLER_QUORUM_VOTERS=${CONTROLLER_QUORUM_VOTERS%?}
    fi
done

mkdir -p $SHARE_DIR/$NODE_ID

if [[ ! -f "$SHARE_DIR/cluster_id" && "$NODE_ID" = "1" ]]; then
    echo "Initializing cluster id"
    CLUSTER_ID=$(kafka-storage.sh random-uuid)
    echo $CLUSTER_ID > $SHARE_DIR/cluster_id
    echo "Cluster id: $CLUSTER_ID Node ID: $NODE_ID"
else
    CLUSTER_ID=$(cat $SHARE_DIR/cluster_id)
    echo "Cluster id: $CLUSTER_ID Node ID: $NODE_ID"
fi

sed -e "s+^node.id=.*+node.id=$NODE_ID+" \
-e "s+^controller.quorum.voters=.*+controller.quorum.voters=$CONTROLLER_QUORUM_VOTERS+" \
-e "s+^listeners=.*+listeners=$LISTENERS+" \
-e "s+^advertised.listeners=.*+advertised.listeners=$ADVERTISED_LISTENERS+" \
-e "s+^log.dirs=.*+log.dirs=$SHARE_DIR/$NODE_ID+" \
/opt/kafka/config/kraft/server.properties > server.properties.updated \
&& mv server.properties.updated /opt/kafka/config/kraft/server.properties

kafka-storage.sh format -t $CLUSTER_ID -c /opt/kafka/config/kraft/server.properties

cat /opt/kafka/config/kraft/server.properties

exec kafka-server-start.sh /opt/kafka/config/kraft/server.properties
