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

LOG_FILE="devopsfetch.log"

# Generate logs and passwords 
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1 - $2" >> $LOG_FILE
}

# display all active ports
display_ports() {
    if [ -z "$1" ]; then 
        echo "Active ports and services"
        if ss -tuln | column -t; then
            log_message "INFO" "Listed all active ports and services"
        else
            log_message "ERROR" "Error listing out the active ports and services"
        fi
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
        echo "Docker images:"
        if docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}"; then
            echo "Docker containers:"
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
            log_message "INFO" "Listed all Docker images and containers"
        else 
            log_message "ERROR" "Error listing out all the docker images and containers"
        fi
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
        echo "Nginx domains and ports:"
        if grep -E 'server_name|listen' /etc/nginx/sites-enabled/* | paste - - | awk '{print $1, $3}' | column -t; then
            log_message "INFO" "Listed all Nginx domains and ports"
        else
            log_message "ERROR" "Error listing out all the Nginx domains and ports"
        fi
    else
        if grep -A10 "server_name $nginx" /etc/nginx/sites-enabled/* | column -t; then
            log_message "INFO" "Provided detailed information for server $1"
        else
            log_message "ERROR" "Error providing the detailed information for server $1"
        fi
    fi
}

# display all users
display_users() {
    if [ -z "$1" ]; then
        echo "Users and last login times:"
        if last -a | column -t; then
            log_message "INFO" "Listed all users and their last logged in times"
        else
            log_message "ERROR" "Error listing all the users"
        fi
    else
        echo "Detailed information for user: $1"
        if last -a | grep "$1" | column -t; then
            log_message "INFO" "Provided detailed information for user $1"
        else
            log_message "ERROR" "Error providing information for user $1"
        fi
    fi
}

#display time range
display_time_range() {
   if [ -z "$2" ]; then # Check if only one argument was provided
        echo "Activities on $1:"
        if journalctl --since "$1" --until "$1 23:59:59" | tail -n 50; then
            log_message "INFO" "Listed all the activities on day $1"
        else 
            log_message "ERROR" "Error listing out all the activities on day $1"
        fi
    else
        echo "Activities between $1 and $2:"
        if journalctl --since "$1" --until "$2" | tail -n 50; then
            log_message "INFO" "Listed all activities that happened between $1 and $2"
        else 
            log_message "ERROR" "Error listing out activities that happened between $1 and $2"
        fi
    fi

}


# Store each of the arguments in a variable
while [ "$#" -gt 0 ]; do
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
            ;;
        *) 
            echo "Invalid input argument: $1"
            display_help
            exit 1 
            ;;
    esac
done
