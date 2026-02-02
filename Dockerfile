FROM ghcr.io/raspberrypi/raspios:bullseye-arm64

LABEL name="nintendo-dgamer"
LABEL description="nintendo-dgamer is a replacement DGamer (DS/DSi) server"
LABEL maintainer="hashsploit <hashsploit@protonmail.com>"

# Install dependencies (fast, precompiled)
RUN apt-get update -y \
    && apt-get install -y \
        apache2 \
        openssl \
        php \
        curl \
        unzip \
        build-essential \
        libbz2-dev libreadline-dev libexpat1-dev zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy your fork code
COPY ./ /srv/dgamer-server
WORKDIR /srv/dgamer-server

# Make entrypoint executable
RUN chmod +x /srv/dgamer-server/entrypoint.sh

# Expose required ports
EXPOSE 80/tcp 443/tcp 53/tcp 53/udp

# Start server
CMD ["/srv/dgamer-server/entrypoint.sh"]
