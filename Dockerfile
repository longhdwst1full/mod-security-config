FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
  logrotate \
  cron \
  tzdata \
  build-essential \
  libpcre3 libpcre3-dev \
  libpcre2-dev \
  libxml2 libxml2-dev \
  libyajl-dev \
  curl git wget \
  zlib1g-dev \
  libtool automake autoconf \
  pkg-config \
  libcurl4-openssl-dev \
  liblua5.3-dev \
  ca-certificates \
  cmake

WORKDIR /opt

# Build ModSecurity v3
RUN git clone --depth 1 -b v3/master https://github.com/SpiderLabs/ModSecurity \
 && cd ModSecurity \
 && git submodule init \
 && git submodule update \
 && ./build.sh \
 && ./configure \
 && make -j$(nproc) \
 && make install

# Clone nginx connector
RUN git clone --depth 1 https://github.com/SpiderLabs/modsecurity-nginx.git

# Build nginx with dynamic module
RUN wget http://nginx.org/download/nginx-1.24.0.tar.gz \
 && tar zxvf nginx-1.24.0.tar.gz \
 && cd nginx-1.24.0 \
 && ./configure --with-compat --add-dynamic-module=../modsecurity-nginx \
 && make -j$(nproc) \
 && make install \
 && mkdir -p /usr/local/nginx/modules \
 && cp objs/ngx_http_modsecurity_module.so /usr/local/nginx/modules/

# Copy config
COPY nginx.conf /usr/local/nginx/conf/nginx.conf
COPY index.html /usr/share/nginx/html/index.html
COPY modsecurity.conf /usr/local/nginx/conf/modsecurity.conf
COPY unicode.mapping /usr/local/nginx/conf/unicode.mapping
COPY modsec-logrotate.conf /etc/logrotate.d/modsec
COPY modsec-logrotate-cron /etc/cron.d/modsec-logrotate

# Copy CRS rules
COPY ../crs /usr/local/nginx/conf/crs

# Tạo log folder
RUN mkdir -p /var/log/modsec && chown -R nobody:nogroup /var/log/modsec
RUN mkdir -p /var/log/modsec/audit && chown -R nobody:nogroup /var/log/modsec

# Fix cron permissions
RUN chmod 0644 /etc/cron.d/modsec-logrotate

# # Apply cron jobs
# RUN crontab /etc/cron.d/modsec-logrotate
RUN apt-get install -y dos2unix \
 && dos2unix /etc/logrotate.d/modsec
RUN chmod 644 /etc/logrotate.d/modsec
# Add entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

CMD ["/entrypoint.sh"]
