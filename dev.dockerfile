FROM golang:1.13-buster
# 如遇墙，可开启代理
# ENV GO111MODULE="on"
# ENV GOPROXY="https://goproxy.io"
RUN go get github.com/cespare/reflex
WORKDIR /app
COPY . .
ENTRYPOINT ["reflex", "-c", "reflex.conf"]