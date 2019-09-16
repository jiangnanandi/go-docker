# go-docker
Go + Docker + GitLab

![](https:/cl.ly/1398e09ac94e/jz1v8e2wrog01wo0ljyn.jpg)
> 如何在本地进行 Go 编码，使用 GitLab 私有库，并且同时在 Docker 环境中编译运行



如果你不清楚如何使用 Docker 或者不了解它是如何运作的，可以查看[官网文档](https://www.docker.com/why-docker)。

### 搭建环境

代码结构如下（业务代码不在本次讨论范围内）：
![](https:/cl.ly/d7d68f6e8c35/Image%202019-09-16%20at%201.53.56%20PM.png)
#### 初始化代码
在代码目录运行 `go mod init github.com/jiangnanandi/go-docker`,完成初始化，将自动生成文件如下（当然你需要把 Github 仓库名称改成自己的名字）：
**go.mod**
```applescript
module github.com/jiangnanandi/go-docker

go 1.12
```

**main.go**
```applescript
package main

import (
	"fmt"
)

func main() {
    fmt.Println("Hello, world!")
}
```

此时运行程序，将在命令行打印输出 `Hello World`

#### 配置开发环境的 Dockerfile
** dev.dockerfile**

```applescript
FROM golang:1.13-buster
RUN go get github.com/cespare/reflex
WORKDIR /app
COPY . .
ENTRYPOINT ["reflex", "-c", "reflex.conf"]
```

配置中使用了 [reflex](https://github.com/cespare/reflex) ，它的作用是监控代码的变动，如有修改则重新启动服务，可以查看配置 `reflex.conf` ：
**reflex.conf**
```applescript
-r '(\.go$|go\.mod)' -s go run .
```

这里意味着每当 `.go` 或者 `go.mod` 文件发生改变重新运行 `go run .`

**编译运行 Docker**
```applescript
docker build -t go-docker -f dev.dockerfile .

docker run -it --rm -v `pwd`:/app --name go-docker go-docker

```

此时，通过 docker 配置文件我们会生成一个名为 `go-docker` 的 docker 环境，并且将本地目录映射为 Docker 环境的 `/app` 目录，并且每当  `.go` 或者 `go.mod` 文件做出修改，就会重启服务。

#### 解决 Docker 中获取 gitlab 私有库代码问题

我在 Go 项目中使用了 GitLab 的私有代码库，如果想要在 Docker 中使用，可以通过通过如下方法，将本地的 `id_rsa` 文件加入项目中，Dockerfile 文件：

**将 git.xxx.com 换成自己的域名即可**

```applescript
FROM golang:1.13-buster
USER root
RUN apt-get update
RUN apt-get install -y git
RUN go get github.com/cespare/reflex
# 替换 git 配置，解决 go get 可以获取私有库代码
RUN git config --global url."git@git.xxx.com:".insteadOf "https://git.xxx.com"

# 传入参数解决 gitlab 私有库问题
ARG SSH_PRIVATE_KEY
RUN mkdir /root/.ssh/
RUN echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa

RUN touch /root/.ssh/config
RUN echo "StrictHostKeyChecking no" > /root/.ssh/config
RUN echo "UserKnownHostsFile /dev/null" >> /root/.ssh/config


WORKDIR /app
COPY . .
ENTRYPOINT ["reflex", "-c","reflex.conf"]
```

编译和启动 Docker：
```applescript
docker build --build-arg SSH_PRIVATE_KEY="$(cat ./id_rsa)" -t go-docker -f dev.dockerfile .

docker run  -it --rm -v `pwd`:/app --name go-docker go-docker
```
#### docker-compose
通过 `docker-compose.yml` 文件,我们可以更方便的配置 Docker 中的服务，例如 Mongodb、Redis 等服务，通常配置如下，大家可以参考:
```applescript
version: "3"
services:
  server:
    build:
      context: .
      dockerfile: dev.dockerfile
    ports:
      - 8080:1323 #host:container
    volumes:
      - .:/app
    environment:
      - GOPROXY
```