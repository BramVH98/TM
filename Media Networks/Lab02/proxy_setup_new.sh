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
proxy_cache_path "/opt/ramcache" levels=1:2 keys_zone=my_cache:10m max_size=10g
inactive=60m use_temp_path=off;

server {
        listen 8080 default_server;
        listen [::]:8080 default_server;
        add_header X-CACHE-STATUS \$UPSTREAM_CACHE_STATUS;
        proxy_set_header X-REQUEST-ID \$REQUEST_ID;

        index index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
                proxy_cache my_cache;
                proxy_pass http://$IP:8080;
        }

        location ~*\.(m3u8)${
                proxy_cache off;
                expires -1;
                proxy_pass http://$IP:8080;
                include /etc/nginx/hls_proxy_params.conf
        }

        location ~*\.(ts)${
                proxy_pass http:/$IP:8000;
                proxy_cache hls;
                proxy_cache_key $request_uri;
                proxy_cache_valid 200 10s;
                proxy_cache_lock on;
                proxy_cache_lock_timeout 5s;
                proxy_cache_lock_age 5s;
                include /etc/nginx/hls_proxy_params.conf;
        }

}" > default;
mv default /etc/nginx/conf.d/hls_proxy.conf;

echo -e "
proxy_redirect              off;

proxy_connect_timeout       5s;
proxy_send_timeout          180s;
proxy_read_timeout          180s;

# Buffer for headers
proxy_buffer_size           16k;
proxy_buffers               512  32k;
proxy_temp_file_write_size  512k;
proxy_max_temp_file_size    256m;

# For keepalive
proxy_http_version          1.1;

proxy_set_header            Host $host;
proxy_set_header            X-Real-IP $remote_addr;
proxy_set_header            X-Forwarded-For $remote_addr;
proxy_set_header            X-Forwarded-Proto $scheme;

proxy_next_upstream         error timeout http_502 http_504;
proxy_next_upstream_tries   2;
echo -e "Creating Proxy-folder";
" > /etc/nginx/hls_proxy_params.conf

sleep 1;
mkdir -p /opt/ramcache
chown -R nginx:root /opt/ramcache

echo "";
echo -e "Restarting nginx";
systemctl restart nginx;
exit 0;
