#this is a script to update your lighthouse client to version v3.4.0 on ubuntu 22.04
#be carefull to change the version numbers if this script is not editer over time
#sources can be found here : 
#https://github.com/sigp/lighthouse/releases
#you can dowload by just using the command :
#wget https://github.com/Infer114/eth_node/edit/main/lighthouse_update.sh
#then starting the script with :
#sh lighthouse_update.sh
#
#By Infer114 02-04-2023

#downloading the last version of lighthouse
curl -LO https://github.com/sigp/lighthouse/releases/download/v3.4.0/lighthouse-v3.4.0-x86_64-unknown-linux-gnu.tar.gz
read -p test

#stopping node services
sudo systemctl stop lighthousevalidator
read -p test
sudo systemctl stop lighthousebeacon
read -p test
sudo systemctl stop geth
read -p test
sudo systemctl stop mevboost
read -p test

#unzipping and replacing the version
tar xvf lighthouse-v3.4.0-x86_64-unknown-linux-gnu.tar.gz
read -p test
sudo cp lighthouse /usr/local/bin
read -p test

#starting all node services
sudo systemctl start geth
read -p test
sudo systemctl start lighthousebeacon
read -p test
sudo systemctl start lighthousevalidator
read -p test
sudo systemctl start mevboost
read -p test

#cleaning the download files
sudo rm lighthouse
sudo rm lighthouse-v3.4.0-x86_64-unknown-linux-gnu.tar.gz

#checking if the version is correctly installed
/usr/local/bin/lighthouse --version
read -t 10
read -p test
sudo systemctl status geth
read -t 10
read -p test
sudo journalctl -fu geth
read -t 10
read -p test
