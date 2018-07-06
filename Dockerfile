FROM resin/odroid-xu4-alpine-buildpack-deps:latest as app-build

RUN [ "cross-build-start" ]

ENV GOLANG_VERSION 1.10.3
ENV GOLANG_ARCH linux-armv6l
ENV GOLANG_SRC_URL https://dl.google.com/go/go$GOLANG_VERSION.$GOLANG_ARCH.tar.gz
ENV GOLANG_SRC_SHA256 d3df3fa3d153e81041af24f31a82f86a21cb7b92c1b5552fb621bad0320f06b6

# Compile GO
RUN set -ex \
	&& apk update \
	&& apk add --no-cache --virtual .build-deps \
		ca-certificates \
		openssl \
		bash \
		curl \
		gcc \
		musl-dev \
		go \
		git \
	&& wget -q "$GOLANG_SRC_URL" -O golang.tar.gz \
	&& echo "$GOLANG_SRC_SHA256  golang.tar.gz" | sha256sum -c - \
	&& tar -C /usr/local -xzf golang.tar.gz \
	&& rm golang.tar.gz

RUN export GOROOT_BOOTSTRAP="$(go env GOROOT)" \
	&& cd /usr/local/go/src \
	&& ./make.bash
	
ENV GOROOT /usr/local/go
ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

# Build minio
ENV CGO_ENABLED 0
ENV MINIO_UPDATE off
ENV MINIO_ACCESS_KEY_FILE=access_key \
    MINIO_SECRET_KEY_FILE=secret_key

WORKDIR /go/src/github.com/minio/

RUN echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
     go get -v -d github.com/minio/minio

RUN cd /go/src/github.com/minio/minio && \
     go install -v -ldflags "$(go run buildscripts/gen-ldflags.go)"

RUN rm -rf /go/pkg /go/src /usr/local/go && apk del .build-deps
	
RUN [ "cross-build-end" ]

# Image creation stage
FROM resin/armhf-alpine:latest
RUN [ "cross-build-start" ]
RUN apk --no-cache add ca-certificates libtool

COPY --from=app-build /go/bin/minio /usr/bin/
COPY docker-entrypoint.sh healthcheck.sh /usr/bin/

RUN chmod +x /usr/bin/minio
RUN chmod +x /usr/bin/docker-entrypoint.sh
RUN chmod +x /usr/bin/healthcheck.sh

RUN [ "cross-build-end" ]

EXPOSE 9000

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]

VOLUME ["/data"]

HEALTHCHECK --interval=30s --timeout=5s \
    CMD /usr/bin/healthcheck.sh

CMD ["minio"]
