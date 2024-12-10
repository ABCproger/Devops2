FROM alpine:latest AS build
RUN apk add --no-cache \
    build-base \
    libstdc++ \
    gcc \
    g++ \
    automake \
    autoconf \
    musl-dev
WORKDIR /home/optima
COPY . .
RUN autoreconf --install
RUN ./configure
RUN make

FROM alpine:latest
RUN apk add --no-cache libstdc++ musl-dev
COPY --from=build /home/optima/funca /usr/local/bin/funca
ENTRYPOINT ["/usr/local/bin/funca"]
