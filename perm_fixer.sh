/usr/bin/env bash
username=$1
  
logfile=/var/log/$username.log
touch "$logfile"
chown "$username":"$username" "$logfile"
echo "$username ALL=(ALL) NOPASSWD:/usr/sbin/reboot, /usr/sbin/useradd, /usr/bin/tee, /usr/bin/passwd" | sudo tee /etc/sudoers.d/"$username"-commands > /dev/null
setfacl -m u:"$username":r /etc/shadow

systemctl restart ptb@"$username".service
rm /usr/bin/menu_r
ln -s /home/"$username"/bot/menu_r /usr/bin/menu_r
chmod +x /usr/bin/menu_r