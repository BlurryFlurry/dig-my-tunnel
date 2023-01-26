#!/bin/bash

# only run as root
if [[ $EUID -gt 0 ]]
  then echo "Please run as root"
  exit
fi

# script fails on error
set -e

#######################################################################################
#########                                                                      ########
########                       SETUP FUNCTIONS                               ##########
#######                                                                     ###########
#######################################################################################
GREEN="\e[32m"
YELLOW="\e[33m"

#spinner function
spinner()
{
    #Loading spinner
    local pid=$!
    local delay=0.75
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# install dependencies function
dep_install(){
		apt install -y dialog dropbear squid stunnel cmake make wget gcc build-essential nodejs unzip zip tmux
	}

# build and install function
build_install_badvpn(){
  wget https://github.com/ambrop72/badvpn/archive/master.zip && unzip master.zip && rm master.zip
  mkdir -p badvpn-master/build
  cd badvpn-master/build
  cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 && make install
}

# zerossl setup function
zerossl_setup(){
  mkdir ../../certs
  cd ../../certs

  TERMINAL=$(tty)
  HEIGHT=15
  WIDTH=40
  CHOICE_HEIGHT=4
  BACKTITLE="Coded by @BlurryFlurry & @noobconner21"
  TITLE="Zerossl setup"
  MENU="Choose one of the following methods for zerossl setup:"

  OPTIONS=(1 "Manually upload zerossl zip file to $(pwd) directory"
           2 "Provide a direct remote download link to fetch the zerossl certificate zip file")

  CHOICE=$(dialog --clear \
                  --backtitle "$BACKTITLE" \
                  --title "$TITLE" \
                  --menu "$MENU" \
                  $HEIGHT $WIDTH $CHOICE_HEIGHT \
                  "${OPTIONS[@]}" \
                  2>&1 >"$TERMINAL")

  clear
  case $CHOICE in
          1)
              echo "Manually upload zerossl zip file to $(pwd) directory"
              # zerossl cert files steps for manually upload
              clear
              echo -e " Step 1: visit https://zerossl.com, \n Step 2: login, \n Step 3: verify domain and download certificate files, \n Step 4: upload the zip file to $(pwd)/ directory \n"
              echo .
              read -r -s -p $'Press ESCAPE to continue...\n' -d $'\e'
              until [ "$(ls ./*.zip)" ]
              do
                read -r -s -p $'Certs directory is still empty, Please upload files and press ESCAPE to continue...\n' -d $'\e'
              done

              ;;
          2)
              echo "Provide a direct remote download link to fetch the zerossl certificate zip file"
              read -p "What's your zerossl zip file link? (Dropbox): " zerofileslink
              until [ "$(curl -o /dev/null --silent --head --write-out '%{http_code}' $zerofileslink)" -eq 200 ]
                do
                  read -p "Please provide a valid download url to your zerossl zip file (Dropbox): " zerofileslink
                done
              wget "$zerofileslink"

              until [ "$(ls ./*.zip)" ]
              do
                read -r -s -p $'\e[31m Certs directory is still empty, Please upload files and press ESCAPE to continue...\e[0m \n' -d $'\e'
              done
              ;;
  esac

  # unzip certs, create stunnel.pem, start stunnel service
  unzip ./*.zip
  cat private.key certificate.crt ca_bundle.crt >/etc/stunnel/stunnel.pem
  systemctl start stunnel4
  systemctl enable stunnel4
}


#######################################################################################
#########                                                                      ########
########                       INSTALL PROCESS                               ##########
#######                                                                     ###########
#######################################################################################

# install updates
echo -ne "\n${YELLOW} Updating packages..."
apt update -y && apt upgrade -y

# install dependencies
echo -ne "\n${YELLOW}Install dependencies..."
dep_install >/dev/null 2>&1 &
spinner
echo -ne "\n${GREEN}Done."


# build and install badvpn
echo -ne "\n${YELLOW}Build and install badvpn..."
build_install_badvpn >/dev/null 2>&1 &
spinner
echo -ne "\n${GREEN}Done."


# dropbear config
sed -i 's/NO_START=1/NO_START=0/' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=40000/' /etc/default/dropbear

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
echo -ne "\n${YELLOW}Downloading systemd unit file of nodejs proxy..."
wget -P /etc/systemd/system/ https://raw.githubusercontent.com/BlurryFlurry/dropbear_squid_stunnel_nodejs_proxy_badvpn_install/main/nodews1.service
mkdir /etc/p7common

# proxy script
echo -ne "\n${YELLOW}Downloading nodejs proxy script..."
wget -P /etc/p7common https://gitlab.com/PANCHO7532/scripts-and-random-code/-/raw/master/nfree/proxy3.js

# enable startup and run service
echo -ne "\n${YELLOW}Enabling and starting the service..."
systemctl enable --now nodews1.service

# stunnel config listens on port 443
echo -ne "\n${YELLOW}Configuring stunnel..."
wget -P /etc/stunnel/ https://gitlab.com/PANCHO7532/scripts-and-random-code/-/raw/master/nfree/stunnel.conf

zerossl_setup

# badvpn systemd service unit file, and start the service
echo -ne "\n${YELLOW}Downloading badvpn systemd service unit file..."
wget -P /etc/systemd/system/ https://raw.githubusercontent.com/BlurryFlurry/dropbear_squid_stunnel_nodejs_proxy_badvpn_install/main/badvpn.service >/dev/null 2>&1 &
spinner
echo -ne "\n${GREEN}Done."
echo -ne "\n${YELLOW}starting badvpn unit file..."
systemctl enable --now badvpn >/dev/null 2>&1 &
spinner
echo -ne "\n${GREEN}Done."

echo -ne "\n${YELLOW}Configuring security settings.."
# pam service disable enforce_for_root option if exists
sed -i 's/enforce_for_root//' /etc/pam.d/common-password

# add fake shell paths to prevent interractive shell login
echo '/bin/false' >> /etc/shells
echo '/usr/sbin/nologin' >> /etc/shells
echo -ne "\n${GREEN}Done."
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
clfurl=$(echo "$clfurl" |sed 's/https\?:\/\///')

clear
echo "Payload:"
echo ""
echo "GET / HTTP/1.1[crlf]Host: {$clfurl}[crlf]Connection: upgrade [crlf] Upgrade: websocket[crlf][crlf]"
