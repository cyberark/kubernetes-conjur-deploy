FROM cyberark/conjur-kubernetes-authenticator:latest as authenticator

# Main container
FROM alpine:3.9

RUN apk add --no-cache bash \
                       jq \
                       wget

COPY --from=authenticator /bin/authenticator /usr/bin

ENV CONJUR_VERSION=5 \
    CONTAINER_MODE=init

COPY get-seedfile.sh \
     start-follower.sh /usr/bin/

RUN chmod +x /usr/bin/get-seedfile.sh \
             /usr/bin/start-follower.sh

CMD ["get-seedfile.sh"]