#!/bin/bash

# Ensure script exits on failure
set -e

# Check for required argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <REPO_NAME>"
    exit 1
fi

# Assign input argument
REPO_NAME="$1"

# Define docker-compose file path
COMPOSE_FILE="docker-compose.yml"

# Find the highest existing ports in docker-compose.yml
HIGHEST_120_PORT=$(grep -oP '120\d+' "$COMPOSE_FILE" | sort -nr | head -n 1)
HIGHEST_150_PORT=$(grep -oP '150\d+' "$COMPOSE_FILE" | sort -nr | head -n 1)

# Set default values if no existing ports found
if [ -z "$HIGHEST_120_PORT" ]; then
    NEW_120_PORT=1201
else
    NEW_120_PORT=$((HIGHEST_120_PORT + 1))
fi

if [ -z "$HIGHEST_150_PORT" ]; then
    NEW_150_PORT=1501
else
    NEW_150_PORT=$((HIGHEST_150_PORT + 1))
fi

# Find the highest container number
HIGHEST_CONTAINER=$(grep -oP 'framework-app-\d+' "$COMPOSE_FILE" | grep -oP '\d+' | sort -nr | head -n 1)

# Set default if no container found
if [ -z "$HIGHEST_CONTAINER" ]; then
    NEW_CONTAINER_NUM=1
else
    NEW_CONTAINER_NUM=$((HIGHEST_CONTAINER + 1))
fi

mkdir "model$NEW_CONTAINER_NUM"
cp model/requirements.txt "model$NEW_CONTAINER_NUM/requirements.txt"

echo 'schedule: "* * * * *"  # Run Every Minute' >> controller$NEW_CONTAINER_NUM.yaml
echo 's3:' >> controller$NEW_CONTAINER_NUM.yaml
echo '  - name: ""' >> controller$NEW_CONTAINER_NUM.yaml
echo '  - access_key: ""' >> controller$NEW_CONTAINER_NUM.yaml
echo '  - secret_key: ""' >> controller$NEW_CONTAINER_NUM.yaml


# Append the new service to the docker-compose.yml file
cat <<EOL >> "$COMPOSE_FILE"

  framework-$NEW_CONTAINER_NUM:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        - NO_CACHE=1
    volumes:
      - ./controller$NEW_CONTAINER_NUM.yaml:/app/controller.yaml
      - ./model$NEW_CONTAINER_NUM:/app/model
    ports:
      - "$NEW_120_PORT:3000"  # Frontend port
      - "$NEW_150_PORT:5000"  # Backend port
    environment:
      - NODE_ENV=production
      - REACT_APP_API_URL=http://localhost:5000
    privileged: true  # Required for Docker-in-Docker
    restart: unless-stopped
    container_name: framework-app-$NEW_CONTAINER_NUM
EOL

echo "Added framework-$NEW_CONTAINER_NUM to $COMPOSE_FILE with ports $NEW_120_PORT"
