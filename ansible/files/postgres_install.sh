#!/bin/bash

# Install docker-compose from script if not already installed
if ! command -v docker-compose &> /dev/null; then
  echo "docker-compose not found. Installing..."
  curl -SL https://github.com/docker/compose/releases/download/v2.17.2/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi

# Define network name
NETWORK_NAME="node_network"

# Check if the network exists
if ! docker network ls | grep -q "$NETWORK_NAME"; then
  echo "Network $NETWORK_NAME does not exist. Creating it..."
  docker network create "$NETWORK_NAME"
else
  echo "Network $NETWORK_NAME already exists."
fi

# Clean up
docker stop obscuronode-postgres
docker rm obscuronode-postgres
rm -rf ./postgres

# Create necessary directories
mkdir -p ./postgres/certs
mkdir -p ./postgres/initdb

# Generate SSL certificates
openssl req -new -newkey rsa:2048 -nodes -keyout ./postgres/certs/server.key -out ./postgres/certs/server.csr -subj "/CN=localhost"
openssl x509 -req -days 365 -in ./postgres/certs/server.csr -signkey ./postgres/certs/server.key -out ./postgres/certs/server.crt

# Create Dockerfile
cat <<EOL > ./postgres/Dockerfile
FROM postgres:latest

COPY ./certs/server.crt /var/lib/postgresql/server.crt
COPY ./certs/server.key /var/lib/postgresql/server.key

RUN chown postgres:postgres /var/lib/postgresql/server.crt /var/lib/postgresql/server.key \\
    && chmod 600 /var/lib/postgresql/server.crt /var/lib/postgresql/server.key

# Configure PostgreSQL to use SSL
RUN echo "ssl = on" >> /usr/share/postgresql/postgresql.conf \\
    && echo "ssl_cert_file = '/var/lib/postgresql/server.crt'" >> /usr/share/postgresql/postgresql.conf \\
    && echo "ssl_key_file = '/var/lib/postgresql/server.key'" >> /usr/share/postgresql/postgresql.conf
EOL

# Create docker-compose.yml
cat <<EOL > ./docker-compose.yml
version: '3.8'  # Specify the version of docker-compose

services:
  postgres:
    build: ./postgres
    container_name: obscuronode-postgres
    environment:
      POSTGRES_PASSWORD: pass
    ports:
      - "5432:5432"
    networks:
      - node_network

networks:
  node_network:
    external: true
EOL

# Build and run the Docker Compose setup
docker-compose -p obscuronode-postgres up --build -d
