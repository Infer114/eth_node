#this is a documentation to install an ETH testnet node using geth + lighthouse on ubuntu 22.04
#be carefull to change the version numbers if this documentation is not edited over time
#sources can be found here : 
#https://github.com/sigp/lighthouse/releases
#you can dowload by just using the command :
#wget https://raw.githubusercontent.com/Infer114/eth_node/main/goerli_prater_install.sh
#
#
#By Infer114 04-06-2023

echo "------------------------------------------"
echo "updating server"
echo "------------------------------------------"

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
#adding default ssh port
sudo ufw allow 22/tcp

#activating firewall
sudo ufw enable

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
ExecStart=geth --goerli --http --datadir /var/lib/goethereum --authrpc.jwtsecret /var/lib/jwtsecret/jwt.hex
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
#for using user testnet to import :
#sudo chown -R testnet:testnet /var/lib/lighthouse
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
ExecStart=/usr/local/bin/lighthouse bn --network prater --datadir /var/lib/lighthouse --staking --execution-endpoint http://127.0.0.1:8551 --execution-jwt /var/lib/jwtsecret/jwt.hex
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
ExecStart=/usr/local/bin/lighthouse vc --network prater --datadir /var/lib/lighthouse --suggested-fee-recipient 0x0000000000000000000000000000000000000000
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start lighthousevalidator
sudo systemctl enable lighthousevalidator

echo done


echo "------------------------------------------"
echo "Script done"
echo "------------------------------------------"
