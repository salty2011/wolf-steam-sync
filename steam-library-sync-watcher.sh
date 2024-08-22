#!/bin/bash

# Configuration
WOLF_ROOT="/wolf"
CLIENTS_DIR="${WOLF_ROOT}/clients/temp"
LIBRARY_DIR="${WOLF_ROOT}/library"

# Use environment variables or default to the IDs we set in the Dockerfile
PUID=${PUID:-99}
PGID=${PGID:-100}

log() {
    echo "$(date): $1"
}

get_wolf_steam_containers() {
    docker ps --format '{{.ID}}\t{{.Names}}' | awk '/WolfSteam_/ {print $1}'
}

get_container_name() {
    docker inspect --format '{{.Name}}' "$1" 2>/dev/null | sed 's/^\///' || echo "Unknown"
}

get_steam_sync_path() {
    local container_id=$1
    echo "${CLIENTS_DIR}/${container_id}/upper"
}

sync_steam_data() {
    local container_id=$1
    local sync_path=$2
    local container_name=$(get_container_name "$container_id")
    log "Starting sync process for closed container: $container_name (ID: $container_id)"
    
    local library_steamapps_dir="${LIBRARY_DIR}/steamapps"
    local library_common_dir="${library_steamapps_dir}/common"
    
    # Ensure source and destination directories exist
    if [ ! -d "$sync_path" ]; then
        log "Error: Client Steam directory not found: $sync_path"
        return 1
    fi
    
    if [ ! -d "$library_steamapps_dir" ]; then
        log "Error: Library steamapps directory not found: $library_steamapps_dir"
        return 1
    fi
    
    # Create library common directory if it doesn't exist
    mkdir -p "$library_common_dir"
    
    # Sync common folder
    local source_common_dir="${sync_path}/steamapps/common"
    if [ -d "$source_common_dir" ]; then
        log "Syncing common directory for container $container_name (ID: $container_id)"
        rsync -av --ignore-errors --update "$source_common_dir/" "$library_common_dir/"
    else
        log "Warning: common directory not found in source: $source_common_dir"
    fi
    
    # Sync ACF files
    log "Syncing ACF files for container $container_name (ID: $container_id)"
    find "$sync_path/steamapps" -maxdepth 1 -name "*.acf" -exec rsync -av --ignore-errors --update {} "$library_steamapps_dir/" \;
    
    local sync_status=$?
    if [ $sync_status -eq 0 ]; then
        log "Successfully synced Steam data for container $container_name (ID: $container_id)"
    elif [ $sync_status -eq 23 ]; then
        log "Partial success: Some files were not transferred for container $container_name (ID: $container_id)"
    else
        log "Failed to sync Steam data for container $container_name (ID: $container_id)"
    fi
    
    # List contents of source and destination for verification
    log "Contents of source steamapps directory:"
    ls -R "${sync_path}/steamapps"
    log "Contents of library steamapps directory:"
    ls -R "$library_steamapps_dir"
    
    # Always attempt to remove the container folder
    local container_folder="${CLIENTS_DIR}/${container_id}"
    log "Removing container folder: $container_folder"
    rm -rf "${container_folder:?}" || log "Warning: Failed to remove container folder: $container_folder"
    
    log "Sync process completed for container: $container_name (ID: $container_id)"
}

log "Wolf Steam Library Sync Watcher started"
log "Using PUID: $PUID, PGID: $PGID"
log "Monitoring for WolfSteam containers..."

# Main loop
declare -A container_sync_paths
previous_containers=$(get_wolf_steam_containers)

# Initialize sync paths for existing containers
for container_id in $previous_containers; do
    sync_path=$(get_steam_sync_path "$container_id")
    container_sync_paths["$container_id"]="$sync_path"
    container_name=$(get_container_name "$container_id")
    log "Detected existing container $container_name (ID: $container_id) with sync path: $sync_path"
done

while true; do
    current_containers=$(get_wolf_steam_containers)
    
    # Check for containers that have stopped
    for container_id in $previous_containers; do
        if ! echo "$current_containers" | grep -q "^$container_id$"; then
            container_name=$(get_container_name "$container_id")
            log "Wolf Steam container stopped: $container_name (ID: $container_id). Starting sync process."
            if [ -n "${container_sync_paths[$container_id]}" ]; then
                sync_steam_data "$container_id" "${container_sync_paths[$container_id]}"
                unset container_sync_paths["$container_id"]
            else
                log "Error: No sync path found for container $container_name (ID: $container_id)"
            fi
        fi
    done
    
    # Check for new containers
    for container_id in $current_containers; do
        if ! echo "$previous_containers" | grep -q "^$container_id$"; then
            container_name=$(get_container_name "$container_id")
            log "New Wolf Steam container detected: $container_name (ID: $container_id)"
            sync_path=$(get_steam_sync_path "$container_id")
            container_sync_paths["$container_id"]="$sync_path"
            log "Sync path for $container_name (ID: $container_id): $sync_path"
        fi
    done
    
    previous_containers=$current_containers
    log "Waiting for container changes..."
    sleep 10
done
