#!/bin/sh

# show help
display_help() {
    echo "Usage: devopsfetch [OPTIONS] [ARGUMENTS]"
    echo ""
    echo "Options:"
    echo "  -p, --port      Displays all the active ports and services or detailed information about a specific port"
    echo "  -d, --docker    Displays all the Docker images and containers or detailed information about a specific container"
    echo "  -n, --nginx     Displays all the Nginx domains and their ports or detailed configuration information for a specific domain"
    echo "  -u, --users     Displays all the users, their last login times, and detailed information about a specific user"
    echo "  -t, --time      Display activities within a specified time range"
    echo "  -h, --help      Displays all the available options"
}

LOG_FILE="/var/log/devopsfetch.log"

# Generate logs and passwords 
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1 - $2" >> $LOG_FILE
}

# Create a table row with border
create_table_row() {
    printf "| %-20s | %-20s |\n" "$1" "$2"
}

# Create a table border
create_table_border() {
    printf "+----------------------+----------------------+\n"
}

# display all active ports
display_ports() {
    if [ -z "$1" ]; then 
        echo "**************************** ACTIVE PORTS ****************************"
        create_table_border
        create_table_row "USER" "PORT"
        create_table_border
        ss -tuln | awk '{print $5}' | grep -Eo ':[0-9]+' | grep -Eo '[0-9]+' | sort -u | while read port; do
            user=$(ss -tuln | grep ":$port" | awk '{print $1}' | sort -u)
            create_table_row "$user" "$port"
        done
        create_table_border
        log_message "INFO" "Listed all active ports and services"
    else
        echo "Display information on port: $1"
        if ss -lntu | grep ":$1" | column -t; then
            log_message "INFO" "Listed information on port $1"
        else
            log_message "ERROR" "Error listing out information on port $1"
        fi
    fi
}

# display all docker containers
display_docker() {
    if [ -z "$1" ]; then
        echo "**************************** DOCKER IMAGES ****************************"
        create_table_border
        create_table_row "REPOSITORY" "TAG"
        create_table_border
        docker images --format "table {{.Repository}}\t{{.Tag}}" | tail -n +2 | while read line; do
            repo=$(echo $line | awk '{print $1}')
            tag=$(echo $line | awk '{print $2}')
            create_table_row "$repo" "$tag"
        done
        create_table_border
        echo "************************** DOCKER CONTAINERS **************************"
        create_table_border
        create_table_row "NAME" "STATUS"
        create_table_border
        docker ps --format "table {{.Names}}\t{{.Status}}" | tail -n +2 | while read line; do
            name=$(echo $line | awk '{print $1}')
            status=$(echo $line | awk '{print $2}')
            create_table_row "$name" "$status"
        done
        create_table_border
        log_message "INFO" "Listed all Docker images and containers"
    else
        echo "Information on $1"
        if docker inspect "$1"; then
            log_message "INFO" "Provided detailed information for $1"
        else
            log_message "ERROR" "Error listing out information for $1"
        fi
    fi
}

# display all Nginx domains
display_nginx() {
    if [ -z "$1" ]; then 
        echo "*************************** NGINX DOMAINS ****************************"
        create_table_border
        create_table_row "DOMAIN" "PORT"
        create_table_border
        grep -E 'server_name|listen' /etc/nginx/sites-enabled/* | paste - - | awk '{print $3, $6}' | while read line; do
            domain=$(echo $line | awk '{print $1}')
            port=$(echo $line | awk '{print $2}')
            create_table_row "$domain" "$port"
        done
        create_table_border
        log_message "INFO" "Listed all Nginx domains and ports"
    else
        if grep -A10 "server_name $1" /etc/nginx/sites-enabled/* | column -t; then
            log_message "INFO" "Provided detailed information for server $1"
        else
            log_message "ERROR" "Error providing the detailed information for server $1"
        fi
    fi
}

# display all users
display_users() {
    if [ -z "$1" ]; then
        echo "**************************** USER LOGIN ****************************"
        create_table_border
        create_table_row "Username" "Last Login"
        create_table_border
        last -a | head -n -2 | while read line; do
            username=$(echo $line | awk '{print $1}')
            last_login=$(echo $line | awk '{print $4, $5, $6, $7, $8, $9, $10}')
            create_table_row "$username" "$last_login"
        done
        create_table_border
        log_message "INFO" "Listed all users and their last logged in times"
    else
        echo "Detailed information for user: $1"
        if last -a | grep "$1" | column -t; then
            log_message "INFO" "Provided detailed information for user $1"
        else
            log_message "ERROR" "Error providing information for user $1"
        fi
    fi
}

# display time range
display_time_range() {
    if [ -z "$2" ]; then # Check if only one argument was provided
        echo "Activities on $1:"
        if journalctl --since "$1" --until "$1 23:59:59" | tail -n 50 | column -t; then
            log_message "INFO" "Listed all the activities on day $1"
        else 
            log_message "ERROR" "Error listing out all the activities on day $1"
        fi
    else
        echo "Activities between $1 and $2:"
        if journalctl --since "$1" --until "$2" | tail -n 50 | column -t; then
            log_message "INFO" "Listed all activities that happened between $1 and $2"
        else 
            log_message "ERROR" "Error listing out activities that happened between $1 and $2"
        fi
    fi
}

# Store each of the arguments in a variable
case $1 in 
    -p|--port)
        display_ports "$2" 
        shift
        ;;
    -d|--docker) 
        display_docker "$2"
        shift
        ;;
    -n|--nginx) 
        display_nginx "$2"
        shift
        ;;
    -u|--users) 
        display_users "$2" 
        shift
        ;;
    -t|--time) 
        display_time_range "$2" "$3"
        shift
        ;;
    -h|--help) 
        display_help 
        exit 0 
        shift
        ;;
    *) 
        echo "Invalid input argument: $1"
        display_help
        exit 1 
        ;;
esac
