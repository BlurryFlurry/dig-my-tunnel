#!/usr/bin/env bash

# only run as root
if [[ $EUID -gt 0 ]]; then
  echo "Please run as root"
  exit
fi

ptb_service_user=$(cat "$HOME"/.config/ptb-service-user)

apt remove dialog dropbear squid acl -y

# remove nodews1 service
systemctl stope nodews1.service
systemctl disable nodews1.service
rm -rf /etc/systemd/system/nodews1.service

#remove python bot service
systemctl stop ptb@$ptb_service_user.service
systemctl disable ptb@$ptb_service_user.service
rm -rf /etc/systemd/system/ptb@.service

# remove stunnel
systemctl stop stunnel4.service
systemctl disable stunnel4.service
apt remove stunnel4 -y

# remove squid
systemctl stop squid.service
systemctl disable squid.service
apt remove squid -y

# remove badvpn service
systemctl stop badvpn.service
systemctl disable badvpn.service
rm /etc/systemd/system/badvpn.service



rm -rf /usr/bin/menu_r
rm -rf /etc/p7common


echo "Try 'apt-get autoremove' command for remove orphan packages."