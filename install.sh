#!/bin/bash

# only run as root
if [[ $EUID -gt 0 ]]; then
  echo "Please run as root"
  exit
fi

# script fails on error
set -e

#######################################################################################
#########                                                                      ########
########                       SETUP FUNCTIONS                               ##########
#######                                                                     ###########
#######################################################################################

declare process_echo_history
declare last_process_status
spinner() {
  #spinner animation
  local pid=$!
  local delay=0.20
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  wait $pid
  last_process_status=$?
  printf "    \b\b\b\b"
}

process_echo() {
  local RED=$(tput setaf 1)
  local GREEN=$(tput setaf 2)
  local YELLOW=$(tput setaf 3)
  local ENDCOLOR=$(tput sgr0)
  local text="$1"
  local text_color=${!2:-$(tput sgr0)}
  local characters=${#text}
  local start_col=$(($(tput cols) / 2 - $characters / 2))
  local start_line=$(($(tput lines) / 2))
  local spinner_col=$(($(tput cols) - 7))
  tput civis
  clear
  echo -e "$process_echo_history"

  tput cup $start_line $start_col
  tput el
  echo -en "${text_color}$text${ENDCOLOR}"

  tput cup $start_line $spinner_col

  spinner
  p_status=$([ "$last_process_status" -eq 0 ] && echo "${GREEN}[DONE]${ENDCOLOR}" || echo "${RED}[FAIL]${ENDCOLOR}")
  echo -e "${GREEN}${p_status}${ENDCOLOR}"
  process_echo_history+="\n $text ${p_status}"
  sleep 0.5
  tput clear
  echo -e "$process_echo_history $ENDCOLOR"
  sleep 0.2
  tput cvvis
  tput cnorm
}

# install dependencies function
dep_install() {
  apt install -y software-properties-common
  add-apt-repository ppa:deadsnakes/ppa
  apt update -y
  apt install -y dialog dropbear squid stunnel cmake make wget gcc build-essential nodejs acl unzip zip tmux socat python3.10 python3.10-venv vnstat
}

# function to enable and start vnstat service
vnstat_setup() {
  systemctl enable --now vnstat.service
  systemctl restart vnstat.service
}


# build and install function
build_install_badvpn() {
  # add-apt-repository ppa:ambrop7/badvpn && apt-get update -y && apt-get install badvpn -y # todo: test this installation method
  wget https://github.com/ambrop72/badvpn/archive/master.zip && unzip master.zip && rm master.zip
  mkdir -p badvpn-master/build
  cd badvpn-master/build
  cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 && make install
}

# zerossl setup function
zerossl_setup() {
  mkdir ../../certs
  cd ../../certs
  local certs_dir=${PWD}

  TERMINAL=$(tty)
  HEIGHT=15
  WIDTH=40
  CHOICE_HEIGHT=4
  BACKTITLE="Coded by @BlurryFlurry & @noobconner21"
  TITLE="Zerossl setup"
  MENU="Choose one of the following methods for zerossl setup:"

  OPTIONS=(1 "Manually upload zerossl zip file to $(pwd) directory"
  2 "Provide a direct remote download link to fetch the zerossl certificate zip file"
  3 "acme.sh easy automation")

  CHOICE=$(dialog --clear --nocancel \
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
    until [ "$(ls ./*.zip)" ]; do
      read -r -s -p $'Certs directory is still empty, Please upload files and press ESCAPE to continue...\n' -d $'\e'
    done

    ;;
  2)
    echo "Provide a direct remote download link to fetch the zerossl certificate zip file"
    read -p "What's your zerossl zip file link? (Dropbox): " zerofileslink
    until [ "$(curl -o /dev/null --silent --head --write-out '%{http_code}' "$zerofileslink" 2>/dev/null)" -eq 200 ]; do
      read -p $'\e[31mPlease provide a valid download url to your zerossl zip file (Dropbox)\e[0m: ' zerofileslink
    done
    wget "$zerofileslink"

    until [ "$(ls ./*.zip)" ]; do
      read -r -s -p $'\e[31m Certs directory is still empty, Please upload files and press ESCAPE to continue...\e[0m \n' -d $'\e'
    done
    ;;
  3)
    echo -e "acme.sh standalone webserver (Beta)\n\n"
    read -p "Please provide a valid email address: " zerossl_email
    read -p "Please provide the domain name: " zerossl_domain

    systemctl stop nodews1 2>&1 >/dev/null
    process_echo "Disabling nodews1 proxy script to clear the port 80 temporary"
    #              curl https://get.acme.sh | sh -s email="$zerossl_email" --issue -d "$zerossl_domain" --standalone --server letsencrypt --staging --test
    #              cat ~/.acme.sh/"$zerossl_domain"/"$zerossl_domain".key ~/.acme.sh/"$zerossl_domain"/"$zerossl_domain" ~/.acme.sh/"$zerossl_domain"/fullchain.cer >/etc/stunnel/stunnel.pem

    curl https://get.acme.sh | sh -s email="$zerossl_email" >/dev/null 2>&1 &
    process_echo "Installing acme.sh..."
    bash ~/.acme.sh/acme.sh --register-account -m "$zerossl_email" >/dev/null 2>&1 &
    process_echo "Registering zerossl account..."
    #    bash ~/.acme.sh/acme.sh --issue --standalone -d "$zerossl_domain" --force --staging --test >/dev/null 2>&1 &
    bash ~/.acme.sh/acme.sh --issue --standalone -d "$zerossl_domain" --force >/dev/null 2>&1 &
    process_echo "issuing standalone certificates..."
    bash ~/.acme.sh/acme.sh --installcert -d "$zerossl_domain" --fullchainpath "$certs_dir"/bundle.cer --keypath "$certs_dir"/private.key >/dev/null 2>&1 &
    process_echo "Installing certificates..."
    cat "$certs_dir"/private.key "$certs_dir"/bundle.cer >/etc/stunnel/stunnel.pem
    chmod 400 /etc/stunnel/stunnel.pem

    systemctl start nodews1 2>&1 >/dev/null
    process_echo "Starting service nodews1 proxy script back online"
    ;;
  esac
  # unzip certs, create stunnel.pem, start stunnel service
  if [ ! -f "/etc/stunnel/stunnel.pem" ]; then
    unzip ./*.zip
    cat private.key certificate.crt ca_bundle.crt >/etc/stunnel/stunnel.pem
    chmod 400 >/etc/stunnel/stunnel.pem
  fi
  systemctl start stunnel4
  systemctl enable stunnel4
}

telegram_bot_setup() {
  read -p "Enter a username for the Telegram bot service (default is 'ptb'): " username
  username=${username:-ptb}          # use 'ptb' as default username if none was provided
  useradd -m -s /bin/false "$username" # create a new Linux user with the specified username
  cd /home/"$username"
  git clone https://github.com/BlurryFlurry/tg-vps-manager.git bot >/dev/null 2>&1 &
  process_echo "Cloning repository to /home/$username/bot ..." YELLOW
  cd bot

  /usr/bin/env python3.10 -m venv venv
  source venv/bin/activate
  pip3.10 install --upgrade pip  >/dev/null 2>&1 &
  process_echo "Upgrading pip3.10" YELLOW
  pip3.10 install wheel >/dev/null 2>&1 &
  process_echo "Installing wheel" YELLOW
  pip3.10 install -r requirements.txt >/dev/null 2>&1 &
  process_echo "Installing requirements..." YELLOW
  deactivate
  sudo chown -R "$username":"$username" /home/"$username"
  systemctl link /home/"$username"/bot/ptb@.service
  echo "Use https://t.me/BotFather to create a new telegram bot for your vps manager"
  echo "Copy the bot token and paste it here"
  read -p "Telegram Bot token: " bot_token
  echo "Use https://t.me/raw_data_bot to find your Telegram ID and paste it here"
  echo "This telegram user ID will be the only user ID that have /grant command permission"
  echo "(you can change these values by editing the env_vars file)"
  read -p "Admin telegram ID: " admin_id
  echo "grant_perm_id=$admin_id" >env_vars
  echo "telegram_bot_token=$bot_token" >>env_vars
  
  mkdir -p "$HOME"/.config
  echo "$username" >"$HOME/.config/ptb-service-user"
  
  systemctl daemon-reload # reload systemd configuration
  curl -sSL https://raw.githubusercontent.com/BlurryFlurry/dig-my-tunnel/main/perm_fixer.sh | sh -s -- $username
  
  systemctl start ptb@"$username".service && echo "Telegram bot service has started!"
  systemctl enable ptb@"$username".service 2>&1
  
}



#######################################################################################
#########                                                                      ########
########                       INSTALL PROCESS                               ##########
#######                                                                     ###########
#######################################################################################

ufw disable || echo "ufw is not found. Continuing.."

# install updates

apt update -qq -y >/dev/null 2>&1 &
process_echo "Updating packages..." YELLOW
apt upgrade -qq -y >/dev/null 2>&1 &
process_echo "Upgrading..." YELLOW

# install dependencies
dep_install >/dev/null 2>&1 &
process_echo "Installing dependencies..." YELLOW

# build and install badvpn
build_install_badvpn >/dev/null 2>&1 &
process_echo "Building and installing badvpn..." YELLOW

# dropbear config
sed -i 's/NO_START=1/NO_START=0/' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=40000/' /etc/default/dropbear

# set banner
read -p "Set custom banner?[Y/n]" -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]; then
  sed -i 's|DROPBEAR_BANNER=""|DROPBEAR_BANNER="/etc/dropbear/banner.dat"|' /etc/default/dropbear
  clear
  echo "Paste your banner and then type EOF (in uppercase) and hit ENTER"
  while read line; do
    [[ "$line" == "EOF" ]] && break
    echo "$line" >>"/etc/dropbear/banner.dat"
  done
fi

# systemd unit file node javascript proxy
wget -P /etc/systemd/system/ https://cdn.jsdelivr.net/gh/BlurryFlurry/dig-my-tunnel@main/nodews1.service >/dev/null 2>&1 &
process_echo "Downloading systemd unit file of nodejs proxy..." YELLOW
mkdir /etc/p7common

# proxy script
wget -P /etc/p7common https://gitlab.com/PANCHO7532/scripts-and-random-code/-/raw/master/nfree/proxy3.js >/dev/null 2>&1 &
process_echo "Downloading nodejs proxy script..." YELLOW

# enable startup and run service
systemctl enable --now nodews1.service >/dev/null 2>&1 &
process_echo "Enabling and starting the service..." YELLOW

# stunnel config listens on port 443
wget -P /etc/stunnel/ https://cdn.jsdelivr.net/gh/BlurryFlurry/dig-my-tunnel@main/stunnel.conf >/dev/null 2>&1 &
process_echo "Configuring stunnel..." YELLOW

zerossl_setup

# badvpn systemd service unit file, and start the service

wget -P /etc/systemd/system/ https://cdn.jsdelivr.net/gh/BlurryFlurry/dig-my-tunnel@main/badvpn.service >/dev/null 2>&1 &
process_echo "Downloading badvpn systemd service unit file..." YELLOW

systemctl enable --now badvpn >/dev/null 2>&1 &
process_echo "starting badvpn unit file..." YELLOW

vnstat_setup >/dev/null 2>&1 &
process_echo "Configuring vnstat..." YELLOW


echo "Configuring security settings.."
# pam service disable enforce_for_root option if exists
sed -i 's/enforce_for_root//' /etc/pam.d/common-password

# add fake shell paths to prevent interractive shell login
echo '/bin/false' >>/etc/shells
echo '/usr/sbin/nologin' >>/etc/shells
echo "Done."
sleep 1
clear

telegram_bot_setup

# create user
read -p "Create a user?[N/y]" -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo ""
  read -p "Enter username (characters): " ssh_user
  until [[ "$ssh_user" =~ ^[0-9a-zA-Z]{2,8}$ ]]; do
    read -p $'\e[31mPlease enter a valid username\e[0m: ' ssh_user
  done

  useradd -M "$ssh_user" -s /bin/false && echo "$ssh_user user has successfully created."
  set +e
  until passwd $ssh_user; do
    echo "Try again"
    sleep 1
  done
  read -p "Max logins limit: " maxlogins
  echo "$ssh_user  hard  maxlogins ${maxlogins}" >/etc/security/limits.d/"$ssh_user".conf
fi


echo "GET / HTTP/1.1[crlf]Host: [host][crlf]Connection: upgrade [crlf] Upgrade: websocket[crlf][crlf]"

read -rp "Press <Enter> to restart the server"
reboot
