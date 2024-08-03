#!/bin/bash

#This script is used to setup a private docker repository using nginx in a ubuntu 20.04.
#This tutorial taken from "https://phoenixnap.com/kb/set-up-a-private-docker-registry"

RED='\033[0;31m'  # Red colored text
NC='\033[0m'      # Normal text
YELLOW='\033[33m'  # Yellow Color
GREEN='\033[32m'   # Green Color

echo "Enter the Domain_name:"
read -r domain_name


echo -e "${YELLOW}... updating packages${NC}"
# Update package information
if ! sudo apt update; then
    echo -e "${RED}The system update failed.${NC}"
    exit 1
fi


echo -e "${YELLOW}...verifying nginx installation${NC}"
# Check if Nginx is installed
if [ -x "$(command -v nginx)" ]; then
    echo -e "${GREEN}Nginx is already installed.${NC}"
else
    # Install Nginx
    echo -e "${YELLOW}Installing Nginx...${NC}"
    sudo apt-get install -y nginx
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Nginx Successfully installed.${NC}"
    else
        echo -e "${RED}Nginx Failed to install.${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}...checking nginx is installed or not${NC}"
# Check if Nginx is running
if sudo systemctl is-active --quiet nginx; then
    echo "${GREEN}Nginx is running.${NC}"
else
    # Start and enable Nginx
    echo "${YELLOW}Starting and enabling Nginx...${NC}"
    sudo systemctl start nginx
    sudo systemctl enable nginx
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Nginx up and running.${NC}"
    else
        echo -e "${RED}Nginx Failed to start nginx.${NC}"
        exit 1
    fi
fi


ip_service="ifconfig.me/ip"  # or "ipecho.net/plain"

public_ip=$(curl -sS "$ip_service")

response=$(curl -IsS --max-time 5 "http://$public_ip" | head -n 1)

if [[ "$response" == *"200 OK"* ]]; then
  echo -e "${GREEN}Website is reachable.${NC}"
else
  echo -e "${RED}Website is not reachable or returned a non-OK status.${NC}"
fi

echo -e "${GREEN}Script executed successfully for installing nginx.${NC}"

echo -e "${YELLOW}...docker installation and setup.....${NC}"
# Check if Docker is installed
if [ -x "$(command -v docker)" ]; then
    echo "${GREEN}Docker is already installed.${NC}"
else
    # Install Docker
    echo -e "${YELLOW}Installing Docker...${NC}"
    sudo apt-get update
    sudo apt-get install -y docker.io
    if ! [ -x "$(command -v docker)" ]; then
        echo -e "${RED}Docker installation failed.${NC}"
        exit 1
    else
        echo "${GREEN}Docker is successfully installed.${NC}"
    fi
fi

echo -e "${YELLOW}...checking the docker is running successfully or not...${NC}"

# Check if Docker is running
if sudo systemctl is-active --quiet docker; then
    echo "${GREEN}Docker is running.${NC}"
else
    # Start Docker
    echo "${YELLOW}Starting Docker...${NC}"
    sudo systemctl start docker
    sudo systemctl enable docker
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Docker Successfully started.${NC}"
    else
        echo -e "${RED}Docker Failed to start.${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}...configuring the docker daemon.json...${NC}"
# Configure Docker daemon
if ! sudo bash -c "cat <<EOL > /etc/docker/daemon.json
{
  \"insecure-registries\": [\"$domain_name\"]
}
EOL"; then
    echo -e "${RED}The Docker daemon configuration failed.${NC}"
    exit 1
fi

echo -e "${YELLOW}...restarting the docker...${NC}"
# Restart Docker
if ! sudo systemctl restart docker; then
    echo -e "${RED}Failed to restart Docker after modifying the daemon.json.${NC}"
    exit 1
fi

sudo apt install python3-certbot-nginx

sudo certbot certonly --nginx

#Congratulations! Your certificate and chain have been saved at:
#   /etc/letsencrypt/live/saranya8.mnsp.co.in/fullchain.pem
 #  Your key file has been saved at:
 #  /etc/letsencrypt/live/saranya8.mnsp.co.in/privkey.pem

 echo -e "${YELLOW}...updating the system...${NC}"
if ! sudo apt update; then
  echo -e "${RED}System update failed.${NC}"
  exit 1
fi


echo -e "${YELLOW}...installing the docker-compose...${NC}"
if ! sudo apt install -y docker-compose; then 
  echo -e "${RED}Failed to install Docker Compose.${NC}"
  exit 1
else
  echo -e "${GREEN}Docker Compose successfully installed.${NC}"
fi

# Create the 'registry' directory
mkdir -p registry
if [ $? -eq 0 ]; then
    echo -e "${GREEN}'registry' directory created.${NC}"
else
    echo -e "${RED}Failed to create 'registry' directory.${NC}"
    exit 1
fi

# Move into the 'registry' directory
cd registry
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to navigate to 'registry' directory.${NC}"
    exit 1
fi

# Create the 'auth' directory
mkdir auth
if [ $? -eq 0 ]; then
    echo -e "${GREEN}'auth' directory created.${NC}"
else
    echo -e "${RED}Failed to create 'auth' directory.${NC}"
    exit 1
fi

# Create the 'nginx' directory
mkdir nginx
if [ $? -eq 0 ]; then
    echo -e "${GREEN}'nginx' directory created.${NC}"
else
    echo -e "${RED}Failed to create 'nginx' directory.${NC}"
    exit 1
fi

# Move into the 'nginx' directory
cd nginx
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to navigate to 'nginx' directory.${NC}"
    exit 1
fi

