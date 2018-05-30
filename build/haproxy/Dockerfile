FROM haproxy:1.7

RUN apt-get update -y && \
    apt-get install -y curl jq vim procps && \
    rm -rf /var/lib/apt/lists/*

COPY conjur-health-check.sh /root/
COPY start.sh /

ENTRYPOINT sleep infinity
