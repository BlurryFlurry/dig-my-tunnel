#!/bin/bash

# only run as root
if [[ $EUID > 0 ]]
  then echo "Please run as root"
  exit
fi

# script fails on error
set -e

# install dependencies
apt update -y && apt upgrade -y
apt install -y dropbear squid stunnel cmake make wget gcc build-essential nodejs unzip zip tmux

# build and install badvpn
wget https://github.com/ambrop72/badvpn/archive/master.zip && unzip master.zip && rm master.zip
mkdir -p badvpn-master/build
cd badvpn-master/build
cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 && make install

# set banner
read -p "Set custom banner?[Y/n]" -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]
then
	sed -i 's|DROPBEAR_BANNER=""|DROPBEAR_BANNER="/etc/dropbear/banner.dat"|' /etc/default/dropbear
	clear
	echo "Paste your banner and then type EOF (in uppercase) and hit ENTER"
	while read line
	do
 		[[ "$line" == "EOF" ]] && break
		echo "$line" >> "/etc/dropbear/banner.dat"
	done
fi

# systemd unit file node javascript proxy
wget -P /etc/systemd/system/ https://raw.githubusercontent.com/BlurryFlurry/dropbear_squid_stunnel_nodejs_proxy_badvpn_install/main/nodews1.service
mkdir /etc/p7common

# proxy script
wget -P /etc/p7common https://gitlab.com/PANCHO7532/scripts-and-random-code/-/raw/master/nfree/proxy3.js

# enable startup and run service
systemctl enable --now nodews1.service

# stunnel config listens on port 443
wget -P /etc/stunnel/ https://gitlab.com/PANCHO7532/scripts-and-random-code/-/raw/master/nfree/stunnel.conf

mkdir ../../certs
cd ../../certs

# zerossl cert files steps
clear
echo -e " Step 1: visit https://zerossl.com, \n Step 2: login, \n Step 3: verify domain and download certificate files, \n Step 4: upload the zip file to $(pwd)/ directory \n"
echo .

read -r -s -p $'Press ESCAPE to continue...\n' -d $'\e'
until [ "$(ls -A .)" ]
do
	read -r -s -p $'Certs directory is still empty, Please upload files and press ESCAPE to continue...\n' -d $'\e'
done

# unzip certs, create stunnel.pem, start stunnel service
unzip *.zip
cat private.key certificate.crt ca_bundle.crt >/etc/stunnel/stunnel.pem
systemctl start stunnel4
systemctl enable stunnel4

# badvpn systemd service unit file, and start the service
wget -P /etc/systemd/system/ https://raw.githubusercontent.com/BlurryFlurry/dropbear_squid_stunnel_nodejs_proxy_badvpn_install/main/badvpn.service
systemctl enable --now badvpn

# pam service disable enforce_for_root option if exists
sed -i 's/enforce_for_root//' /etc/pam.d/common-password

# add fake shell paths to prevent interractive shell login
echo '/bin/false' >> /etc/shells
echo '/usr/sbin/nologin' >> /etc/shells
clear

# create user
read -p "Create a user?[N/y]" -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo ""
    read -p "Enter username: " ssh_user
    useradd -M $ssh_user -s /bin/false && echo "$ssh_user user has successfully created." && passwd $ssh_user
fi

# display payload creation from cloudfront url
read -p "Enter your cloudfront url: " clfurl
clfurl=$(echo $clfurl |sed 's/https\?:\/\///')

clear
echo "Payload:"
echo ""
echo "GET / HTTP/1.1[crlf]Host: $clfurl[crlf]Connection: upgrade [crlf] Upgrade: websocket[crlf][crlf]"
