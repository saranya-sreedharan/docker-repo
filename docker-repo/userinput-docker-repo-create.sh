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


echo -e "${YELLOW}...Installing Certbot and its Nginx plugin${NC}"
if ! sudo apt install -y certbot python3-certbot-nginx; then 
    echo -e "${RED}Package installation failed.${NC}"
    echo -e "${RED}Please check the error message above for more details.${NC}"
    exit 1
fi

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

echo -e "${YELLOW}Creating directories...${NC}"

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

# Create the 'conf.d' directory
mkdir conf.d
if [ $? -eq 0 ]; then
    echo -e "${GREEN}'conf.d' directory created.${NC}"
else
    echo -e "${RED}Failed to create 'conf.d' directory.${NC}"
    exit 1
fi

# Create the 'ssl' directory
mkdir ssl
if [ $? -eq 0 ]; then
    echo -e "${GREEN}'ssl' directory created.${NC}"
else
    echo -e "${RED}Failed to create 'ssl' directory.${NC}"
    exit 1
fi

cd .. || exit 1

echo -e "${YELLOW}Creating docker-compose.yml...${NC}"

# Create docker-compose.yml using nano
cat <<EOL > docker-compose.yml
version: '3'
services:
#Registry
  registry:
    image: registry:2
    restart: always
    ports:
    - "5000:5000"
    environment:
      REGISTRY_AUTH: htpasswd
      REGISTRY_AUTH_HTPASSWD_REALM: Registry-Realm
      REGISTRY_AUTH_HTPASSWD_PATH: /auth/registry.passwd
      REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY: /data
    volumes:
      - registrydata:/data
      - ./auth:/auth
    networks:
      - mynet
#Nginx Service
  nginx:
    image: nginx:alpine
    container_name: nginx
    restart: unless-stopped
    tty: true
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf.d/:/etc/nginx/conf.d/
      - ./nginx/ssl/:/etc/nginx/ssl/
    networks:
      - mynet
#Docker Networks
networks:
  mynet:
    driver: bridge
#Volumes
volumes:
  registrydata:
    driver: local
EOL

if [ $? -eq 0 ]; then
    echo -e "${GREEN}docker-compose.yml created successfully.${NC}"
else
    echo -e "${RED}Failed to create docker-compose.yml.${NC}"
    exit 1
fi

cd nginx/conf.d/


echo -e "${YELLOW}Creating registry.conf...${NC}"

# Create registry.conf using nano
cat <<EOL > registry.conf
upstream docker-registry {
    server registry:5000;
}
server {
    listen 80;
    server_name \$domain_name;
    return 301 https://\$domain_name\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name \$domain_name;
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    # Log files for Debug
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    location / {
        # Do not allow connections from docker 1.5 and earlier
        # docker pre-1.6.0 did not properly set the user agent on ping, catch "Go *" user agents
        if (\$http_user_agent ~ "^(docker/1.(3|4|5(?![0-9]-dev))|Go ).*$" )  {
            return 404;
        }
        proxy_pass                          http://docker-registry;
        proxy_set_header  Host              \$http_host;
        proxy_set_header  X-Real-IP         \$remote_addr;
        proxy_set_header  X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header  X-Forwarded-Proto \$scheme;
        proxy_read_timeout                  900;
    }
}
EOL

if [ $? -eq 0 ]; then
    echo -e "${GREEN}registry.conf created successfully.${NC}"
else
    echo -e "${RED}Failed to create registry.conf.${NC}"
    exit 1
fi


echo -e "${YELLOW}Creating additional volume ...${NC}"

# Create additional.conf using nano
cat <<EOL > additional.conf
client_max_body_size 2G;
EOL

if [ $? -eq 0 ]; then
    echo -e "${GREEN}additional.conf created successfully.${NC}"
else
    echo -e "${RED}Failed to create additional.conf.${NC}"
    exit 1
fi

cd .. || exit 1

#echo -e "${YELLOW}...the ssl files are copying...${NC}"
#sudo cp /etc/letsencrypt/live/$domain_name/fullchain.pem ssl/
#sudo cp /etc/letsencrypt/live/$domain_name/privkey.pem ssl/


echo -e "${YELLOW}...the ssl files are copying...${NC}"

# Copy SSL files
sudo cp /etc/letsencrypt/live/$domain_name/fullchain.pem ssl/ || {
    echo -e "${RED}Failed to copy fullchain.pem.${NC}"
    exit 1
}

sudo cp /etc/letsencrypt/live/$domain_name/privkey.pem ssl/ || {
    echo -e "${RED}Failed to copy privkey.pem.${NC}"
    exit 1
}

#cd registry/auth
cd .. || exit 1
cd auth

#sudo apt install apache2-utils
#htpasswd -Bc registry.passwd admin

echo -e "${YELLOW}...installing apache2-utils...${NC}"
sudo apt install -y apache2-utils || {
    echo -e "${RED}Failed to install apache2-utils.${NC}"
    exit 1
}

echo -e "${YELLOW}...creating registry.passwd file...${NC}"
htpasswd -Bc registry.passwd admin || {
    echo -e "${RED}Failed to create registry.passwd file.${NC}"
    exit 1
}

cd .. || exit 1

# Create rootCA.crt
sudo openssl x509 -in /etc/letsencrypt/live/$domain_name/fullchain.pem -inform PEM -out rootCA.crt
if [ $? -eq 0 ]; then
    echo -e "${GREEN}rootCA.crt created successfully.${NC}"
else
    echo -e "${RED}Failed to create rootCA.crt.${NC}"
    exit 1
fi

echo -e "${YELLOW}Copying rootCA.crt to Docker certificates directory...${NC}"

# Copy rootCA.crt to Docker certificates directory
sudo mkdir -p /etc/docker/certs.d/$domain_name/
sudo cp rootCA.crt /etc/docker/certs.d/$domain_name/
if [ $? -eq 0 ]; then
    echo -e "${GREEN}rootCA.crt copied to Docker certificates directory.${NC}"
else
    echo -e "${RED}Failed to copy rootCA.crt to Docker certificates directory.${NC}"
    exit 1
fi

echo -e "${YELLOW}Copying rootCA.crt to extra CA certificates directory...${NC}"

# Copy rootCA.crt to extra CA certificates directory
sudo mkdir -p /usr/share/ca-certificates/extra/
sudo cp rootCA.crt /usr/share/ca-certificates/extra/
if [ $? -eq 0 ]; then
    echo -e "${GREEN}rootCA.crt copied to extra CA certificates directory.${NC}"
else
    echo -e "${RED}Failed to copy rootCA.crt to extra CA certificates directory.${NC}"
    exit 1
fi

echo -e "${YELLOW}Reconfiguring CA certificates...${NC}"

# Reconfigure CA certificates
sudo dpkg-reconfigure ca-certificates
if [ $? -eq 0 ]; then
    echo -e "${GREEN}CA certificates reconfigured successfully.${NC}"
else
    echo -e "${RED}Failed to reconfigure CA certificates.${NC}"
    exit 1
fi

echo -e "${YELLOW}Restarting Docker service...${NC}"

# Restart Docker service
sudo systemctl restart docker
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Docker service restarted successfully.${NC}"
else
    echo -e "${RED}Failed to restart Docker service.${NC}"
    exit 1
fi


 echo -e "${YELLOW}...checking the nginx is up then stoping that...${NC}"
if sudo systemctl is-active --quiet nginx; then
    echo "Nginx is running. Stopping Nginx..."
    sudo systemctl stop nginx
    echo "Nginx stopped successfully."
else
    echo "Nginx is not running."
fi



echo -e "${YELLOW}Starting Docker Compose...${NC}"

# Start Docker Compose

sudo usermod -aG docker $USER

echo -e "${YELLOW}...the docker compose starting...${NC}"

sudo docker-compose up -d
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Docker Compose started successfully.${NC}"
else
    echo -e "${RED}Failed to start Docker Compose.${NC}"
    exit 1
fi


echo -e "${YELLOW}Checking Docker Compose status...${NC}"

# Check Docker Compose status
sudo docker-compose ps
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Docker Compose is running.${NC}"
else
    echo -e "${RED}Docker Compose is not running.${NC}"
    exit 1
fi

echo -e "${YELLOW}Pulling PHP image...${NC}"

# Pull PHP image
sudo docker pull php
if [ $? -eq 0 ]; then
    echo -e "${GREEN}PHP image pulled successfully.${NC}"
else
    echo -e "${RED}Failed to pull PHP image.${NC}"
    exit 1
fi

echo -e "${YELLOW}Tagging the PHP image...${NC}"

# Tag the PHP image
sudo docker images
sudo docker tag php:latest $domain_name/php:v2
if [ $? -eq 0 ]; then
    echo -e "${GREEN}PHP image tagged successfully.${NC}"
else
    echo -e "${RED}Failed to tag PHP image.${NC}"
    exit 1
fi

echo -e "${YELLOW}Logging in to the private registry...${NC}"

# Log in to the private registry
sudo docker login https://$domain_name
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Logged in to the private registry.${NC}"
else
    echo -e "${RED}Failed to log in to the private registry.${NC}"
    exit 1
fi

echo -e "${YELLOW}Pushing the tagged PHP image to the private registry...${NC}"

#tag the image with private repo
sudo docker tag php:latest $domain_name/php:v2

# Push the tagged PHP image to the private registry
sudo docker push $domain_name/php:v2
if [ $? -eq 0 ]; then
    echo -e "${GREEN}PHP image pushed to the private registry successfully.${NC}"
else
    echo -e "${RED}Failed to push PHP image to the private registry.${NC}"
    exit 1
fi


