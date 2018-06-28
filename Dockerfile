FROM resin/odroid-xu4-alpine-buildpack-deps:latest

RUN [ "cross-build-start" ]

ENV GOLANG_VERSION 1.10.3
ENV GOLANG_ARCH linux-armv6l
ENV GOLANG_SRC_URL https://dl.google.com/go/go$GOLANG_VERSION.$GOLANG_ARCH.tar.gz
ENV GOLANG_SRC_SHA256 d3df3fa3d153e81041af24f31a82f86a21cb7b92c1b5552fb621bad0320f06b6

RUN apk add --no-cache ca-certificates

RUN set -ex \
	&& apk add --no-cache --virtual .build-deps \
		bash \
		gcc \
		musl-dev \
		openssl \
		go \
	\
	&& export GOROOT_BOOTSTRAP="$(go env GOROOT)" \
	\
	&& wget -q "$GOLANG_SRC_URL" -O golang.tar.gz \
	&& echo "$GOLANG_SRC_SHA256  golang.tar.gz" | sha256sum -c - \
	&& tar -C /usr/local -xzf golang.tar.gz \
	&& rm golang.tar.gz \
	&& cd /usr/local/go/src \
	&& ./make.bash \
	\
	&& rm -rf /*.patch \
	&& apk del .build-deps
	
RUN [ "cross-build-end" ] 	

ENV GOROOT /usr/local/go
ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH

COPY go-wrapper /usr/local/bin/

CMD ["echo","'No CMD command was set in Dockerfile! Details about CMD command could be found in Dockerfile Guide section in our Docs. Here's the link: http://docs.resin.io/deployment/dockerfile"]