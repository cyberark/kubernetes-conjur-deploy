FROM haproxy:1.7

RUN apt-get clean
RUN apt-get update
RUN apt-get install -y \
    curl \
    jq \
    vim 

COPY conjur-health-check.sh /root/
COPY start.sh /
ENTRYPOINT sleep infinity
