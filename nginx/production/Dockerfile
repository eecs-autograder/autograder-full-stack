FROM nginx:latest

VOLUME /www/static

# Add nginx config
ADD sites-enabled/nginx_production.conf /etc/nginx/conf.d/default.conf

RUN mkdir -p /etc/nginx/ssl
RUN openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048
