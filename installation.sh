#creating user eth1
adduser eth1
#granting superuser priviliges to this user
usermod -aG sudo eth1

#updating the server
sudo apt update && sudo apt upgrade -y
sudo apt dist-upgrade && sudo apt autoremove

#modifying the ssh port
sudo nano /etc/ssh/sshd_config
sudo systemctl restart ssh

#configuring firewall
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
#sudo ufw allow SSHPORT /tcp
sudo ufw deny 22/tcp
#adding geth port
sudo ufw allow 30303
#adding lighthouse port
sudo ufw allow 9000
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

sudo nano /etc/systemd/system/geth.service

#ajouter service

sudo systemctl daemon-reload
sudo systemctl start geth
sudo systemctl enable geth

#installation lighthouse
sudo apt install curl
curl -LO https://github.com/sigp/lighthouse/releases/download/v3.4.0/lighthouse-v3.4.0-x86_64-unknown-linux-gnu.tar.gz

tar xvf lighthouse-v3.4.0-x86_64-unknown-linux-gnu.tar.gz
sudo cp lighthouse /usr/local/bin
sudo rm lighthouse
sudo rm lighthouse-v3.4.0-x86_64-unknown-linux-gnu.tar.gz

sudo mkdir -p /var/lib/lighthouse
sudo chown -R eth1:eth1 /var/lib/lighthouse
#ajout des validateurs ici (créé /var/lib/lighthouse/validators
sudo chown -R root:root /var/lib/lighthouse

sudo useradd --no-create-home --shell /bin/false lighthousebeacon
sudo mkdir -p /var/lib/lighthouse/beacon
sudo chown -R lighthousebeacon:lighthousebeacon /var/lib/lighthouse/beacon
sudo chmod 700 /var/lib/lighthouse/beacon

#creation service lighthouse
sudo nano /etc/systemd/system/lighthousebeacon.service
#service ici

sudo systemctl daemon-reload
sudo systemctl start lighthousebeacon
sudo systemctl enable lighthousebeacon

#config validator service
sudo useradd --no-create-home --shell /bin/false lighthousevalidator
#besoin d'avoir importé les clés
sudo chown -R lighthousevalidator:lighthousevalidator /var/lib/lighthouse/validators
sudo chmod 700 /var/lib/lighthouse/validators

sudo nano /etc/systemd/system/lighthousevalidator.service
#ajouter service
sudo systemctl daemon-reload
sudo systemctl start lighthousevalidator
sudo systemctl enable lighthousevalidator

#installing MEV boost
sudo useradd --no-create-home --shell /bin/false mevboost

cd ~
wget https://github.com/flashbots/mev-boost/releases/download/v1.3.2/mev-boost_1.3.2_linux_amd64.tar.gz

sha256sum mev-boost_1.3.2_linux_amd64.tar.gz
tar xvf mev-boost_1.3.2_linux_amd64.tar.gz
sudo cp mev-boost /usr/local/bin
rm mev-boost LICENSE README.md mev-boost_1.3.2_linux_amd64.tar.gz
sudo chown mevboost:mevboost /usr/local/bin/mev-boost

sudo nano /etc/systemd/system/mevboost.service

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

sudo systemctl daemon-reload
sudo systemctl start mevboost
sudo systemctl enable mevboost
