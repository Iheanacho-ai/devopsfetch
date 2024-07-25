#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Copy main script to /usr/local/bin
cp devopsfetch.sh /usr/local/bin/devopsfetch
chmod +x /usr/local/bin/devopsfetch

# Create log file and set permissions
touch /var/log/devopsfetch.log
chmod 666 /var/log/devopsfetch.log

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


# Reload systemd, enable and start the service and timer
systemctl daemon-reload
systemctl enable devopsfetch.service
systemctl start devopsfetch.service

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

echo "DevOpsFetch has been installed and configured."