#!/bin/bash

echo -e "Updating"

sudo apt -qq -y update
sudo apt -qq -y upgrade

echo -e ""
echo -e "Installing packages"

sudo apt -qq -y install nginx libnginx-mod-rtmp ffmpeg build-essential

echo -e ""
echo -e "NGINX configuring"

sleep 1

echo -e "
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
        worker_connections 768;
}

http {

        sendfile on;
        tcp_nopush on;
        types_hash_max_size 2048;

        include /etc/nginx/mime.types;
        default_type application/octet-stream;

        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;

        gzip on;

        include /etc/nginx/conf.d/*.conf;
        include /etc/nginx/sites-enabled/*;
}

rtmp {
        include /etc/nginx/rtmpconf.d/*.conf;
}
" > nginx.conf;

mv nginx.conf /etc/nginx/nginx.conf

echo -e "RTMP Configuring"

sleep 1

mkdir /etc/nginx/rtmpconf.d > /dev/null 2>&1

echo -e "
server {
        listen 1935;
        chunk_size 4096;

        application live {
              live on;
              record off;

              push rtmp://localhost/dash/;
              push rtmp://localhost/hls/;
        }

        application hls {
              allow publish 127.0.0.1;
              deny publish all;

              live on;
              record all;
              record_path /var/www/html/rec;
              exec_record_done ffmpeg -y -i \$path -acodec libmp3lame -ar 44100 -ac 1 -vcodec libx264 /var/www/html/rec/\$basename.mp4 -vframes 1 /var/www/html/rec/\$basename.jpg;

              hls on;
              hls_path /var/www/html/hls;
              hls_fragment 3;
              hls_playlist_length 60;
        }
        application dash {
              allow publish 127.0.0.1;
              deny publish all;

              live on;
              record off;

              dash on;
              dash_path /var/www/html/dash;
        }
        application vod {
              play /var/www/html/rec;
        }
}
" > streaming.conf;
mv streaming.conf /etc/nginx/rtmpconf.d

echo -e "HTML folder creation"

sleep 1

rm -R /var/www/html/* > /dev/null 2>&1

mkdir /var/www/html/hls
mkdir /var/www/html/dash
mkdir /var/www/html/rec

chmod 777 /var/www/html
chmod 777 /var/www/html/hls
chmod 777 /var/www/html/dash
chmod 777 /var/www/html/rec

echo -e "HTML downloading..."

sleep 1

wget https://raw.githubusercontent.com/dust555/MediaNetworks/main/HttpStreaming/dash.all.js > /dev/null 2>&1
wget https://raw.githubusercontent.com/dust555/MediaNetworks/main/HttpStreaming/dash.html > /dev/null 2>&1
wget https://raw.githubusercontent.com/dust555/MediaNetworks/main/HttpStreaming/dash.php > /dev/null 2>&1
wget https://raw.githubusercontent.com/dust555/MediaNetworks/main/HttpStreaming/hls.html > /dev/null 2>&1
wget https://raw.githubusercontent.com/dust555/MediaNetworks/main/HttpStreaming/hls.js > /dev/null 2>&1
wget https://raw.githubusercontent.com/dust555/MediaNetworks/main/HttpStreaming/hls.php > /dev/null 2>&1

mv dash.all.js /var/www/html > /dev/null 2>&1
mv dash.html /var/www/html > /dev/null 2>&1
mv dash.php /var/www/html > /dev/null 2>&1
mv hls.html /var/www/html > /dev/null 2>&1
mv hls.js /var/www/html > /dev/null 2>&1
mv hls.php /var/www/html > /dev/null 2>&1



echo -e "
# Please see /usr/share/doc/nginx-doc/examples/ for more detailed examples.

server {
        listen 80 default_server;
        listen [::]:80 default_server;

        # SSL configuration
        #
        # listen 443 ssl default_server;
        # listen [::]:443 ssl default_server;
        #
        # Note: You should disable gzip for SSL traffic.
        # See: https://bugs.debian.org/773332
        #
        # Read up on ssl_ciphers to ensure a secure configuration.
        # See: https://bugs.debian.org/765782
        #
        # Self signed certs generated by the ssl-cert package
        # Don't use them in a production server!
        #
        # include snippets/snakeoil.conf;

        root /var/www/html;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files \$uri \$uri/ =404;
        }
        location ~* \.(?:html)$ {
                add_header Cache-Control: public;
        }
        location ~* \.(?:jpg|jpeg|gif|png|ico|cur|gz|svg|svgz|mp4|ogg|ogv|webm|htc)$ {
                expires 1M;
                add_header Cache-Control: public;
        }
        location ~* \.(?:css|js)$ {
                expires 1y;
                add_header Cache-Control: public;
        }

        # pass PHP scripts to FastCGI server
        #
        #location ~ \.php$ {
        #       include snippets/fastcgi-php.conf;
        #
        #       # With php-fpm (or other unix sockets):
        #       fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        #       # With php-cgi (or other tcp sockets):
        #       fastcgi_pass 127.0.0.1:9000;
        #}

        # if apache concurs with nginx
        #location ~ /\.ht {
        #       deny all;
        #}
}" > /etc/nginx/sites-available/default

echo ""
echo -e "NGINX restarting"
systemctl restart nginx
exit 0
