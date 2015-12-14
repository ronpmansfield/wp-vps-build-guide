server {
    server_name www.example.com;
    rewrite ^/(.*)$ https://example.com/$1 permanent;
}

server {
    listen 443 default ssl http2;
    listen [::]:443 default ssl http2 ipv6only=on;

    server_name example.com;
    root /var/www/example;
    include global/common.conf;
    include global/wordpress.conf;
    
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    
    pagespeed LoadFromFile "https://example.com/" "/var/www/example/";
}