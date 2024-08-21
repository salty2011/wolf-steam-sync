# Wolf Steam Library Sync Watcher

> ⚠️ **DEVELOPMENT STATUS: This project is currently in development and not actively working. Use at your own risk.** ⚠️

This project contains a Docker container that watches for Wolf Steam containers and syncs their game libraries to a shared location. It's designed to efficiently manage game files across multiple Steam instances.

## Features

- Monitors Docker for Wolf Steam containers
- Syncs game files and ACF files when a container stops
- Preserves existing files in the shared library
- Uses rsync for efficient file transfer
- Runs with specified user and group IDs for proper file permissions

## Prerequisites
- Access to the Docker socket
- A consolidated folder folder, see below

The `/wolf` directory should be structured as follows:

```
/wolf
├── clients
│   └── temp
│       ├── [container_id_1]
│       │   └── upper
│       │       └── steamapps
│       │           ├── common
│       │           │   └── [game_folders]
│       │           └── [acf_files]
│       └── [container_id_2]
│           └── ...
└── library
    └── steamapps
        ├── common
        │   └── [shared_game_folders]
        └── [shared_acf_files]
```

Ensure these directories exist and have the correct permissions before running the container.

## Building the Container

1. Clone this repository:
   ```
   git clone https://github.com/salty2011/wolf-steam-sync.git
   cd wolf-steam-sync
   ```

2. Build the Docker image:
   ```
   docker build -t wolf-steam-sync-watcher:latest .
   ```

## Running the Container

Launch the container with the following command:

```bash
docker run -d \
  --name wolf-steam-sync-watcher \
  -e PUID=99 \
  -e PGID=100 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /wolf:/wolf \
  --restart unless-stopped \
  wolf-steam-sync-watcher:latest
```

Replace `99` and `100` with your desired user and group IDs.

## Configuration

The script uses the following directory structure:

- `/wolf/clients/temp`: Temporary location for individual Steam container data
- `/wolf/library`: Shared Steam library location

Ensure these directories exist and have the correct permissions.

## Monitoring

To view the logs of the running container:

```bash
docker logs wolf-steam-sync-watcher
```

To follow the logs in real-time:

```bash
docker logs -f wolf-steam-sync-watcher
```

## Troubleshooting

If you encounter issues:

1. Check the logs for any error messages.
2. Ensure the container has the necessary permissions to access the Docker socket and the `/wolf` directory.
3. Verify that the PUID and PGID match the ownership requirements of your system.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
