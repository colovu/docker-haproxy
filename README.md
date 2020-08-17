# Haproxy

针对 [Haproxy](http://www.haproxy.org) 应用的 Docker 镜像，用于提供 Haproxy 服务。

使用说明可参照：[官方说明](http://www.haproxy.org/#docs)

<img src="img/haproxy-logo.png" alt="haproxy-logo" style="zoom:200%;" />



**版本信息**：

- 2.0、latest

**镜像信息**

* 镜像地址：colovu/haproxy:latest



## **TL;DR**

Docker 快速启动命令：

```shell
# 启动三个 Nginx 实例
$ docker run -d --name www1 colovu/nginx:latest
$ docker run -d --name www2 colovu/nginx:latest
$ docker run -d --name www3 colovu/nginx:latest

# 启动 Haproxy 代理
$ docker run -d --name haproxy colovu/haproxy:latest
```

Docker-Compose 快速启动命令：

```shell
$ curl -sSL https://raw.githubusercontent.com/colovu/docker-haproxy/master/docker-compose.yml > docker-compose.yml

$ docker-compose up -d
```

启动后，可使用以下方式验证：

```shell
# 使用不同浏览器访问页面，刷新出的主机名会有所不同（或关闭 ID 对应容器后重新刷新，也会有变化）
http://localhost

# 访问管理页面
http://localhost:8888/haproxy
```


---



## 默认对外声明

### 端口

- 8080：默认使用此端口代理外部 80 端口（使用 Gosu 后不允许使用`1024`以下端口）
- 8888：默认状态监控的 Web 访问端口
- 14567：默认状态查询端口

### 数据卷

镜像默认提供以下数据卷定义，默认数据分别存储在自动生成的应用名对应`Haproxy`子目录中：

```shell
/srv/conf			# 配置文件
/srv/data			# 数据文件，主要存放应用数据
/var/log			# 日志输出
```

如果需要持久化存储相应数据，需要**在宿主机建立本地目录**，并在使用镜像初始化容器时进行映射。宿主机相关的目录中如果不存在对应应用`haproxy`的子目录或相应数据文件，则容器会在初始化时创建相应目录及文件。



## 容器配置

在初始化 `Haproxy` 容器时，如果没有预置配置文件，可以在命令行中设置相应环境变量对默认参数进行修改。类似命令如下：

```shell
$ docker run -d -e "HAPROXY_ADMIN_PORT=8888" --name haproxy colovu/haproxy:latest
```



### 常规配置参数

常规配置参数用来配置容器基本属性，一般情况下需要设置，主要包括：

- **HAPROXY_GLOBAL_STATS_PORT**：默认值：**14567**。状态查询默认端口
- **HAPROXY_ADMIN_PORT**：默认值：**8888**。Web状态查询端口
- **HAPROXY_ADMIN_STATS_URI**：默认值：**haproxy**。Web状态查询地址
- **HAPROXY_ADMIN_USER**：默认值：**admin**。Web状态查询默认用户
- **HAPROXY_ADMIN_PASS**：默认值：**colovu**。Web状态查询默认密码

### 常规可选参数

如果没有必要，可选配置参数可以不用定义，直接使用对应的默认值，主要包括：

- `ENV_DEBUG`：默认值：**false**。设置是否输出容器调试信息。可选值：1、true、yes

### 集群配置参数

配置服务为集群工作模式时，通过以下参数进行配置：

- 




## 安全

### 容器安全

本容器默认使用应用对应的运行时用户及用户组运行应用，以加强容器的安全性。在使用非`root`用户运行容器时，相关的资源访问会受限；应用仅能操作镜像创建时指定的路径及数据。使用`Non-root`方式的容器，更适合在生产环境中使用。



## 注意事项

- 容器中启动参数不能配置为后台运行，如果应用使用后台方式运行，则容器的启动命令会在运行后自动退出，从而导致容器退出；只能使用前台运行方式，如：`-db`



## 更新记录

- 2.0、2.0.14、latest



----

本文原始来源 [Endial Fang](https://github.com/colovu) @ [Github.com](https://github.com)
