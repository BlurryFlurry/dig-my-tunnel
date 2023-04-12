# Dropbear Squid Stunnel Nodejs Proxy Badvpn auto installer

```
apt-get install curl -y && bash <(curl https://cdn.jsdelivr.net/gh/BlurryFlurry/dropbear_squid_stunnel_nodejs_proxy_badvpn_install@main/install.sh)
````

### Read this first before you run the installer!

- I've only tested this script on Ubuntu 20.04 LTS.
- Install updates and upgrade first with command:`sudo apt update -y && apt upgrade -y`and wait for completing the process.
- You should have your own domain/subdomain pointed to the IP address of your vps/server/instance with an "A" record. 
- If you don't have a domain name, you can use cloudns.com or https://freenet.cafe websites. This is a requirement for the SSL certificate-generating process for Stunnel.
- Tip: When you are at generating the SSL certificate process, You should note, it's easier if you select acme.sh automation, and it will save a lot of time because you will not have to go through the zerossl certificate site and create accounts and verify your domain, acme.sh option will automatically do it for you.
- **Very important:** Your firewall must be disabled and your public IP address must accept inbound traffic. or you should know what you are doing with the firewall settings.

- **Cloudfront tunnels**: You do not need to already have an AWS Cloudfront distribution created before you execute the script. You can create it after you are done with this script. But it does not harm if you already have created one for your domain.
- SSH Banner file is located in `/etc/dropbear/banner.dat`. You can modify this banner file after you finish the script (`sudo nano /etc/dropbear/banner.dat`).<br> Don't forget to restart dropbear service when you are finished modifying banner using this command: `systemctl restart dropbear.service`. <br>This script will also interactively ask you to set the banner. You can answer `NO` by pressing  `N` if you prefer creating a banner file after finishing this script, or you can press `Y` to answer `yes`. Then you will have to paste the html banner contents, After you paste the banner content, You have to hit the `<ENTER>` and go to the next line, and then you have to type `EOF` in capital letters. then hit `<Enter>` key again. It will start continuing the installation process. 

ProTip: Execute this script on tmux session, (in case you have a laggy internet connection)

Nodejs proxy script credits goes to [@PANCHO7532](https://gitlab.com/PANCHO7532)

More credits to [@noobconner21](https://gitlab.com/noobconner21) for helping me out
