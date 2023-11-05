#!/bin/bash
echo -e "Updating";

apt -qq -y update;
apt -qq -y upgrade;

echo -e "\n\nInstalling packages";

apt -qq -y install nginx libnginx-mod-rtmp ffmpeg build-essential;

echo -e "\n\nConfig NGINX";

sleep 1;

# Create the nginx.conf file with your configuration content
echo "user www-data;
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
}" | tee /etc/nginx/nginx.conf;

# Ensure the file is owned by the correct user
chown www-data:www-data /etc/nginx/nginx.conf

# Move or copy any other required files or directories as needed


echo -e "\nRTMP config";

sleep 1;

mkdir /etc/nginx/rtmpconf.d > /dev/null 2>&1;

# Create the stream.conf file with your configuration content
echo 'server {
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
        record path /var/www/html/rec;
        exec_record_done ffmpeg -y -i $path -acodec libmp3lame -ar 44100 -ac 1 -vcodec libx264 /var/www/html/rec/$basename.mp4 -vframes 1 /var/www/html/rec/$basename.jpg;
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
}' | tee /etc/nginx/rtmpconf.d/stream.conf;

echo -e "\nHTML stuff happening now";

sleep 1;

rm -R /var/www/html/* > /dev/null 2>&1;

mkdir /var/www/html/hls;
mkdir /var/www/html/dash;
mkdir /var/www/html/rec;

find /var/www/html -type d -exec chmod 777 {} \;

sleep 1;

wget https://raw.githubusercontent.com/dust555/MediaNetworks/main/HttpStreaming/dash.all.js > /dev/null 2>&1;
wget https://raw.githubusercontent.com/dust555/MediaNetworks/main/HttpStreaming/dash.html > /dev/null 2>&1;
wget https://raw.githubusercontent.com/dust555/MediaNetworks/main/HttpStreaming/dash.php > /dev/null 2>&1;
wget https://raw.githubusercontent.com/dust555/MediaNetworks/main/HttpStreaming/hls.html > /dev/null 2>&1;
wget https://raw.githubusercontent.com/dust555/MediaNetworks/main/HttpStreaming/hls.js > /dev/null 2>&1;
wget https://raw.githubusercontent.com/dust555/MediaNetworks/main/HttpStreaming/hls.php > /dev/null 2>&1;

mv dash.all.js /var/www/html > /dev/null 2>&1;
mv dash.html /var/www/html > /dev/null 2>&1;
mv dash.php /var/www/html > /dev/null 2>&1;
mv hls.html /var/www/html > /dev/null 2>&1;
mv hls.js /var/www/html > /dev/null 2>&1;
mv hls.php /var/www/html > /dev/null 2>&1;

echo -e "\n";
 #this is without ssl certificates as a test
 
# Create the Nginx server block configuration file with your content
echo 'server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/html;

        index index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
            try_files $uri $uri/ =404;
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
}' | sudo tee /etc/nginx/sites-available/default;


echo -e "\nRestarting NGINX";

sudo systemctl restart nginx;
exit 0;
