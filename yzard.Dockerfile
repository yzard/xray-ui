ARG FOREGO_VERSION="v0.18.3"
ARG GO_VERSION="1.26.0"
ARG CADDY_VERSION="2.11.1"


# build xui
FROM golang:${GO_VERSION} AS xui
WORKDIR /root
COPY . .
RUN go build -ldflags "-linkmode external -extldflags '-static'" main.go

# build forego
FROM golang:${GO_VERSION} AS forego
RUN git clone https://github.com/nginx-proxy/forego/ \
   && cd /go/forego \
   && git -c advice.detachedHead=false checkout ${FOREGO_VERSION} \
   && go mod download \
   && CGO_ENABLED=0 GOOS=linux go build -o forego . \
   && go clean -cache \
   && mv forego /usr/local/bin/ \
   && cd - \
   && rm -rf /go/forego

# build caddy with brotli
FROM caddy:${CADDY_VERSION}-builder-alpine AS caddy
RUN xcaddy build --with github.com/ueffel/caddy-brotli


# build image
FROM alpine:latest AS main
RUN apk add --no-cache bash ca-certificates tzdata curl

COPY --from=caddy /usr/bin/caddy /usr/bin/caddy
COPY --from=forego /usr/local/bin/forego /usr/local/bin/forego
COPY --from=xui  /root/main /usr/local/bin/x-ui

ENV CADDYPATH="/etc/caddy"
ENV XDG_DATA_HOME="/data"
ENV DOCKER_HOST="unix:///tmp/docker.sock"

COPY ./caddy/* /root/caddy/
COPY ./backup_binary/* /root/backup_binary/
COPY ./yzard.procfile /root/
COPY ./yzard.docker_entrypoint.sh /root/
WORKDIR /root

EXPOSE 80 443 2015
VOLUME [ "/root/bin/",  "/etc/xray-ui", "/etc/caddy", "/data/caddy" ]

ENTRYPOINT ["sh", "/root/yzard.docker_entrypoint.sh"]
CMD ["/usr/local/bin/forego", "start", "-f", "yzard.procfile", "-r"]
