# Dig my tunnel

### (Dropbear Squid Stunnel Nodejs Proxy Badvpn auto installer)


[![Watch the video](https://i.imgur.com/oqIbrhO.png)](https://vimeo.com/824303001)

### Description:
This script helps you to install packages: Dropbear Squid Stunnel Nodejs Proxy Badvpn and configure automatically for tunneling purpose.
The target of this script is install only the minimum packages to reduce the processor usage, and prevent the server from slowing down and allow keep everything up and running on even servers that has very minimal resources.


Installation command: (read the instructions below before you execute this command)
```
apt-get install curl -y && bash <(curl https://cdn.jsdelivr.net/gh/BlurryFlurry/dig-my-tunnel@main/install.sh)
````

### Read this first before you run the installer!

- I've only tested this script on Ubuntu 20.04 LTS.
- Install updates and upgrade first with command:`sudo apt update -y && apt upgrade -y`and wait for completing the process.
- Port 80 must be free to use. If you have no idea how to check if the port 80 is busy or make it free: try this command: `sudo apt install nodejs npm -y && npx kill-port 80` <br> and verify it by this command: `(ss -ntlp | grep ':80 ') >/dev/null && echo 'port 80 is busy' || echo 'port 80 is free'` <- if this command give you the output saying port 80 is busy, you must find the process that keeping port 80 is busy and stop it before you continue. I suggest you to use google and do some reasearch about it. If port 80 is free, you are good to proceed.
- You should have your own domain/subdomain pointed to the IP address of your vps/server/instance with an "A" record. 
- If you don't have a domain name, you can use cloudns.com or https://freenet.cafe websites. This is a requirement for the SSL certificate-generating process for Stunnel.
- Tip: When you are at generating the SSL certificate process, You should note, it's easier if you select acme.sh automation, and it will save a lot of time because you will not have to go through the zerossl certificate site and create accounts and verify your domain, acme.sh option will automatically do it for you.
- **Very important:** Your firewall must be disabled and your public IP address must accept inbound traffic. or you should know what you are doing with the firewall settings. You can tweak your firewall after you finishing the installation process. (Again, google is your friend)

- **Cloudfront tunnels**: You do not need to already have an AWS Cloudfront distribution created before you execute the script. You can create it after you are done with this script. But it does not harm if you already have created one for your domain.
- SSH Banner file is located in `/etc/dropbear/banner.dat`. You can modify this banner file after you finish the script (`sudo nano /etc/dropbear/banner.dat`).<br> Don't forget to restart dropbear service when you are finished modifying banner using this command: `systemctl restart dropbear.service`. <br>This script will also interactively ask you to set the banner. You can answer `NO` by pressing  `N` if you prefer creating a banner file after finishing this script, or you can press `Y` to answer `yes`. Then you will have to paste the html banner contents, After you paste the banner content, You have to hit the `<ENTER>` and go to the next line, and then you have to type `EOF` in capital letters. then hit `<Enter>` key again. It will start continuing the installation process. 

Uninstall command:
```
apt-get install curl -y && bash <(curl https://cdn.jsdelivr.net/gh/BlurryFlurry/dig-my-tunnel@main/uninstall.sh)
````


ProTip: Execute this script on tmux session, (in case you have a laggy internet connection)

**I am not responsible for any kind of damage that happen to your server after you use this script, so you should be able to rebuild your vps/server in case anything go wrong. If you found a bug, Fix it your self and make a pull request or open an issue.**

Nodejs proxy script credits goes to [@PANCHO7532](https://gitlab.com/PANCHO7532)

More credits to [@noobconner21](https://gitlab.com/noobconner21) for helping me out
