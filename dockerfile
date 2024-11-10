ARG ALPINE_VERSION=3.15


FROM alpine:${ALPINE_VERSION} AS build-env

ARG GO_VERSION=1.19.13
ARG BUILD_OS=linux
ARG BUILD_ARCH=amd64

WORKDIR /build

RUN set -eux; \
  apk add --no-cache \
    bash \
    libc6-compat

RUN set -eux; \
  wget -O go.tar.gz "https://dl.google.com/go/go${GO_VERSION}.${BUILD_OS}-${BUILD_ARCH}.tar.gz" ; \
  tar -C /usr/local/ -xzf go.tar.gz; \
  rm -f go.tar.gz

ENV GOPATH=/go
ENV GOFLAGS="-v -mod=readonly -mod=vendor"
ENV GO111MODULE=on
ENV CGO_ENABLED=0

ENV PATH="${GOPATH}/bin:/usr/local/go/bin:${PATH}"

RUN go version


FROM build-env AS rtorrent-cli-builder

ARG TARGET_OS
ARG TARGET_ARCH
ARG BUILD_MARKDOWN=no

ENV GOOS="${TARGET_OS}"
ENV GOARCH="${TARGET_ARCH}"

COPY ./ ./

RUN set -eux; \
  echo "GOOS=${GOOS}"; \
  echo "GOARCH=${GOARCH}"; \
  \
  go build -ldflags "-s -w -extldflags '-static  -fno-PIC'" -o "/rtorrent-cli-${GOOS}-${GOARCH}" ./cmd/rtorrent-cli; \
  \
  if [ "${BUILD_MARKDOWN}" == "yes" ]; then \
    go build -ldflags "-s -w -extldflags '-static  -fno-PIC'" -o "/rtorrent-cli-markdown-${GOOS}-${GOARCH}" ./cmd/rtorrent-cli-markdown; \
  fi


FROM scratch AS rtorrent-cli

ARG TARGET_OS
ARG TARGET_ARCH

COPY --from=rtorrent-cli-builder "/rtorrent-cli-${TARGET_OS}-${TARGET_ARCH}" /rtorrent-cli

ENTRYPOINT ["/rtorrent-cli"]


FROM scratch AS rtorrent-cli-markdown

ARG TARGET_OS
ARG TARGET_ARCH

COPY --from=rtorrent-cli-builder "/rtorrent-cli-markdown-${TARGET_OS}-${TARGET_ARCH}" /rtorrent-cli-markdown

ENTRYPOINT ["/rtorrent-cli-markdown"]


FROM scratch

RUN "Fake target to avoid error" && false
