#!/bin/bash

# Function to check the OS and determine package manager
#!/bin/bash

# Define color codes using tput
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NC=$(tput sgr0) # No Color

# Function to check the OS and determine package manager
check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        os_name="$NAME"
        os_version="$VERSION_ID"
    elif [ -f /etc/issue ]; then
        os_info=$(cat /etc/issue | head -n 1)
        os_name=$(echo "$os_info" | awk '{print $1}')
        os_version=$(echo "$os_info" | awk '{print $3}' | cut -d '.' -f1)
    else
        os_name="Unknown"
        os_version="Unknown"
    fi

    case "$os_name" in
        Ubuntu|Debian)
            PACKAGE_MANAGER="apt"
            ;;
        CentOS)
            if [ "$os_version" -lt 7 ]; then
                echo "${RED}CentOS version is less than 7. Exiting.${NC}"
                exit 1
            fi
            PACKAGE_MANAGER="yum"
            ;;
        RedHat|Fedora|RedHatEnterpriseServer)
            PACKAGE_MANAGER="yum"
            ;;
        *)
            echo "${RED}Unsupported distribution: $os_name${NC}"
            exit 1
            ;;
    esac
    echo "${GREEN}Detected OS: $os_name $os_version${NC}"
}


# Function to install Elasticsearch
install_elasticsearch() {
    echo "Installing Elasticsearch..."
    if [ "$PACKAGE_MANAGER" = "apt" ]; then
        wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
        echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
        sudo apt-get update
        sudo apt-get install elasticsearch -y
    elif [ "$PACKAGE_MANAGER" = "yum" ]; then
        sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
        echo "[elasticsearch-7.x]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md" | sudo tee /etc/yum.repos.d/elasticsearch.repo
        sudo yum install elasticsearch -y
    fi

    # Configure Elasticsearch to start on boot
    sudo systemctl daemon-reload
    sudo systemctl enable elasticsearch.service

    echo "Elasticsearch installed."
}

# Function to install Kibana
install_kibana() {
    echo "Installing Kibana..."
    if [ "$PACKAGE_MANAGER" = "apt" ]; then
        sudo apt-get install kibana -y
    elif [ "$PACKAGE_MANAGER" = "yum" ]; then
        sudo yum install kibana -y
    fi

    # Configure Kibana to start on boot
    sudo systemctl daemon-reload
    sudo systemctl enable kibana.service

    echo "Kibana installed."
}

# Function to start services
start_services() {
    echo "Starting Elasticsearch..."
    sudo systemctl start elasticsearch.service
    echo "Elasticsearch started."

    echo "Starting Kibana..."
    sudo systemctl start kibana.service
    echo "Kibana started."
}

# Function to remove Elasticsearch and purge related files
remove_elasticsearch() {
    echo "Removing Elasticsearch and purging related files..."
    sudo systemctl stop elasticsearch.service
    sudo systemctl disable elasticsearch.service
    if [ "$PACKAGE_MANAGER" = "apt" ]; then
        sudo apt-get remove --purge elasticsearch -y
    elif [ "$PACKAGE_MANAGER" = "yum" ]; then
        sudo yum remove elasticsearch -y
    fi
    sudo rm -rf /etc/elasticsearch
    sudo rm -rf /var/lib/elasticsearch
    echo "Elasticsearch and related files have been removed."
}

# Function to remove Kibana and purge related files
remove_kibana() {
    echo "Removing Kibana and purging related files..."
    sudo systemctl stop kibana.service
    sudo systemctl disable kibana.service
    if [ "$PACKAGE_MANAGER" = "apt" ]; then
        sudo apt-get remove --purge kibana -y
    elif [ "$PACKAGE_MANAGER" = "yum" ]; then
        sudo yum remove kibana -y
    fi
    sudo rm -rf /etc/kibana
    sudo rm -rf /var/lib/kibana
    echo "Kibana and related files have been removed."
}

# Function to create an Elasticsearch user
create_user() {
    read -p "Enter username: " username
    read -sp "Enter password: " password
    echo
    echo "Creating user $username..."
    curl -X POST "localhost:9200/_security/user/$username" -H 'Content-Type: application/json' -d'{
        "password" : "'"$password"'",
        "roles" : [ "superuser" ]
    }'
    echo
    echo "User $username created."
}

# Function to delete an Elasticsearch user
delete_user() {
    read -p "Enter username to delete: " username
    echo "Deleting user $username..."
    curl -X DELETE "localhost:9200/_security/user/$username"
    echo
    echo "User $username deleted."
}

# Main script starts here
# celar the screen
clear
# Welcome message
echo  "${GREEN}Welcome to the ELK Stack Auto-Installer${NC}"
echo "This script will help you install and configure Elasticsearch and Kibana."
echo "Please ensure you have the necessary permissions to proceed."
echo "---------------------------------------------"
check_os

# Display menu
echo "Please choose an option:"
echo "1. Install Elasticsearch and Kibana"
echo "2. Install only Elasticsearch"
echo "3. Install only Kibana"
echo "4. Remove Elasticsearch and Kibana"
echo "5. Remove only Elasticsearch"
echo "6. Remove only Kibana"
echo "7. Create Elasticsearch user"
echo "8. Delete Elasticsearch user"
read -p "Enter your choice (1-8): " choice

case $choice in
    1)
        install_elasticsearch
        install_kibana
        start_services
        ;;
    2)
        install_elasticsearch
        sudo systemctl start elasticsearch.service
        ;;
    3)
        install_kibana
        sudo systemctl start kibana.service
        ;;
    4)
        remove_elasticsearch
        remove_kibana
        ;;
    5)
        remove_elasticsearch
        ;;
    6)
        remove_kibana
        ;;
    7)
        create_user
        ;;
    8)
        delete_user
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo "Process completed."

# Set up passwords for built-in users
echo "Setting up passwords for built-in Elasticsearch users. You will be prompted to enter passwords."
sudo /usr/share/elasticsearch/bin/elasticsearch-setup-passwords interactive

# Generate an enrollment token for Kibana
echo "Generating an enrollment token for Kibana:"
sudo /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana

# Configure Kibana for network access
sudo sed -i 's/#server.host: "localhost"/server.host: "0.0.0.0"/' /etc/kibana/kibana.yml
