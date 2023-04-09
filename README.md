# Dropbear Squid Stunnel Nodejs Proxy Badvpn auto installer

```
apt-get install curl -y && bash <(curl https://cdn.jsdelivr.net/gh/BlurryFlurry/dropbear_squid_stunnel_nodejs_proxy_badvpn_install@main/install.sh)
````

I only have tested this script on ubuntu 20.04 LTS.

Before you executing this script, you should have a domain/subdomain pointed to the ip address of your vps/server/instance with "A" record.

If you don't have a domain name, you can use cloudns.com or freenet.cafe websites. This is a requirement for the SSL certificate generating process.

ProTip: Execute this script on tmux session, (in case you have a laggy internet connection)

Nodejs proxy script credits goes to [@PANCHO7532](https://gitlab.com/PANCHO7532)

More credits to [@noobconner21](https://gitlab.com/noobconner21) for helping me out
