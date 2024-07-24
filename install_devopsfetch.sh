#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Install dependencies
install_dependencies() {
    echo "Installing necessary packages..."
    apt-get update
    apt-get install -y net-tools docker.io nginx
}

# Install devopsfetch
install_devopsfetch() {
    echo "Installing devopsfetch..."
    cp devopsfetch /usr/local/bin/devopsfetch
    chmod +x /usr/local/bin/devopsfetch
}

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

# Enable and start the service
enable_and_start_service() {
    echo "Enabling and starting the devopsfetch service..."
    systemctl daemon-reload
    systemctl enable devopsfetch.service
    systemctl start devopsfetch.service
}

# Main script execution
install_dependencies
install_devopsfetch
create_systemd_service
enable_and_start_service

echo "Installation complete."
