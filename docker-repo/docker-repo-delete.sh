#!/bin/bash


RED='\033[0;31m'  # Red colored text
NC='\033[0m'      # Normal text
YELLOW='\033[33m'  # Yellow Color
GREEN='\033[32m'   # Green Color


# Revert SSL Certificates and Root CA Certificate
echo -e "\n${YELLOW}Reverting SSL Certificates and Root CA Certificate...${NC}"

sudo rm -rf /etc/letsencrypt/live/saranya4.mnsp.co.in

sudo rm -rf /etc/docker/certs.d/saranya4.mnsp.co.in/
sudo rm -rf /usr/share/ca-certificates/extra/rootCA.crt

# Reconfigure CA Certificates
sudo dpkg-reconfigure ca-certificates

# Remove Docker Compose Services
echo -e "\n${YELLOW}Removing Docker Compose Services...${NC}"
docker-compose down

# Remove Docker Images
echo -e "\n${YELLOW}Removing Docker Images...${NC}"
sudo rmi -f $(sudo docker images -aq)
docker rmi saranya4.mnsp.co.in/php:v2
docker rmi php:latest

# Stop and Disable Docker
echo -e "\n${YELLOW}Stopping and Disabling Docker...${NC}"
sudo systemctl stop docker
sudo systemctl disable docker

# Remove Docker and Docker Compose
echo -e "\n${YELLOW}Removing Docker and Docker Compose...${NC}"
sudo apt-get purge docker.io docker-compose

# Remove Nginx
echo -e "\n${YELLOW}Removing Nginx...${NC}"
sudo systemctl stop nginx
sudo apt-get purge nginx* -y
sudo apt-get autoremove -y
sudo rm -rf /etc/nginx

# Remove Certbot
echo -e "\n${YELLOW}Removing Certbot...${NC}"
sudo apt-get purge certbot python3-certbot-nginx

# Remove Created Directories
echo -e "\n${YELLOW}Removing Created Directories...${NC}"
sudo rm -rf registry/

echo -e "\n${GREEN}Reversion and Uninstallation completed successfully.${NC}"
