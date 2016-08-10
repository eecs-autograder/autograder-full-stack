FROM nginx:latest

# Install dart
RUN apt-get update --fix-missing
RUN apt-get install -y curl
RUN apt-get install -y apt-transport-https
RUN sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
RUN sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
RUN apt-get update
RUN apt-get install -y dart
ENV dart_bin_dir /usr/lib/dart/bin
ENV PATH $dart_bin_dir:$PATH

VOLUME /www/static

# Add nginx config
ADD sites-enabled/nginx_dev.conf /etc/nginx/conf.d/default.conf
