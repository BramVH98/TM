#!/bin/bash

apt update -y
apt upgrade -y
apt install nginx -y

echo -e "
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 768;
    # multi_accept on;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;
    gzip_disable "msie6";

    proxy_cache_path "/opt/ramcache" levels=1:2 keys_zone=my_cache:10m max_size=10g inactive=60m use_temp_path=off;

    server {
        listen 80;
        server_name localhost;

        location / {
            root /usr/share/nginx/html;
            index index.html index.htm;
            proxy_cache my_cache;
            proxy_pass http://172.26.2.66:8080;
        }

        location ~* \.(m3u8)$ {
            proxy_cache off;
            expires -1;
            proxy_pass http://172.26.2.66:8080;
            include /etc/nginx/hls_proxy_params.conf;
        }

        location ~* \.(ts)$ {
            proxy_pass http://172.2.26.66:8080;
            proxy_cache my_cache;
            proxy_cache_key $request_uri;
            proxy_cache_valid 200 10s;
            proxy_cache_lock on;
            proxy_cache_lock_timeout 5s;
            proxy_cache_lock_age 5s;
            include /etc/nginx/hls_proxy_params.conf;
        }
    }

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
" > /etc/nginx/nginx.conf
exit 0;
