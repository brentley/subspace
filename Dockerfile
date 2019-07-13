FROM golang:1.11.5 AS build
MAINTAINER github.com/subspacecloud/subspace

RUN apt-get update \
    && apt-get install -y git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /go/src/github.com/subspacecloud/subspace

RUN go get -v \
    github.com/jteeuwen/go-bindata/... \
    github.com/dustin/go-humanize \
    github.com/julienschmidt/httprouter \
    github.com/Sirupsen/logrus \
    github.com/gorilla/securecookie \
    golang.org/x/crypto/acme/autocert \
    golang.org/x/time/rate \
	golang.org/x/crypto/bcrypt \
    go.uber.org/zap \
	gopkg.in/gomail.v2 \
    github.com/crewjam/saml \
    github.com/dgrijalva/jwt-go \
    github.com/skip2/go-qrcode

ADD *.go ./
ADD static ./static
ADD templates ./templates
ADD email ./email

ARG BUILD_VERSION=unknown

ENV GODEBUG="netdns=go http2server=0"
ENV GOPATH="/go"

RUN go-bindata --pkg main static/... templates/... email/... \
    && go fmt \
    && go vet --all

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -v --compiler gc --ldflags "-extldflags -static -s -w -X main.version=${BUILD_VERSION}" -o /usr/bin/subspace-linux-amd64



FROM phusion/baseimage:0.11
MAINTAINER github.com/soundscapecloud/soundscape

RUN apt-get update \
    && apt-get install -y iproute2 iptables dnsmasq socat

ENV DEBIAN_FRONTEND noninteractive

ADD entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --from=build /usr/bin/subspace-linux-amd64 /usr/bin/subspace

RUN chmod +x /usr/bin/subspace /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]

CMD [ "/sbin/my_init" ]
