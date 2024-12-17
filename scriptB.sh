#!/bin/bash

# Target server URL
SERVER_URL="127.0.0.1/compute"

# Function to make an HTTP request
make_request() {
    local wait_time=$((RANDOM % 6 + 5))  # Generate random delay between 5 and 10 seconds
    echo "Waiting for $wait_time seconds before making a request..."
    sleep "$wait_time"
    echo "Sending request to $SERVER_URL..."
    curl -i -X GET "$SERVER_URL" &
}

# Main loop to make requests asynchronously
while true; do
    make_request
done
