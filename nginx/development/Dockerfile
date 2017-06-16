FROM nginx:latest

VOLUME /www/typescript
VOLUME /www/rest_framework

# Add nginx config
ADD sites-enabled/nginx_dev.conf /etc/nginx/conf.d/default.conf
