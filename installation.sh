#this is a script to install an ETH node using geth + lighthouse on ubuntu 22.04
#be carefull to change the version numbers if this script is not edited over time
#sources can be found here : 
#https://github.com/sigp/lighthouse/releases
#you can dowload by just using the command :
#wget https://raw.githubusercontent.com/Infer114/eth_node/main/installation.sh
#then starting the script with :
#sh installation.sh
#
#By Infer114 02-25-2023

echo "------------------------------------------"
echo "creating eth1 user and updating server"
echo "------------------------------------------"

#creating user eth1
adduser eth1
#granting superuser to user
usermod -aG sudo eth1

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
sudo ufw allow 30303
#adding lighthouse port
sudo ufw allow 9000

#modifying the ssh port
#sudo nano /etc/ssh/sshd_config
#sudo systemctl restart ssh
#sudo ufw allow SSHPORT /tcp
#sudo ufw deny 22/tcp

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
echo "installing geth"
echo "------------------------------------------"

sudo add-apt-repository -y ppa:ethereum/ethereum
sudo apt update
sudo apt install geth

sudo useradd --no-create-home --shell /bin/false goeth
sudo mkdir -p /var/lib/goethereum
sudo chown -R goeth:goeth /var/lib/goethereum

echo done

echo "------------------------------------------"
echo "creating geth service"
echo "------------------------------------------"

cat <<EOF >/etc/systemd/system/geth.service

[Unit]
Description=Go Ethereum Client
After=network.target
Wants=network.target

[Service]
User=goeth
Group=goeth
Type=simple
Restart=always
RestartSec=5
ExecStart=geth --http --datadir /var/lib/goethereum --authrpc.jwtsecret /var/lib/jwtsecret/jwt.hex

[Install]
WantedBy=default.target
EOF

sudo systemctl daemon-reload
sudo systemctl start geth
sudo systemctl enable geth

echo done

echo "------------------------------------------"
echo "installating lighthouse"
echo "------------------------------------------"

sudo apt install curl
curl -LO https://github.com/sigp/lighthouse/releases/download/v3.5.0/lighthouse-v3.5.0-x86_64-unknown-linux-gnu.tar.gz

tar xvf lighthouse-v3.5.0-x86_64-unknown-linux-gnu.tar.gz
sudo cp lighthouse /usr/local/bin
sudo rm lighthouse
sudo rm lighthouse-v3.5.0-x86_64-unknown-linux-gnu.tar.gz

echo done

echo "------------------------------------------"
echo "importing validators"
echo "------------------------------------------"

sudo mkdir -p /var/lib/lighthouse
sudo chown -R eth1:eth1 /var/lib/lighthouse
#add validators here (will create /var/lib/lighthouse/validators)
#/usr/local/bin/lighthouse --network mainnet account validator import --directory $HOME/eth2deposit-cli/validator_keys --datadir /var/lib/lighthouse
sudo chown -R root:root /var/lib/lighthouse

echo done

echo "------------------------------------------"
echo "creating lighthouse beacon service"
echo "------------------------------------------"

sudo useradd --no-create-home --shell /bin/false lighthousebeacon
sudo mkdir -p /var/lib/lighthouse/beacon
sudo chown -R lighthousebeacon:lighthousebeacon /var/lib/lighthouse/beacon
sudo chmod 700 /var/lib/lighthouse/beacon

cat <<EOF >/etc/systemd/system/lighthousebeacon.service
[Unit]
Description=Lighthouse Eth2 Client Beacon Node
Wants=network-online.target
After=network-online.target

[Service]
User=lighthousebeacon
Group=lighthousebeacon
Type=simple
Restart=always
RestartSec=5
ExecStart=/usr/local/bin/lighthouse bn --network mainnet --datadir /var/lib/lighthouse --staking --execution-endpoint http://127.0.0.1:8551 --execution-jwt /var/lib/jwtsecret/jwt.hex --builder-profit-threshold 250000000000000000

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start lighthousebeacon
sudo systemctl enable lighthousebeacon

echo done

echo "------------------------------------------"
echo "creating validator service"
echo "------------------------------------------"

sudo useradd --no-create-home --shell /bin/false lighthousevalidator
#you must allready have imported keys here
sudo chown -R lighthousevalidator:lighthousevalidator /var/lib/lighthouse/validators
sudo chmod 700 /var/lib/lighthouse/validators

cat <<EOF >/etc/systemd/system/lighthousevalidator.service
[Unit]
Description=Lighthouse Eth2 Client Validator Node
Wants=network-online.target
After=network-online.target

[Service]
User=lighthousevalidator
Group=lighthousevalidator
Type=simple
Restart=always
RestartSec=5
ExecStart=/usr/local/bin/lighthouse vc --network mainnet --datadir /var/lib/lighthouse --suggested-fee-recipient 0x0ETH_ADRESSE_HERE --graffiti "<yourgraffiti>" --builder-proposals

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start lighthousevalidator
sudo systemctl enable lighthousevalidator

echo done

echo "------------------------------------------"
echo "installing MEV boost"
echo "------------------------------------------"

sudo useradd --no-create-home --shell /bin/false mevboost
cd ~
wget https://github.com/flashbots/mev-boost/releases/download/v1.4.0/mev-boost_1.4.0_linux_amd64.tar.gz
#sha256sum mev-boost_1.4.0_linux_amd64.tar.gz
tar xvf mev-boost_1.4.0_linux_amd64.tar.gz
sudo cp mev-boost /usr/local/bin
rm mev-boost LICENSE README.md mev-boost_1.4.0_linux_amd64.tar.gz
sudo chown mevboost:mevboost /usr/local/bin/mev-boost

echo done

echo "------------------------------------------"
echo "creating mev-boost service"
echo "------------------------------------------"

cat <<EOF >/etc/systemd/system/mevboost.service
[Unit]
Description=mev-boost (Mainnet)
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=mevboost
Group=mevboost
Restart=always
RestartSec=5
ExecStart=mev-boost \
    -mainnet \
    -relay-check \
    -relays https://0x8b5d2e73e2a3a55c6c87b8b6eb92e0149a125c852751db1422fa951e42a09b82c142c3ea98d0d9930b056a3bc9896b8f@bloxroute.max-profit.blxrbdn.com

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start mevboost
sudo systemctl enable mevboost

echo done

echo "------------------------------------------"
echo "Script done"
echo "------------------------------------------"
