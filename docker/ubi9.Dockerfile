FROM docker.io/redhat/ubi9:latest

ENV PROJECT_VERSION 0.1.0

RUN set -eux; microdnf update && microdnf install -y wget curl; \
    rpm_arch="$(rpm --query --queryformat='%{ARCH}' rpm)"; \
	case "$rpm_arch" in \
		x86_64) rpmarch='amd64' ;; \
		i[3456]86) rpmarch='i386' ;; \
		aarch64) rpmarch='arm64' ;; \
		armv[67]*) rpmarch='armhf' ;; \
		ppc64le) rpmarch='ppc64el' ;; \
		riscv64 | s390x) rpmarch="$rpm_arch" ;; \
		*) echo >&2 "Error: unknown/unsupported architecture '$rpm_arch'"; exit 1 ;; \
	esac; \
	wget -O /usr/local/bin/su-exec-rs "$URL" && \
    chmod +x /usr/local/bin/su-exec-rs && \
	su-exec-rs; su-exec-rs nobody true;
