#!/usr/bin/env bash

# only run as root
if [[ $EUID -gt 0 ]]; then
  echo "Please run as root"
  exit
fi

ptb_service_user=$(cat "$HOME"/.config/ptb-service-user)
set -e
apt remove dialog dropbear squid acl -y

# remove nodews1 service
systemctl stop nodews1.service
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

# remove badvpn / service
systemctl stop badvpn.service
systemctl disable badvpn.service
rm /etc/systemd/system/badvpn.service
rm /usr/local/bin/badvpn-udpgw
rm /usr/local/share/man/badvpn*
rm -rf ~/badvpn-master || true

# remove vnstat
systemctl stop vnstat.service
systemctl disable vnstat.service
apt remove vnstat -y

rm -rf /usr/bin/menu_r
rm -rf /etc/p7common

# delete certs folder
rm -rf /certs

echo "Try 'apt-get autoremove' command for remove orphan packages."