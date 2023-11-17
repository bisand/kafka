#!/bin/sh

# From: https://www.ibm.com/docs/en/imdm/12.0?topic=kafka-creating-ssl-artifacts
PASSWORD=${PASSWORD:-brigading-hydrozoons-ikat-vee}
CERT_COUNTRY=${CERT_COUNTRY:-NO}
CERT_STATE=${CERT_STATE:-Vestfold}
CERT_CITY=${CERT_CITY:-Tønsberg}
CERT_ORG=${CERT_ORG:-biseth.net}
CERT_ORG_UNIT=${CERT_ORG_UNIT:-}
CERT_COMMON_NAME=${CERT_COMMON_NAME:-$HOSTNAME}

# Create openssl.cnf
cat <<EOF > ./openssl.cnf
default_bits = 2048
default_keyfile = privkey.pem
distinguished_name = req_distinguished_name
req_extensions = req_ext

[ req_distinguished_name ]
countryName = Country
countryName_default = $CERT_COUNTRY
stateOrProvinceName = State
stateOrProvinceName_default = $CERT_STATE
localityName = City
localityName_default = $CERT_CITY
organizationName = Organization
organizationName_default = $CERT_ORG
commonName = Primary Host Name
commonName_max = 64

[ req_ext ]
subjectAltName = @alt_names

[alt_names]
IP.1 = 192.168.86.175
DNS.1 = kafka.publicnode.eu
DNS.2 = luke.lan
EOF

mkdir -p /tmp/servercerts/ /tmp/clientcerts/

echo "#1 Generate the self-signed certificate authority (CA)"
openssl req -new -x509 -keyout /tmp/servercerts/ca-key -out /tmp/servercerts/ca-cert -days 365 -passin pass:$PASSWORD -passout pass:$PASSWORD -subj "/C=$CERT_COUNTRY/ST=$CERT_STATE/L=$CERT_CITY/O=$CERT_ORG/OU=$CERT_ORG_UNIT/CN=$CERT_COMMON_NAME" -config ./openssl.cnf

echo "#2 Generate the SSL key store and certificate for the Kafka brokers."
keytool -keystore /tmp/servercerts/serverkeystore.jks -alias uumdm -validity 365 -genkey -keyalg RSA -storepass $PASSWORD -keypass $PASSWORD -dname "CN=$CERT_COMMON_NAME, OU=$CERT_ORG_UNIT, O=$CERT_ORG, L=$CERT_CITY, ST=$CERT_STATE, C=$CERT_COUNTRY" -noprompt

echo "#3 Sign the certificates in the key store using the CA that you generated in step 2."
keytool -keystore /tmp/servercerts/serverkeystore.jks -alias uumdm -certreq -file /tmp/servercerts/cert-file -storepass $PASSWORD -keypass $PASSWORD -noprompt

echo "#4 Sign the certificate."
openssl x509 -req -CA /tmp/servercerts/ca-cert -CAkey /tmp/servercerts/ca-key -in /tmp/servercerts/cert-file -out /tmp/servercerts/cert-signed -days 365 -CAcreateserial -extfile ./openssl.cnf -extensions req_ext -passin pass:$PASSWORD

echo "#5 Import the CA certificate."
keytool -keystore /tmp/servercerts/serverkeystore.jks -alias CARoot -import -file /tmp/servercerts/ca-cert -storepass $PASSWORD -keypass $PASSWORD -noprompt

echo "#6 Import the signed certificate."
keytool -keystore /tmp/servercerts/serverkeystore.jks -alias uumdm -import -file /tmp/servercerts/cert-signed -storepass $PASSWORD -keypass $PASSWORD -noprompt

echo "#7 Import the CA certificate file created in step 2 to the Kafka server's trust store."
keytool -keystore /tmp/servercerts/servertruststore.jks -alias CARoot -import -file ca-cert -storepass $PASSWORD -keypass $PASSWORD -noprompt

cp /tmp/servercerts/* /tmp/clientcerts/

echo "#8 create the client trust store file"
keytool -keystore /tmp/clientcerts/clienttruststore.jks -alias CARoot -import -file /tmp/clientcerts/ca-cert -storepass $PASSWORD -keypass $PASSWORD -noprompt

echo "#9 Generate the key and certificate for the client using the keytool utility."
keytool -keystore /tmp/clientcerts/clientkeystore.jks -alias localhost -validity 365 -genkey -keyalg RSA -storepass $PASSWORD -keypass $PASSWORD -dname "CN=$CERT_COMMON_NAME, OU=$CERT_ORG_UNIT, O=$CERT_ORG, L=$CERT_CITY, ST=$CERT_STATE, C=$CERT_COUNTRY" -noprompt

echo "#10 Export the certificate from the key store."
keytool -keystore /tmp/clientcerts/clientkeystore.jks -alias localhost -certreq -file /tmp/clientcerts/cert-file -storepass $PASSWORD -keypass $PASSWORD -noprompt

echo "#11 Sign the certificate."
openssl x509 -req -CA /tmp/clientcerts/ca-cert -CAkey /tmp/clientcerts/ca-key -in /tmp/clientcerts/cert-file -out /tmp/clientcerts/cert-signed -days 365 -CAcreateserial -extfile ./openssl.cnf -extensions req_ext -passin pass:$PASSWORD

echo "#12 Import the CA certificate"
keytool -keystore /tmp/clientcerts/clientkeystore.jks -alias CARoot -import -file /tmp/clientcerts/ca-cert -storepass $PASSWORD -keypass $PASSWORD -noprompt

echo "#13 Generate the key and certificate for each machine in the Kafka cluster using the keytool utility."
keytool -keystore /tmp/clientcerts/clientkeystore.jks -alias localhost -import -file /tmp/clientcerts/cert-signed -storepass $PASSWORD -keypass $PASSWORD -noprompt
