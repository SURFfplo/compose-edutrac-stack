#!/bin/bash

#############################################################################
# COLOURS AND MARKUP
#############################################################################

red='\033[0;31m'            # Red
green='\033[0;49;92m'       # Green
yellow='\033[0;49;93m'      # Yellow
white='\033[1;37m'          # White
grey='\033[1;49;30m'        # Grey
nc='\033[0m'                # No color

clear

echo -e "${yellow}
# Test if machine is running in swarm if not start it 
#############################################################################${nc}"
if docker node ls > /dev/null 2>&1; then
  echo already running in swarm mode 
else
  docker swarm init 
  echo docker was a standalone node now running in swarm 
fi


echo -e "${yellow}
# Create secrets for db use 
#############################################################################${nc}"
echo -e "${green}Choose new database root password: ${nc}"
read dbrootpwd
printf $dbrootpwd | docker secret create db_root_password -
echo -e "${green}Done....${nc}"

echo -e "${green}Choose new database dba password: ${nc}"
read dbdbapwd
printf $dbdbapwd | docker secret create db_dba_password -
echo -e "${green}Done....${nc}"


echo -e "${yellow}
# Build first container 
#############################################################################${nc}"
cd /var/docker/edutrac/image-sis-edutrac
docker build . -t etsis-apache-php
echo -e "${green}Done....${nc}"


echo -e "${yellow}
# Build second container 
#############################################################################${nc}"
cd /var/docker/edutrac/image-base-mysql 
docker pull mysql:5.7
echo -e "${green}Done....${nc}"


echo -e "${yellow}
# Create config for mysql container 
#############################################################################${nc}"
cd /var/docker/edutrac/compose-sis-stack
docker config create my_cnf /var/docker/edutrac/compose-sis-stack/config_mysql/my.cnf 
echo -e "${green}Done....${nc}"


echo -e "${yellow}
# Remove original files from host and clone files from SURFfplo 
#############################################################################${nc}"
cd /var/docker/edutrac/compose-sis-stack
# remove old public_hhtml
rm -r public_html
git clone https://github.com/SURFfplo/eduTrac-SIS.git public_html
#git clone https://github.com/parkerj/eduTrac-SIS.git public_html
#cp ./config_etsis/* ./public_html/
echo -e "${green}Done....${nc}"

echo -e "${yellow}
# Create the service
#############################################################################${nc}"
cd /var/docker/edutrac/compose-sis-stack
docker stack deploy -c docker-compose.yml apps
echo -e "${green}Done....${nc}"

clear

echo "woit for 15 seconds for containers to fully come up" 
sleep 30

echo -e "${yellow}
# Initialize etis container
#############################################################################${nc}"
containerid="$(docker container ps -q -f 'name=etsis')"
echo $containerid
docker exec -i -w /var/www/html "$(docker container ps -q -f 'name=etsis')" chmod 755 config.php
docker exec -i -w /var/www/html "$(docker container ps -q -f 'name=etsis')" chmod 755 phinx.php
docker exec -i "$(docker container ps -q -f 'name=etsis')" chown -R apache:apache /var/www/html
docker exec -i -w /var/www/html "$(docker container ps -q -f 'name=etsis')" ./etsis core migrate
# ./fillcontainer.sh
echo -e "${green}Done....${nc}"

