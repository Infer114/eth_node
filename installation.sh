#working on it, do not use

#creating user eth1
adduser eth1
#granting superuser priviliges to this user
usermod -aG sudo eth1

#updating the server
sudo apt update && sudo apt upgrade -y
sudo apt dist-upgrade && sudo apt autoremove

#configuring firewall
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

sudo ufw enable
sudo ufw status numbered

#creating JWT token
sudo mkdir -p /var/lib/jwtsecret
openssl rand -hex 32 | sudo tee /var/lib/ethereum/jwttoken

#installing geth
sudo add-apt-repository -y ppa:ethereum/ethereum
sudo apt update
sudo apt install geth

sudo useradd --no-create-home --shell /bin/false goeth
sudo mkdir -p /var/lib/goethereum
sudo chown -R goeth:goeth /var/lib/goethereum

#creating geth service
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

#installating lighthouse
sudo apt install curl
curl -LO https://github.com/sigp/lighthouse/releases/download/v3.5.0/lighthouse-v3.5.0-x86_64-unknown-linux-gnu.tar.gz

tar xvf lighthouse-v3.5.0-x86_64-unknown-linux-gnu.tar.gz
sudo cp lighthouse /usr/local/bin
sudo rm lighthouse
sudo rm lighthouse-v3.5.0-x86_64-unknown-linux-gnu.tar.gz

#importing validators
sudo mkdir -p /var/lib/lighthouse
sudo chown -R eth1:eth1 /var/lib/lighthouse
#add validators here (will create /var/lib/lighthouse/validators)
#/usr/local/bin/lighthouse --network mainnet account validator import --directory $HOME/eth2deposit-cli/validator_keys --datadir /var/lib/lighthouse
sudo chown -R root:root /var/lib/lighthouse

#creating lighthouse service 
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

#creating validator service
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

#installing MEV boost
sudo useradd --no-create-home --shell /bin/false mevboost
cd ~
wget https://github.com/flashbots/mev-boost/releases/download/v1.4.0/mev-boost_1.4.0_linux_amd64.tar.gz
#sha256sum mev-boost_1.4.0_linux_amd64.tar.gz
tar xvf mev-boost_1.4.0_linux_amd64.tar.gz
sudo cp mev-boost /usr/local/bin
rm mev-boost LICENSE README.md mev-boost_1.4.0_linux_amd64.tar.gz
sudo chown mevboost:mevboost /usr/local/bin/mev-boost

#creating mev-boost service
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
