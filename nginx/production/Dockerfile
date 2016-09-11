FROM nginx:latest

RUN mkdir -p /etc/nginx/ssl
RUN openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048

VOLUME /www/static
VOLUME /etc/letsencrypt

# Add nginx config
ADD sites-enabled/nginx_production.conf /etc/nginx/conf.d/default.conf

