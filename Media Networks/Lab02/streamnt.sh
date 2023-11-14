#!/bin/bash

apt update -y
apt upgrade -y
apt install -y build-essential ffmpeg libpcre3 libpcre3-dev libssl-dev zlib1g-dev
apt install nginx
apt install libnginx-mod-rtmp

systemctl stop nginx
systemctl start nginx
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

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}

rtmp {
  server {
    listen 1935;
    chunk_size 4000;
    application mylive {
      live on;
      record all;
      record_path /tmp/recordings;
      record_max_size 1K;
      record_unique on;
      allow publish all;
      allow play all;
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

http {
  server {
    listen 8080;
    server_name bramstream;
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
" > /etc/nginx/nginx.conf;

mkdir -p /tmp/recordings;
chmod 777 /tmp/recordings;
mkdir -p /var/www/html/hls;
chmod 777 /var/www/html/hls;
mkdir -p /var/www/html/dash;
chmod 777 /var/www/html/dash;
mkdir -p /var/www/html/recordings;
chmod 777 /var/www/html/recordings;

echo -e "
!DOCTYPE html>
<html>
<head>
    <title>Video Player</title>
</head>
<body>
    <video id="videoPlayer" controls autoplay>
        <!-- You can specify a default video source here -->
        <source src="default.mp4" type="video/mp4">
    </video>

    <script>
        // Function to get the value of a GET variable from the URL
        function getParameterByName(name, url) {
            if (!url) url = window.location.href;
            name = name.replace(/[\[\]]/g, '\\$&');
            var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
                results = regex.exec(url);
            if (!results) return null;
            if (!results[2]) return '';
            return decodeURIComponent(results[2].replace(/\+/g, ' '));
        }

        // Get the value of the 'video' GET variable from the URL
        var videoSource = getParameterByName('video');

        if (videoSource) {
            // Set the video source based on the 'video' GET variable
            var videoPlayer = document.getElementById('videoPlayer');
            videoPlayer.src = 'recordings/' + videoSource;
            videoPlayer.load();
        }
    </script>
</body>
</html>
" > /var/www/html/video.html
chmod 777 /var/www/html/video.html
exit 0;
