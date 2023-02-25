#this is a script to update your lighthouse client to version v3.4.0 on ubuntu 22.04
#be carefull to change the version numbers if this script is not edited over time
#sources can be found here : 
#https://github.com/sigp/lighthouse/releases
#you can dowload by just using the command :
#wget https://raw.githubusercontent.com/Infer114/eth_node/main/lighthouse_update.sh
#then starting the script with :
#sh lighthouse_update.sh
#
#By Infer114 02-04-2023

echo "------------------------------------------"
echo "downloading the last version of lighthouse"
echo "------------------------------------------"
echo
curl -LO https://github.com/sigp/lighthouse/releases/download/v3.5.0/lighthouse-v3.5.0-x86_64-unknown-linux-gnu.tar.gz
echo

echo "------------------------------------------"
echo "stopping node services"
echo "------------------------------------------"
echo
sudo systemctl stop lighthousevalidator
sudo systemctl stop lighthousebeacon
sudo systemctl stop geth
sudo systemctl stop mevboost
sleep 30
echo

echo "------------------------------------------"
echo "unzipping and replacing the version"
echo "------------------------------------------"
echo
tar xvf lighthouse-v3.5.0-x86_64-unknown-linux-gnu.tar.gz
sudo cp lighthouse /usr/local/bin
echo

echo "------------------------------------------"
echo "starting all node services"
echo "------------------------------------------"
echo
sudo systemctl start geth
sudo systemctl start lighthousebeacon
sudo systemctl start lighthousevalidator
sudo systemctl start mevboost
echo

echo "------------------------------------------"
echo "cleaning the download files"
echo "------------------------------------------"
echo
sudo rm lighthouse
sudo rm lighthouse-v3.5.0-x86_64-unknown-linux-gnu.tar.gz
echo

echo "------------------------------------------"
echo "checking if the version is correctly installed"
echo "------------------------------------------"
echo
/usr/local/bin/lighthouse --version
