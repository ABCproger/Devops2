FROM alpine
WORKDIR /home/optima
COPY ./funca .
RUN apk add libstdc++
RUN apk add libc6-compat
ENTRYPOINT ["./funca"]
