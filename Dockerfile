FROM ghcr.io/raspberrypi/raspios:bullseye-slim

LABEL name="nintendo-dgamer"
LABEL description="nintendo-dgamer is a replacement DGamer (DS/DSi) server"
LABEL maintainer="hashsploit <hashsploit@protonmail.com>"

# Install dependencies
RUN apt-get update -y \
    && apt-get install -y \
        curl build-essential make wget tar xz-utils \
        libbz2-dev libreadline-dev libexpat1-dev zlib1g-dev \
        libssl-dev ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Compile OpenSSL (Pi-friendly version)
RUN curl -sSL https://www.openssl.org/source/openssl-1.1.1t.tar.gz -o /tmp/openssl.tar.gz \
    && cd /tmp \
    && tar -xzf openssl.tar.gz \
    && cd openssl-1.1.1t \
    && ./config --prefix=/usr --openssldir=/usr/lib/ssl no-shared \
    && make -j$(nproc) \
    && make install

# Compile PCRE
RUN curl -sSL https://ftp.pcre.org/pub/pcre/pcre-8.45.tar.bz2 -o /tmp/pcre.tar.bz2 \
    && cd /tmp \
    && tar -xjf pcre.tar.bz2 \
    && cd pcre-8.45 \
    && ./configure --prefix=/usr \
        --enable-unicode-properties \
        --enable-pcre16 \
        --enable-pcre32 \
        --enable-pcregrep-libz \
        --enable-pcregrep-libbz2 \
        --enable-pcretest-libreadline \
        --disable-static \
    && make -j$(nproc) \
    && make install

# Compile Apache 2.4.54 from source (slightly newer)
RUN curl -sSL https://downloads.apache.org/httpd/httpd-2.4.54.tar.gz -o /tmp/httpd.tar.gz \
    && curl -sSL https://downloads.apache.org/apr/apr-1.7.0.tar.gz -o /tmp/apr.tar.gz \
    && curl -sSL https://downloads.apache.org/apr/apr-util-1.6.1.tar.gz -o /tmp/apr-util.tar.gz \
    && cd /tmp \
    && tar -xzf httpd.tar.gz \
    && tar -xzf apr.tar.gz \
    && tar -xzf apr-util.tar.gz \
    && mv apr-1.7.0 httpd-2.4.54/srclib/apr \
    && mv apr-util-1.6.1 httpd-2.4.54/srclib/apr-util \
    && cd httpd-2.4.54 \
    && ./configure \
        --prefix=/usr/local/apache \
        --with-included-apr \
        --enable-ssl \
        --with-ssl=/usr/lib/ssl \
        --enable-ssl-staticlib-deps \
        --enable-mods-static=ssl \
        --enable-modules=all \
        --enable-so \
    && make -j$(nproc) \
    && make install

# Generate self-signed certificates
RUN mkdir -p /usr/local/apache/certs \
    && openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
       -subj "/C=US/ST=California/L=San Jose/O=None/CN=localhost" \
       -keyout /usr/local/apache/certs/server.key \
       -out /usr/local/apache/certs/server.crt

# Copy site files
COPY ./sites/ /var/www/
COPY ./certs/ /usr/local/apache/certs/
COPY ./configs/apache/ /usr/local/apache/conf/
COPY ./entrypoint.sh /srv/
RUN chmod +x /srv/entrypoint.sh

EXPOSE 80/tcp 443/tcp 53/tcp 53/udp
CMD ["/srv/entrypoint.sh"]
