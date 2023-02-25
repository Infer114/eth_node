#just a script for mevboost installation
#you have to edit your execution/consensus client to make use of this

wget https://github.com/flashbots/mev-boost/releases/download/v1.4.0/mev-boost_1.4.0_linux_amd64.tar.gz
#sha256sum mev-boost_1.4.0_linux_amd64.tar.gz
tar xvf mev-boost_1.4.0_linux_amd64.tar.gz
sudo systemctl stop mevboost
sudo cp mev-boost /usr/local/bin
rm mev-boost LICENSE README.md mev-boost_1.4.0_linux_amd64.tar.gz
sudo chown mevboost:mevboost /usr/local/bin/mev-boost
sudo systemctl start mevboost
