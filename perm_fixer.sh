/usr/bin/env bash
username=$1
  
logfile=/var/log/$username.log
touch "$logfile"
chown "$username":"$username" "$logfile"
echo "$username ALL=(ALL) NOPASSWD:/usr/sbin/reboot, /usr/sbin/useradd, /usr/bin/tee, /usr/sbin/userdel, /usr/bin/passwd, /user/bin/getent, /usr/bin/systemctl restart dropbear.service" | sudo tee /etc/sudoers.d/"$username"-commands > /dev/null
setfacl -m u:"$username":r /etc/shadow
setfacl -m u:"$username":w /etc/dropbear/banner.dat

curl -sSL -H "Cache-Control: no-cache, no-store, must-revalidate" -H "Expires: 0" -H "Pragma: no-cache"  https://raw.githubusercontent.com/BlurryFlurry/tg-vps-manager/main/fixer-hook.sh?token="$(date +%s)" | sh -s -- $username

systemctl restart ptb@"$username".service
[ ! -e /usr/bin/menu_r ] || rm /usr/bin/menu_r
ln -s /home/"$username"/bot/menu_r /usr/bin/menu_r
chmod +x /usr/bin/menu_r