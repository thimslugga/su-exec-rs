FROM redhat/ubi9-minimal

#RUN microdnf install -y wget

ENV PROJECT_VERSION 0.1.0
RUN set -eux; \
  microdnf install -y curl \
  rpm_arch="$(rpm --query --queryformat='%{ARCH}' rpm)"; \
	case "$rpm_arch" in \
		x86_64) dpkgArch='amd64' ;; \
		i[3456]86) dpkgArch='i386' ;; \
		aarch64) dpkgArch='arm64' ;; \
		armv[67]*) dpkgArch='armhf' ;; \
		ppc64le) dpkgArch='ppc64el' ;; \
		riscv64 | s390x) dpkgArch="$rpm_arch" ;; \
		*) echo >&2 "error: unknown/unsupported architecture '$rpm_arch'"; exit 1 ;; \
	esac; \
	wget -O /usr/local/bin/su-exec-rs "$URL"; \
	chmod +x /usr/local/bin/su-exec-rs; \
	su-exec-rs; \
	su-exec-rs nobody true
