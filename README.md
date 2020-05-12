# HAProxy

针对 HAProxy 应用的 Docker 镜像，用于提供 HAProxy 服务。

**版本信息**：

- 2.0、2.0.14、latest

**镜像信息**

* 镜像地址：colovu/haproxy:latest
  * 依赖镜像：colovu/ubuntu:latest



## 默认对外声明

### 端口

- 8888：HAProxy状态监控端口

### 数据卷

镜像默认提供以下数据卷定义，默认数据存储在自动生成的应用名对应子目录中：

```shell
/var/log			# 日志输出
/srv/conf			# 配置文件
/srv/data			# 数据存储
```

如果需要持久化存储相应数据，需要在宿主机建立本地目录，并在使用镜像初始化容器时进行映射。

举例：

- 使用宿主机`/host/dir/to/conf`存储配置文件
- 使用宿主机`/host/dir/to/data`存储数据文件
- 使用宿主机`/host/dir/to/log`存储日志文件

创建以上相应的宿主机目录后，容器启动命令中对应的数据卷映射参数类似如下：

```shell
-v /host/dir/to/conf:/srv/conf -v /host/dir/to/data:/srv/data -v /host/dir/to/log:/var/log
```

使用 Docker Compose 时配置文件类似如下：

```yaml
services:
  ha-name:
  ...
    volumes:
      - /host/dir/to/conf:/srv/conf
      - /host/dir/to/data:/srv/data
      - /host/dir/to/log:/var/log
  ...
```

> 注意：应用需要使用的子目录会自动创建。



## 使用说明

- 在后续介绍中，启动的容器默认命名为haproxy，需要根据实际情况修改



### 容器网络

在工作在同一个网络组中时，如果容器需要互相访问，相关联的容器可以使用容器初始化时定义的名称作为主机名进行互相访问。

创建网络：

```shell
$ docker network create app-tier --driver bridge
```

- 使用桥接方式，创建一个命名为`app-tier`的网络



### 下载镜像

可以不单独下载镜像，如果镜像不存在，会在初始化容器时自动下载。

```shell
# 下载指定Tag的镜像
$ docker pull colovu/haproxy:tag

# 下载最新镜像
$ docker pull colovu/haproxy:latest
```



### 运行容器

生成并运行一个新的容器：

```shell
 docker run -d --name haproxy \
  -v /host/dir/to/conf:/srv/conf \
  colovu/haproxy:latest
```

如果存在 dvc（endial/dvc-alpine） 数据卷容器：

```shell
docker run -d --name haproxy \
  --volumes-from dvc \
  colovu/haproxy:latest
```



### 进入容器

使用容器ID或启动时的命名（本例中命名为`haproxy`）进入容器：

```shell
docker exec -it haproxy /bin/bash
```



### 停止容器

使用容器ID或启动时的命名（本例中命名为`haproxy`）停止：

```shell
docker stop haproxy
```



## 注意事项

- 容器中启动参数不能配置为后台运行，只能使用前台运行方式，即：`daemone`
- 如果应用使用后台方式运行，则容器的启动命令会在运行后自动退出，从而导致容器退出



----

本文原始来源 [Endial Fang](https://github.com/colovu) @ [Github.com](https://github.com)
