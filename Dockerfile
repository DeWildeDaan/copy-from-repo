FROM alpine:latest

RUN apk update && \
    apk add --no-cache \
    git \
    curl \
    bash \
    openssl \
    jq

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
