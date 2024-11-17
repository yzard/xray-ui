ARG GO_VERSION="1.23.5"
ARG CADDY_VERSION="2.9.1"
ARG DEBIAN_VERSION="11"

# build xui
FROM golang:${GO_VERSION} AS xui
WORKDIR /root
COPY . .
RUN go build -ldflags "-linkmode external -extldflags '-static'" main.go


# build forego
FROM golang:${GO_VERSION} as forego
ARG FOREGO_VERSION
RUN git clone https://github.com/nginx-proxy/forego/ \
   && cd /go/forego \
   && git -c advice.detachedHead=false checkout $FOREGO_VERSION \
   && go mod download \
   && CGO_ENABLED=0 GOOS=linux go build -o forego . \
   && go clean -cache \
   && mv forego /usr/local/bin/ \
   && cd - \
   && rm -rf /go/forego


# build caddy
FROM caddy:${CADDY_VERSION}-builder-alpine AS caddy
RUN xcaddy build --with github.com/ueffel/caddy-brotli

# build final image
FROM alpine:latest as main
RUN apk add --no-cache bash ca-certificates tzdata curl

# copy caddy to final image
COPY --from=caddy /usr/bin/caddy /usr/bin/caddy
ENV CADDYPATH="/etc/caddy"
ENV XDG_DATA_HOME="/data"
ENV DOCKER_HOST="unix:///tmp/docker.sock"

# copy forego to final image
COPY --from=forego /usr/local/bin/forego /usr/local/bin/forego

# copy x-ui to final image
COPY --from=xui  /root/main /usr/local/bin/x-ui

COPY ./caddy/* /root/caddy/
COPY ./backup_binary/* /root/backup_binary/
COPY ./yzard.procfile /root/
COPY ./yzard.docker_entrypoint.sh /root/
WORKDIR /root

EXPOSE 80 443 2015
VOLUME [ "/root/bin/",  "/etc/xray-ui", "/etc/caddy", "/data/caddy" ]

ENTRYPOINT ["sh", "/root/yzard.docker_entrypoint.sh"]
CMD ["/usr/local/bin/forego", "start", "-f", "yzard.procfile", "-r"]
