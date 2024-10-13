FROM docker.io/fedora:latest

# Install necessary packages
RUN set -eux; \
    dnf update && dnf install -y curl gcc && dnf clean all; \
    mkdir -p /src; \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Add Rust to PATH
ENV PATH="/root/.cargo/bin:${PATH}"

# Set the working directory
WORKDIR /src

# Copy the Rust project files
COPY . .

# Build and run commands are in the compose.yml file
