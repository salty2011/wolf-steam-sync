# Use a lightweight base image
FROM alpine:3.14

# Install necessary packages
RUN apk add --no-cache \
    bash \
    docker-cli \
    rsync

# Copy the script into the container
COPY steam-library-sync-watcher.sh /app/steam-library-sync-watcher.sh

# Make the script executable
RUN chmod +x /app/steam-library-sync-watcher.sh

# Set the working directory
WORKDIR /app

# Run the script
CMD ["bash", "steam-library-sync-watcher.sh"]
