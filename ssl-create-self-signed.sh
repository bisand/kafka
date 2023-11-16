#!/bin/sh

# From: https://www.ibm.com/docs/en/imdm/12.0?topic=kafka-creating-ssl-artifacts

mkdir -p /tmp/servercerts/ /tmp/clientcerts/

# Generate the self-signed certificate authority (CA) 
openssl req -new -x509 -keyout /tmp/servercerts/ca-key -out /tmp/servercerts/ca-cert -days 365

# Generate the key and certificate for each machine in the Kafka cluster using the keytool utility. 
keytool -keystore /tmp/clientcerts/clientkeystore.jks -alias localhost -import -file /tmp/clientcerts/cert-signed

# Generate the SSL key store and certificate for the Kafka brokers.
keytool -keystore /tmp/servercerts/serverkeystore.jks -alias uumdm -validity 365 -genkey -keyalg RSA

# Sign the certificates in the key store using the CA that you generated in step 2.
keytool -keystore /tmp/servercerts/serverkeystore.jks -alias uumdm -certreq -file /tmp/servercerts/cert-file

# Sign the certificate. 
openssl x509 -req -CA /tmp/servercerts/ca-cert -CAkey /tmp/servercerts/ca-key -in /tmp/servercerts/cert-file -out /tmp/servercerts/cert-signed -days 365 -CAcreateserial -extfile ./openssl.cnf -extensions req_ext

# Import the CA certificate.
keytool -keystore /tmp/servercerts/serverkeystore.jks -alias CARoot -import -file /tmp/servercerts/ca-cert

# Import the signed certificate. 
keytool -keystore /tmp/servercerts/serverkeystore.jks -alias uumdm -import -file /tmp/servercerts/cert-signed

# Import the CA certificate file created in step 2 to the Kafka server's trust store.
keytool -keystore /tmp/servercerts/servertruststore.jks -alias CARoot -import -file ca-cert -storepass xxxxxxx

cp /tmp/servercerts/ca-cert /tmp/clientcerts/
cp /tmp/servercerts/cert-file /tmp/clientcerts/

# create the client trust store file
keytool -keystore /tmp/clientcerts/clienttruststore.jks -alias CARoot -import -file /tmp/clientcerts/ca-cert -storepass xxxxxxx

# Generate the key and certificate for the client using the keytool utility.
keytool -keystore /tmp/clientcerts/clientkeystore.jks -alias localhost -validity 365 -genkey -keyalg RSA

# Export the certificate from the key store. 
keytool -keystore /tmp/clientcerts/clientkeystore.jks -alias localhost -certreq -file /tmp/clientcerts/cert-file

# Sign the certificate. 
openssl x509 -req -CA /tmp/clientcerts/ca-cert -CAkey /tmp/clientcerts/ca-key -in /tmp/clientcerts/cert-file -out /tmp/clientcerts/cert-signed -days 365 -CAcreateserial

# Import the CA certificate
keytool -keystore /tmp/clientcerts/clientkeystore.jks -alias CARoot -import -file /tmp/clientcerts/ca-cert

# Import the signed certificate
keytool -keystore /tmp/clientcerts/clientkeystore.jks -alias localhost -import -file /tmp/clientcerts/cert-signed


