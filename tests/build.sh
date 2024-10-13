#!/bin/bash

# Usage of source.c is to test su-exec-rs
#
# ./pewpew
# id
#
# Fedora Silverblue 40
# $ ./pewpew
# ++ ioctl failed: Input/output error
#
# sudo bash
# root # ./busybox su -v
#./busybox su <username> -c ./pewpew
#
# Container
# docker run -it --rm -v "$PWD":/cwd:ro docker.io/ubuntu /cwd/pewpew
#
# Container with su-exec-rs
# docker run -it --rm -v "$PWD":/cwd:ro docker.io/ubuntu /cwd/su-exec-rs nobody /cwd/pewpew

usage() {
  echo "Usage: $0 [command]"
  echo ""
  echo "Commands:"
  echo "  install-deps"
  echo "  build-static-source"
  echo "  build-source"
  echo "  podman-build-source"
  echo "  docker-build-source"
}

installDeps() {
  dnf update -y
  dnf groupinstall -y "Development Tools" "Development Libraries"
  dnf install -y gcc gcc-c++ glibc-static libstdc++-static glibc-devel \
    make cmake automake autoconf libtool pkgconfig m4 bison flex gettext
}

# Building source.c with GCC
buildStaticSource() {
  #gcc -Wall -Werror source.c -o pewpew
  gcc -o pewpew -static source.c
}

podmanBuildSource() {
  local workdir
  workdir="$(pwd)"

  podman run -it \
    --rm \
    -v "$workdir":/src \
    -w /src gcc gcc \
    -o pewpew \
    -static ./source.c
}

dockerBuildSource() {
  local workdir userid groupid
  workdir="$(pwd)"
  userid="$(id -u)"
  groupid="$(id -g)"

  docker run -it \
    --rm \
    -v "$workdir":/src \
    -w /src \
    -u "$userid":"$groupid" \
    gcc gcc -o pewpew -static ./source.c
}

main() {
  local command
  command="$1"

  case "$command" in
  install-deps)
    installDeps
    ;;
  build-static-source)
    buildStaticSource
    ;;
  build-source)
    buildStaticSource
    ;;
  podman-build-source)
    podmanBuildSource
    ;;
  docker-build-source)
    dockerBuildSource
    ;;
  *)
    usage
    ;;
  esac
}

main "$@"
