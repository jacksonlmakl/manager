#!/bin/bash
# Ensure script exits on failure
set -e
# Start the main containers
echo "Starting main containers..."
docker compose up -d
echo "Main containers started"
# Get all running container IDs
container_ids=$(docker ps -q)
echo "Found $(echo $container_ids | wc -w) running containers"
# Loop through each container and execute the deploy script
for container_id in $container_ids; do
  container_name=$(docker inspect --format='{{.Name}}' $container_id | sed 's/\///')
  echo "=========================="
  echo "Processing container: $container_id ($container_name)"
  
  # Create a directory for logs if it doesn't exist
  mkdir -p ./logs
  # Set the log file path for this container
  log_file="./logs/${container_name}.job.log"
  temp_log_file="./logs/${container_name}.temp.log"
  
  # Execute the run script in each container and save output to temporary log file
  echo "Running execution script in container $container_id"
  echo "--- Job Output Begin ---"
  sudo docker container exec "$container_id" sudo bash bin/deploy > deploy.txt 2>&1 &
  if sudo docker container exec $container_id sudo bash bin/run > "$temp_log_file" 2>&1; then
    # Filter out "requirement already satisfied" and similar messages
    grep -v "Requirement already satisfied\|is already the newest version\|upgraded, 0 newly installed, 0 to remove\|WARNING: apt does not\|InRelease\|installing" "$temp_log_file" > "$log_file"
    
    # Show the filtered log content
    cat "$log_file"

    echo "--- Job Output End ---"
    echo "✅ Successfully ran execution script in container $container_id"
    echo "✅ Filtered logs saved to $log_file"
    # Remove temporary log file
    rm "$temp_log_file"
  else
    # On error, keep the full log content
    mv "$temp_log_file" "$log_file"
    echo "--- Job Output End ---"
    echo "❌ Failed to run execution script in container $container_id"
    echo "❌ Check $log_file for details"
  fi
  echo "=========================="
done
echo "All containers started and execution scripts executed"
