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

# display all active ports
display_ports() {
    if [ -z "$1" ]; then 
        echo "Active ports and services"
        ss -tuln | column -t
    else
        echo "Display information on port: $1"
        ss -lntu | grep ":$1" | column -t
    fi
}

# display all docker containers
display_docker() {
    if [ -z "$1" ]; then
        echo "Docker images:"
        docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}"
        echo "Docker containers:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "Information on $1"
        docker inspect "$1"
    fi
}

# display all Nginx domains
display_nginx() {
    if [ -z "$1" ]; then 
        echo "Nginx domains and ports:"
        grep -E 'server_name|listen' /etc/nginx/sites-enabled/* | paste - - | awk '{print $1, $3}' | column -t 
    else
        grep -A10 "server_name $nginx" /etc/nginx/sites-enabled/* | column -t
    fi
}

# display all users
display_users() {
    if [ -z "$1" ]; then
        echo "Users and last login times:"
        last -a | column -t
    else
        echo "Detailed information for user: $1"
        last -a | grep "$1" | column -t
    fi
}

#display time range
display_time_range() {
   if [ -z "$2" ]; then # Check if only one argument was provided
        echo "Activities on $1:"
        journalctl --since "$1" --until "$1 23:59:59" | tail -n 50 
    else
        echo "Activities between $1 and $2:"
        journalctl --since "$1" --until "$2" | tail -n 50
    fi

}


# Store each of the arguments in a variable
while [ "$#" -gt 0 ]; do
    case $1 in 
        -p|--port) 
            display_ports "$2" | tee -a "$LOG_FILE"
            shift
            ;;
        -d|--docker) 
            display_docker "$2" | tee -a "$LOG_FILE"
            shift
            ;;
        -n|--nginx) 
            display_nginx "$2" | tee -a "$LOG_FILE"
            shift
            ;;
        -u|--users) 
            display_users "$2" | tee -a "$LOG_FILE"
            shift
            ;;
        -t|--time) 
            display_time_range "$2" "$3" | tee -a "$LOG_FILE"
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
