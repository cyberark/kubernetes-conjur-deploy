FROM haproxy:1.8

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y && \
    apt-get install -y curl jq vim procps socat && \
    rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /docker-entrypoint.sh

COPY conjur-health-check.sh /root/
COPY haproxy.cfg /usr/local/etc/haproxy/
