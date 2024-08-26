#!/usr/bin/env bash

#sudo dnf groupinstall -y "Development Tools" "Development Libraries"
#sudo dnf isntall -y gcc gcc-c++ make cmake automake autoconf libtool pkgconfig m4 bison flex gettext \
#  glibc-static libstdc++-static glibc-devel

# building source.c with gcc
#gcc -Wall -Werror source.c -o pewpew
gcc -o pewpew -static source.c

#docker run -it --rm -v "$PWD":/src -w /src -u "$(id -u):$(id -g)" gcc gcc -o pewpew -static ./source.c

#podman run -it --rm -v "$(pwd)":/src -w /src gcc gcc -o pewpew -static ./source.c

# Usage:
# ./pewpew
# id

# Fedora Silverblue 40
# $ ./pewpew
# ++ ioctl failed: Input/output error

# sudo bash
# root # ./busybox su -v
#./busybox su <username> -c ./pewpew

# Container
# docker run -it --rm -v "$PWD":/cwd:ro docker.io/ubuntu /cwd/pewpew

# Container with su-exec-rs
# docker run -it --rm -v "$PWD":/cwd:ro docker.io/ubuntu /cwd/su-exec-rs nobody /cwd/pewpew
