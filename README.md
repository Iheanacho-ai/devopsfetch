# Building `devopsfetch` 

## Overview
`devopsfetch` is a command-line tool designed for collecting and displaying system information. This information includes active ports, user logins, Nginx configurations, Docker images, and container statuses. Additionally, it provides a systemd service for continuous monitoring and logging of these activities.

## Installation and Configuration
To install the `devopsfetch` tool, you need to run the `install_devopsfetch.sh`installation script. This script installs the tools you need to successfully use the `devopsfetch` tool on your Ubuntu system and then installs and starts the `devopsfetch` tool as a service in your system.

The `install_devopsfetch.sh` script, firsts ensures that it is being run as the root user, if its not it prints out an error and then exits with a status code of 1.

```sh
#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi
```

Next, it installs the dependencies the tool requires to run:
```sh
# Install dependencies
install_dependencies() {
    echo "Installing necessary packages..."
    apt-get update
    apt-get install -y net-tools docker.io nginx
}
```

Next, the script copies the `devopsfetch` executable to `/usr/local/bin/` and sets the executable permission on it.

```sh
# Install devopsfetch
install_devopsfetch() {
    echo "Installing devopsfetch..."
    cp devopsfetch /usr/local/bin/devopsfetch
    chmod +x /usr/local/bin/devopsfetch
}
```
 
After copying the executable, the next step is to create a systemd service file `/etc/systemd/system/devopsfetch.service`. This file specifies:
- **Unit Section**: Describes the service and specifies it should start after the network is up.
- **Service Section**: Configures the service to execute /usr/local/bin/devopsfetch, restart automatically if it fails, and run as the root user.
- **Install Section**: Configures the service to be wanted by the multi-user target (i.e., it should be started in a multi-user system state).



```sh
# Create systemd service file
create_systemd_service() {
    echo "Creating systemd service..."
    SERVICE_FILE="/etc/systemd/system/devopsfetch.service"
    bash -c "cat > $SERVICE_FILE <<EOF
[Unit]
Description=DevOpsFetch Monitoring Service
After=network.target

[Service]
ExecStart=/usr/local/bin/devopsfetch
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF"
}

```

Then it defines a function `enable_and_start_service` that reloads the systemd configuration to recognize the new service, enables the service to start on boot, and starts the service immediately.

```sh
# Enable and start the service
enable_and_start_service() {
    echo "Enabling and starting the devopsfetch service..."
    systemctl daemon-reload
    systemctl enable devopsfetch.service
    systemctl start devopsfetch.service
}

```

Finally, the script calls all the previosuly defined functions inorder to perform the installation and setup the tasks. When the installation is completed and all the tasks are done, it prints out an "Installation complete" message to your console.

```sh
install_dependencies
install_devopsfetch
create_systemd_service
enable_and_start_service

echo "Installation complete."
```

## Running the Installation Script
Run this command to start the installation script:

```
chmod +x install_devopsfetch.sh
./install_devopsfetch.sh
```

## Using the `devopsfetch` tool
The `devopsfetch` tool accepts arguments that tells the tool what information you would like to learn about your system. These arguements are:
- `-p`, `--port`: Display all active ports and services or detailed information about a specific port.

**Usage** 
```
./devopsfetch -p
./devopsfetch -p 8080
```

- `-d`, `--docker`: List all Docker images and containers or provide detailed information about a specific container.

**Usage**
```
./devopsfetch -d
./devopsfetch -d container_name
```

- `-n`, `--nginx`: Display all Nginx domains and their ports or detailed configuration information for a specific domain.

```
./devopsfetch -n
./devopsfetch -n example.com
```

- `-u`, `--users`: List all users and their last login times, or provide detailed information about a specific user.

```
./devopsfetch -u
./devopsfetch -u username
```

- `-t`, `--time`: Display activities within a specified time range.

```
./devopsfetch -t '2024-07-23 00:00:00'
./devopsfetch -t '2024-07-23 00:00:00' '2024-07-24 00:00:00'
```

- `-h`, `--help`: Displays all available options.

```
./devopsfetch -h
```
## Logging and Monitoring
All logs are written to `devopsfetch.log`. The logs include:
- `INFO`: Successful operations and activities.
- `ERROR`: Errors encountered during execution.
