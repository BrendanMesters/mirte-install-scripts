#!/bin/bash 

ZOEF_SRC_DIR=/usr/local/src/zoef

# Install wifi-connect
wget https://github.com/balena-io/wifi-connect/raw/master/scripts/raspbian-install.sh
chmod +x raspbian-install.sh
./raspbian-install.sh -y
rm raspbian-install.sh

# Make sure there are no conflicting hcdp-servers
sudo apt install -y dnsmasq-base
systemctl disable systemd-resolved
#echo "nameserver 8.8.8.8" > /etc/resolv.conf
systemctl disable hostapd

# Added systemd service to account for fix: https://askubuntu.com/questions/472794/hostapd-error-nl80211-could-not-configure-driver-mode
sudo rm /lib/systemd/system/zoef_ap.service
sudo ln -s $ZOEF_SRC_DIR/zoef_install_scripts/services/zoef_ap.service /lib/systemd/system/

sudo systemctl daemon-reload
sudo systemctl stop zoef_ap || /bin/true
sudo systemctl start zoef_ap
sudo systemctl enable zoef_ap

# Install avahi
sudo apt install -y libnss-mdns
sudo apt install -y avahi-utils avahi-daemon
sudo apt install -y avahi-utils avahi-daemon # NOTE: Twice, since regular apt installation on armbian fails (https://forum.armbian.com/topic/10204-cant-install-avahi-on-armbian-while-building-custom-image/)

# Disable lo interface for avahi
sed -i 's/#deny-interfaces=eth1/deny-interfaces=lo/g' /etc/avahi/avahi-daemon.conf

# Install inotify-wait to listen to wifi changes made by wifi-connect
sudo apt install -y inotify-tools

# Disable ssh root login
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config

# Install usb_ethernet script from EV3
wget https://raw.githubusercontent.com/ev3dev/ev3-systemd/ev3dev-buster/scripts/ev3-usb.sh -P $ZOEF_SRC_DIR/zoef_install_scripts
chmod +x $ZOEF_SRC_DIR/zoef_install_scripts/ev3_usb.sh
sudo chmod +x $ZOEF_SRC_DIR/zoef_install_scripts/ev3-usb.sh
sudo chown zoef:zoef $ZOEF_SRC_DIR/zoef_install_scripts/ev3-usb.sh
sudo bash -c 'echo "libcomposite" > /etc/modules'

# Generate wifi password (TODO: generate random password and put on NTFS)
if [ ! -f /etc/wifi_pwd ]; then
    sudo bash -c 'echo zoef_zoef > /etc/wifi_pwd'
fi

# Allow wifi_pwd to be modified using the web interface
sudo chmod 777 /etc/wifi_pwd
