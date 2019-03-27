FROM alpine:3.9

RUN apk add --no-cache bash \
                       wget

COPY get-seedfile.sh \
     start-follower.sh /usr/bin/

RUN chmod +x /usr/bin/get-seedfile.sh \
             /usr/bin/start-follower.sh

CMD ["get-seedfile.sh"]