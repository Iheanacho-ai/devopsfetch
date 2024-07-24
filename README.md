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

Next, it copies the `devopsfetch` script to `/usr/local/bin` directory, and sets the script as executable:
```sh
cp devopsfetch /usr/local/bin/devopsfetch
chmod +x /usr/local/bin/devopsfetch

```

Next, it creates a log file at this path `/var/log/devopsfetch.log` and set the log file permissions to `666`, meaning all users can read and write to this file:

```sh
touch /var/log/devopsfetch.log
chmod 666 /var/log/devopsfetch.log

```
 
After creating the log file, the next step is to create a systemd service file `/etc/systemd/system/devopsfetch.service`. This file specifies:
- **Unit Section**: Describes the service and specifies it should start after the network is up.
- **Service Section**: Configures the service to execute /usr/local/bin/devopsfetch, restart automatically if it fails, and run as the root user.
- **Install Section**: Configures the service to be wanted by the multi-user target (i.e., it should be started in a multi-user system state).



```sh
# Create systemd service file
cat << EOF > /etc/systemd/system/devopsfetch.service
[Unit]
Description=DevOpsFetch Monitoring Service
After=network.target

[Service]
ExecStart=/bin/bash -c '/usr/local/bin/devopsfetch -t "$(date -d \"5 minutes ago\" +\"%Y-%m-%d %H:%M:%S\")" "$(date +\"%Y-%m-%d %H:%M:%S\")"'
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF


```

Then it creates a timer that schedules the `devopsfetch` service every 5 minutes:

```sh
# Create timer file for execution every 5 minutes
cat << EOF > /etc/systemd/system/devopsfetch.timer
[Unit]
Description=Run DevOpsFetch every 5 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
EOF


```

Next, the script:
- **Reloads Systemd**: Reloads `systemd` to recognize the new service and timer files.
- **Enables Services**: Configures `systemd` to start the service and timer at boot.
- **Starts Timer**: Starts the timer immediately, which will, in turn, start the devopsfetch service according to the schedule.

```sh
# Reload systemd, enable and start the service and timer
systemctl daemon-reload
systemctl enable devopsfetch.service
systemctl enable devopsfetch.timer
systemctl start devopsfetch.timer

```

After starting the service the script then setups a log rotation to archive old log entries:

```sh
# Set up log rotation
cat << EOF > /etc/logrotate.d/devopsfetch
/var/log/devopsfetch.log {
    hourly
    rotate 288
    compress
    missingok
    notifempty
    create 666 root root
}
EOF


```

In the code block above, the script sets up `logrotate` to manage the log file. It does this:
- **Hourly**: Rotates the log file every hour.
- **Rotate 288**: Keeps 288 hours of logs (12 days).
- **Compress**: Compresses old log files to save space.
- **Missingok**: Ignores errors if the log file is missing.
- **Notifempty**: Does not rotate the log file if it is empty.
- **Create**: Specifies permissions and ownership for the newly created log files.

Finally after the script has installed the dependencies and completed the devopsfetch service setup, the script sends out this information to the user:

```sh
echo "DevOps fetch has been installed and configured."

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
