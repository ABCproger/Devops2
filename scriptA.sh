#!/bin/bash

# Configuration
IMAGE_NAME="abcproger/httpserver"         # Replace with your image name
CPU_BUSY_THRESHOLD=10                    # CPU usage threshold in percentage (busy)
IDLE_THRESHOLD=2                         # CPU usage threshold in percentage (idle)
CHECK_INTERVAL=30                        # Interval between checks (in seconds)
CONSECUTIVE_MINUTES=2                    # Consecutive minutes threshold
UPDATE_INTERVAL=300                      # Interval to check for updates (in seconds)
LOG_FILE="server_monitor.log"            # Log file for all operations

# Container and CPU mapping
declare -A CONTAINERS=( 
    [srv1]=0
    [srv2]=1
    [srv3]=2
)

# Track container states
declare -A BUSY_COUNTERS
declare -A IDLE_COUNTERS

# Function to log messages
log_message() {
    local message=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# Function to start a container on a specific CPU
start_container() {
    local name=$1
    local core=$2
    log_message "Starting container $name on CPU core $core..."
    docker run -d --cpuset-cpus="$core" --name "$name" "$IMAGE_NAME" && \
    log_message "Container $name started successfully."
}

# Function to monitor CPU usage of a container
get_cpu_usage() {
    local container=$1
    docker stats --no-stream --format "{{.CPUPerc}}" "$container" | sed 's/%//'
}

# Function to check if a container exists
container_exists() {
    docker ps -a --format "{{.Names}}" | grep -q "^$1$"
}

# Function to stop a container
stop_container() {
    local name=$1
    log_message "Stopping container $name due to idleness..."
    docker stop "$name" && docker rm "$name" && \
    log_message "Container $name stopped and removed."
}

# Function to remove old stopped containers
cleanup_containers() {
    log_message "Cleaning up unused containers..."
    docker container prune -f > /dev/null && log_message "Unused containers cleaned up."
}

update_container_with_redundancy() {
    local primary=$1        
    local backup=$2        
    local core=$3 

    if ! container_exists "$backup"; then
        log_message "Launching backup container $backup before updating $primary..."
        start_container "$backup" "$core"
        sleep 10 
    fi

    log_message "Stopping and updating $primary..."
    docker stop "$primary"
    docker rm "$primary"
    start_container "$primary" "$core"

    log_message "Stopping backup container $backup after $primary update..."
    docker stop "$backup"
    docker rm "$backup"
}

# Function to update containers
update_containers() {
    log_message "Checking for updates to image $IMAGE_NAME..."

    LOCAL_IMAGE_ID=$(docker images -q "$IMAGE_NAME:latest")

    docker pull "$IMAGE_NAME" > /dev/null
    if [ $? -ne 0 ]; then
        log_message "Failed to pull the latest image. Skipping update."
        return
    fi

    NEW_IMAGE_ID=$(docker images -q "$IMAGE_NAME:latest")

    # Порівнюємо старий і новий образ
    if [ "$LOCAL_IMAGE_ID" != "$NEW_IMAGE_ID" ]; then
        log_message "New version detected. Updating containers..."

        if container_exists "srv1" && ! container_exists "srv2"; then
            # If only srv1 is running, ensure redundancy
            update_container_with_redundancy "srv1" "srv2" "${CONTAINERS[srv1]}"
        else
            # Update all running containers
            for name in "${!CONTAINERS[@]}"; do
                if container_exists "$name"; then
                    log_message "Updating $name..."
                    docker stop "$name" && docker rm "$name"
                    start_container "$name" "${CONTAINERS[$name]}"
                    sleep 10  # Ensure smooth transition
                fi
            done
        fi
        log_message "All containers updated successfully."
    else
        log_message "No updates available. Image is already up-to-date."
    fi
}


# Main script logic
log_message "Launching srv1..."
start_container srv1 "${CONTAINERS[srv1]}"

LAST_UPDATE_CHECK=$(date +%s)

while true; do
    CURRENT_TIME=$(date +%s)

    # Check each container
    for name in "${!CONTAINERS[@]}"; do
        if container_exists "$name"; then
            CPU_USAGE=$(get_cpu_usage "$name")

            # Check if the container is busy
            if (( $(echo "$CPU_USAGE > $CPU_BUSY_THRESHOLD" | bc -l) )); then
                BUSY_COUNTERS[$name]=$((BUSY_COUNTERS[$name] + 1))
                IDLE_COUNTERS[$name]=0
            elif (( $(echo "$CPU_USAGE < $IDLE_THRESHOLD" | bc -l) )); then
                IDLE_COUNTERS[$name]=$((IDLE_COUNTERS[$name] + 1))
                BUSY_COUNTERS[$name]=0
            else
                BUSY_COUNTERS[$name]=0
                IDLE_COUNTERS[$name]=0
            fi

            # Scale logic
            if [ "$name" = "srv1" ] && [ ${BUSY_COUNTERS[$name]} -ge $((CONSECUTIVE_MINUTES * 60 / CHECK_INTERVAL)) ] && ! container_exists "srv2"; then
                start_container srv2 "${CONTAINERS[srv2]}"
            fi

            if [ "$name" = "srv2" ] && [ ${BUSY_COUNTERS[$name]} -ge $((CONSECUTIVE_MINUTES * 60 / CHECK_INTERVAL)) ] && ! container_exists "srv3"; then
                start_container srv3 "${CONTAINERS[srv3]}"
            fi

            # Idle logic
            if [ "$name" = "srv3" ] && [ ${IDLE_COUNTERS[$name]} -ge $((CONSECUTIVE_MINUTES * 60 / CHECK_INTERVAL)) ]; then
                stop_container srv3
            fi

            if [ "$name" = "srv2" ] && [ ${IDLE_COUNTERS[$name]} -ge $((CONSECUTIVE_MINUTES * 60 / CHECK_INTERVAL)) ]; then
                stop_container srv2
            fi
        fi
    done

    # Update check
    if (( CURRENT_TIME - LAST_UPDATE_CHECK >= UPDATE_INTERVAL )); then
        update_containers
        cleanup_containers
        LAST_UPDATE_CHECK=$CURRENT_TIME
    fi

    sleep $CHECK_INTERVAL
done
