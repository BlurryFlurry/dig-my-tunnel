#!/bin/bash
if [[ $EUID > 0 ]]
  then echo "Please run as root"
  exit
fi
set -e
apt update -y && apt upgrade -y
apt install -y dropbear squid stunnel cmake make wget gcc build-essential nodejs unzip zip tmux
wget https://github.com/ambrop72/badvpn/archive/master.zip && unzip master.zip && rm master.zip
mkdir -p badvpn-master/build
cd badvpn-master/build
cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 && make install

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

wget -P /etc/systemd/system/ https://raw.githubusercontent.com/BlurryFlurry/dropbear_squid_stunnel_nodejs_proxy_badvpn_install/main/nodews1.service
mkdir /etc/p7common
wget -P /etc/p7common https://gitlab.com/PANCHO7532/scripts-and-random-code/-/raw/master/nfree/proxy3.js
systemctl enable --now nodews1.service
wget -P /etc/stunnel/ https://gitlab.com/PANCHO7532/scripts-and-random-code/-/raw/master/nfree/stunnel.conf

mkdir ../../certs
cd ../../certs

clear
echo -e " Step 1: visit https://zerossl.com, \n Step 2: login, \n Step 3: verify domain and download certificate files, \n Step 4: upload the zip file to $(pwd)/ directory \n"
echo .

read -r -s -p $'Press ESCAPE to continue...\n' -d $'\e'
until [ "$(ls -A .)" ]
do
	read -r -s -p $'Certs directory is still empty, Please upload files and press ESCAPE to continue...\n' -d $'\e'
done
unzip *.zip
cat private.key certificate.crt ca_bundle.crt >/etc/stunnel/stunnel.pem
systemctl start stunnel4
systemctl enable stunnel4
wget -P /etc/systemd/system/ https://gitlab.com/PANCHO7532/scripts-and-random-code/-/raw/master/nfree/badvpn.service
systemctl enable --now badvpn
sed -i 's/enforce_for_root//' /etc/pam.d/common-password
echo '/bin/false' >> /etc/shells
echo '/usr/sbin/nologin' >> /etc/shells
clear
read -p "Create a user?[N/y]" -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]
then
    read -p "Enter username: " ssh_user
    useradd -M $ssh_user -s /bin/false && echo "$ssh_user user has successfully created." && passwd $ssh_user
fi
read -p "Enter your cloudfront url: " clfurl
clfurl=$(echo $clfurl |sed 's/https\?:\/\///')

clear
echo "Payload:"
echo ""
echo "GET / HTTP/1.1[crlf]Host: $clfurl[crlf]Connection: Upgrade[crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf][crlf]"
