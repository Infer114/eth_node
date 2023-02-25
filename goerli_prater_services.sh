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
