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
# Remove current services  
#############################################################################${nc}"
docker service rm $(docker service ls -q) 
echo -e "${green}Done....${nc}"

sleep 5

echo -e "${yellow}
# Remove original data from host
#############################################################################${nc}"
rm -R /opt/docker/volumes/mysql/*  
echo -e "${green}Done....${nc}"


echo -e "${yellow}
# Remove current secrets and configs
#############################################################################${nc}"
docker secret rm $(docker secret ls -q)
docker config rm $(docker config ls -q)
echo -e "${green}Done....${nc}"


