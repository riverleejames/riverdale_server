FROM ubuntu:25.10

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    perl \
    libwww-perl \
    libmojolicious-perl \
    libxml-libxml-perl \
    atomicparsley \
    ffmpeg \
    wget \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install get_iplayer
RUN wget -O /usr/local/bin/get_iplayer https://raw.githubusercontent.com/get-iplayer/get_iplayer/master/get_iplayer && \
    chmod +x /usr/local/bin/get_iplayer

# Create directories
RUN mkdir -p /downloads /root/.get_iplayer

# Set working directory
WORKDIR /downloads

# Keep container running
CMD ["tail", "-f", "/dev/null"]
