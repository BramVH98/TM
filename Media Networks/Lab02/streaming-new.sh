#!/bin/bash
echo -e "Updating";
# do "sudo -i" first, also if you get bad interpreter error do "sed -i 's/\r$//' scriptname.sh"
# execute this from the git clone folder (for mv index.html)
currect_dir=$(pwd)
apt -qq -y update;
apt -qq -y upgrade;

echo -e "";
echo -e "Installing required packages";

apt -qq -y install libpcre3 libpcre3-dev libssl-dev zlib1g-dev ffmpeg build-essential;
apt -qq -y install nginx libnginx-mod-rtmp;

echo -e "";
echo -e "Configuring NGINX";
sleep 1;
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

        server {
                listen 8080;
                server_name bram.server;
                location / {
                        add_header Cache-Control no-cache;

                        add_header 'Access-Control-Allow-Origin' '*' always;
                        add_header 'Access-Control-Expose-Headers' 'Content-Length';

                        #types {
                                #application/vnd.apple.mpegurl m3u8;
                                #video/mp2t ts;
                        #}
                        root /var/www/html;
                        index hls.html;
                }
        }
}

rtmp {
        server {
                listen 1935;
                chunk_size 4000;
                application mytv {
                        live on;
                        record all;
                        record_path /tmp/recordings;
                        record_max_size 1K;
                        record_unique on;
                        allow publish 127.0.0.1;
                }

                application hls {
                        live on;
                        hls on;
                        hls_path /var/www/html/hls;
                        hls_fragment 10;
                        hls_playlist_length 60;
                        record all;
                        record_path /var/www/html/recordings;
                        record_max_size 1K;
                        record_unique on;
                        exec_record_done ffmpeg -y -i $path -acodec libmp3lame -ar 44100 -ac 1 -vcodec libx264 $dirname/$basename.mp4;
                }

                application dash {
                        live on;
                        dash on;
                        dash_path /var/www/html/dash;
                }
        }
}" > nginx.conf;
mv nginx.conf /etc/nginx/nginx.conf;

echo -e "Creating HTML-folders";
sleep 1;
rm -R /var/www/html/* > /dev/null 2>&1;

mv "$currect_dir/index.html" /var/www/html/index.html;

mkdir /tmp/recordings;
mkdir /var/www/html/hls;
mkdir /var/www/html/dash;
mkdir /var/www/html/recordings;

chmod 777 /var/www/html;
chmod 777 /var/www/html/*;
chmod 777 /tmp/recordings;


echo -e "Restarting nginx";
systemctl restart nginx;
exit 0;
