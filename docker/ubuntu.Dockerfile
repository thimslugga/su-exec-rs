# ubuntu.Dockerfile
FROM docker.io/ubuntu:latest

# Install necessary packages
RUN set -exu; \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install --quiet --assume-yes --no-install-recommends \
        locales \
        wget \
        curl \
        ca-certificates \
        build-essential && \
    apt-clean && rm -rf ./var/lib/apt/lists/*; \
    mkdir -p /src; \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Add Rust to PATH
ENV PATH="/root/.cargo/bin:${PATH}"

# Set the working directory
WORKDIR /src

# Copy the Rust project files
COPY . .

# Build and run commands are in the docker-compose.yml file
