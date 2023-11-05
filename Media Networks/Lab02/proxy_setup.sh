#!/bin/bash
# do "sudo -i" first, also if you get bad interpreter error do "sed -i 's/\r$//' scriptname.sh"
read -rp "Enter server-IP (not the proxy): " IP;
echo -e "Updating";
apt -qq -y update;
apt -qq -y upgrade;

echo -e "";
echo -e "Installing required packages";
apt -qq -y install nginx;

echo -e "";
echo -e "Configuring NGINX";
sleep 1;
echo -e "
# nginx-proxy
proxy_cache_path /var/www/cache levels=1:2 keys_zone=my_cache:10m
max_size=10g
inactive=60m use_temp_path=off;

server {
        listen 80 default_server;
        listen [::]:80 default_server;
        add_header X-CACHE-STATUS \$UPSTREAM_CACHE_STATUS;
        proxy_set_header X-REQUEST-ID \$REQUEST_ID;

        index index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
                proxy_cache my_cache;
                proxy_cache_valid 200 301 302;
                proxy_pass http://$IP;
        }
}" > default;
mv default /etc/nginx/sites-available/default;

echo -e "Creating Proxy-folder";
sleep 1;
mkdir /var/www/proxy;
chmod 777 /var/www/proxy;

echo "";
echo -e "Restarting nginx";
systemctl restart nginx;
exit 0;
