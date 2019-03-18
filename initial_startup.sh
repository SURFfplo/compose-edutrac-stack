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
echo -e "${green}Done....${nc}"



echo -e "${yellow}
# Test if network is running in overlay if not start it
#############################################################################${nc}"
docker network ls|grep appnet > /dev/null || docker network create --driver overlay appnet
sleep 5
echo -e "${green}Done....${nc}"


echo -e "${yellow}
# Create secrets for db use 
#############################################################################${nc}"
echo -e "${green}Choose new database root password: ${nc}"
read dbrootpwd
printf $dbrootpwd | docker secret create edutrac_db_root_password -
echo -e "${green}Done....${nc}"

echo -e "${green}Choose new database dba password: ${nc}"
read dbdbapwd
printf $dbdbapwd | docker secret create edutrac_db_dba_password -
echo -e "${green}Done....${nc}"


echo -e "${yellow}
# Check if sis containter is available and build if needed
#############################################################################${nc}"
DIRECTORY='image-edutrac-sis'
if [ ! -d ../"$DIRECTORY" ]; then
  echo "  https://github.com/SURFfplo/"$DIRECTORY".git ../"$DIRECTORY" "
  git clone https://github.com/SURFfplo/"$DIRECTORY".git ../"$DIRECTORY"
fi
docker-compose build etsis
echo -e "${green}Done....${nc}"



echo -e "${yellow}
# Build second container 
#############################################################################${nc}"
docker-compose build db
echo -e "${green}Done....${nc}"


echo -e "${yellow}
# Create config for mysql container 
#############################################################################${nc}"
docker config create my_cnf config_mysql/my.cnf 
echo -e "${green}Done....${nc}"


echo -e "${yellow}
# Create folder structure for mysql container
#############################################################################${nc}"
mkdir .data
mkdir .data/mysql 
echo -e "${green}Done....${nc}"


echo -e "${yellow}
# Remove original files from host and clone files from SURFfplo 
#############################################################################${nc}"
cd ../"$DIRECTORY"
# remove old public_hhtml
rm -r public_html
git clone https://github.com/SURFfplo/eduTrac-SIS.git public_html
#git clone https://github.com/parkerj/eduTrac-SIS.git public_html
#cp ./config_etsis/* ./public_html/
echo -e "${green}Done....${nc}"

echo -e "${yellow}
# Create the service
#############################################################################${nc}"
cd ../compose-sis-stack
docker stack deploy -c docker-compose.yml apps
echo -e "${green}Done....${nc}"

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

