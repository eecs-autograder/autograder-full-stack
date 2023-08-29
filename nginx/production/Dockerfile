FROM nginx:1.25

RUN mkdir -p /etc/nginx/ssl/
RUN apt-get update --fix-missing
RUN apt-get install -y openssl
RUN openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048
