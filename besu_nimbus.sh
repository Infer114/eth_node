
#this is a documentation to install an ETH node using besu + nimbus on ubuntu 22.04, using port 30304 for EL (take care to open it on your router TCP/UDP, besu will need it for peer discovery)
#be carefull to change the version numbers if this documentation is not edited over time
#sources can be found here : 
#https://github.com/hyperledger/besu/
#https://github.com/status-im/nimbus-eth2/releases
#you can dowload by just using the command :
#wget https://raw.githubusercontent.com/Infer114/eth_node/main/besu_nimbus.sh
#
#
#By Infer114 04-06-2023

echo "------------------------------------------"
echo "creating eth user and updating server"
echo "------------------------------------------"

#creating user eth3
adduser eth3
#granting superuser to user
usermod -aG sudo eth3

#updating the server
sudo apt update && sudo apt upgrade -y
sudo apt dist-upgrade && sudo apt autoremove

echo done

echo "------------------------------------------"
echo "installing and configuring firewall"
echo "------------------------------------------"

sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing

#adding geth port
sudo ufw allow 30304
#adding lighthouse port
sudo ufw allow 9000

#modifying the ssh port
sudo nano /etc/ssh/sshd_config
#add ssh port here
sudo systemctl restart ssh
sudo ufw allow YOURSSH/tcp
sudo ufw deny 22/tcp

#activating firewall
sudo ufw enable
sudo ufw status numbered

echo done

echo "------------------------------------------"
echo "creating JWT token"
echo "------------------------------------------"

sudo mkdir -p /var/lib/jwtsecret
openssl rand -hex 32 | sudo tee /var/lib/jwtsecret/jwt.hex
sudo chmod +r /var/lib/jwtsecret/jwt.hex

echo "------------------------------------------"
echo "installing Besu"
echo "------------------------------------------"

#check version number:
#https://github.com/hyperledger/besu/releases

cd ~
curl -LO https://hyperledger.jfrog.io/hyperledger/besu-binaries/besu/23.7.2/besu-23.7.2.tar.gz
tar xvf besu-23.7.2.tar.gz
sudo cp -a besu-23.7.2 /usr/local/bin/besu
rm besu-23.7.2.tar.gz
rm -r besu-23.7.2
sudo apt -y install openjdk-17-jre
sudo apt install -y libjemalloc-dev
sudo useradd --no-create-home --shell /bin/false besu
sudo mkdir -p /var/lib/besu
sudo chown -R besu:besu /var/lib/besu
sudo nano /etc/systemd/system/besu.service

[Unit]
Description=Besu Execution Client (Mainnet)
Wants=network-online.target
After=network-online.target
[Service]
User=besu
Group=besu
Type=simple
Restart=always
RestartSec=5
Environment="JAVA_OPTS=-Xmx5g"
ExecStart=/usr/local/bin/besu/bin/besu \
  --network=mainnet \
  --sync-mode=X_SNAP \
  --data-path=/var/lib/besu \
  --data-storage-format=BONSAI \
  --engine-jwt-secret=/var/lib/jwtsecret/jwt.hex
  --p2p-port=30304
  --nat-method=UPNPP2PONLY
[Install]
WantedBy=multi-user.target

#add your WAN ADDRESS in the service configuration file if needed with   --p2p-host=WAN_ADDRESS_HERE

sudo systemctl daemon-reload
sudo systemctl start besu
sudo systemctl status besu

sudo journalctl -fu besu

sudo systemctl enable besu

echo "------------------------------------------"
echo "installing nimbus"
echo "------------------------------------------"

#check version number:
#https://github.com/status-im/nimbus-eth2/releases

cd ~
curl -LO https://github.com/status-im/nimbus-eth2/releases/download/v23.9.0/nimbus-eth2_Linux_amd64_23.9.0_6c0d756d.tar.gz
tar xvf nimbus-eth2_Linux_amd64_23.9.0_6c0d756d.tar.gz
cd nimbus-eth2_Linux_amd64_23.9.0_6c0d756d
sudo cp build/nimbus_beacon_node /usr/local/bin

cd ~
rm nimbus-eth2_Linux_amd64_23.9.0_6c0d756d.tar.gz
rm -r nimbus-eth2_Linux_amd64_23.9.0_6c0d756d

#importer les keystore :
#Placer les fichiers ici : $HOME/staking-deposit-cli/validator_keys
sudo mkdir -p $HOME/staking-deposit-cli/validator_keys
sudo chown -R <yourusername>:<yourusername> $HOME/staking-deposit-cli/validator_keys
sudo mkdir -p /var/lib/nimbus
sudo chmod 700 /var/lib/nimbus
sudo /usr/local/bin/nimbus_beacon_node deposits import --data-dir=/var/lib/nimbus $HOME/staking-deposit-cli/validator_keys

#sync nimbus :
#https://eth-clients.github.io/checkpoint-sync-endpoints/

sudo /usr/local/bin/nimbus_beacon_node trustedNodeSync --network=mainnet --data-dir=/var/lib/nimbus --trusted-node-url=https://beaconstate.ethstaker.cc --backfill=false

sudo useradd --no-create-home --shell /bin/false nimbus
sudo chown -R nimbus:nimbus /var/lib/nimbus
sudo nano /etc/systemd/system/nimbus.service

[Unit]
Description=Nimbus Consensus Client (Mainnet)
Wants=network-online.target
After=network-online.target
[Service]
User=nimbus
Group=nimbus
Type=simple
Restart=always
RestartSec=5
ExecStart=/usr/local/bin/nimbus_beacon_node \
  --network=mainnet \
  --data-dir=/var/lib/nimbus \
  --web3-url=http://127.0.0.1:8551 \
  --jwt-secret=/var/lib/jwtsecret/jwt.hex \
  --suggested-fee-recipient=0x0000000YOUR_OWN_ADRESS_HERE0000000000000 \
  --graffiti="<yourgraffiti>"
[Install]
WantedBy=multi-user.target

sudo systemctl daemon-reload
sudo systemctl start nimbus
sudo systemctl status nimbus
sudo journalctl -fu nimbus
sudo systemctl enable nimbus






#Updating Besu
#https://github.com/hyperledger/besu/releases

cd ~
curl -LO https://hyperledger.jfrog.io/hyperledger/besu-binaries/besu/23.1.1/besu-23.1.1.tar.gz

#As of 23.1.0 Besu requires Java 17 to run. Use $ java -version to determine the version you have installed. If it is not 17 or greater, then run the following command 
#sudo apt -y install openjdk-17-jre to install Java 17 
#before updating.

sudo systemctl stop besu
tar xvf besu-23.1.1.tar.gz
sudo rm -r /usr/local/bin/besu
sudo cp -a besu-23.1.1 /usr/local/bin/besu

sudo systemctl start besu
sudo systemctl status besu
sudo journalctl -fu besu
sudo journalctl -fu nimbus

cd ~
rm besu-23.1.1.tar.gz
rm -r besu-23.1.1






#Updating Nimbus
cd ~
curl -LO https://github.com/status-im/nimbus-eth2/releases/download/v22.10.1/nimbus-eth2_Linux_amd64_22.10.1_97a1cdc4.tar.gz
sudo systemctl stop nimbus
tar xvf nimbus-eth2_Linux_amd64_22.10.1_97a1cdc4.tar.gz
cd nimbus-eth2_Linux_amd64_22.10.1_97a1cdc4
sudo cp build/nimbus_beacon_node /usr/local/bin

sudo systemctl start nimbus
sudo systemctl status nimbus
sudo journalctl -fu nimbus

cd ~
rm nimbus-eth2_Linux_amd64_22.10.1_97a1cdc4.tar.gz
rm -r nimbus-eth2_Linux_amd64_22.10.1_97a1cdc4
