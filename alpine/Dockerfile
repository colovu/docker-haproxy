# Ver: 1.2 by Endial Fang (endial@126.com)
#

# 预处理 =========================================================================
FROM colovu/abuilder as builder

# sources.list 可使用版本：default / tencent / ustc / aliyun / huawei
ARG apt_source=default

# 编译镜像时指定用于加速的本地服务器地址
ARG local_url=""

ENV APP_NAME=haproxy \
	APP_VERSION=2.0.17

WORKDIR /usr/local

RUN select_source ${apt_source};
RUN install_pkg libc-dev lua5.3-dev pcre2-dev openssl-dev zlib-dev

# 下载并解压软件包
RUN set -eux; \
	appName="${APP_NAME}-${APP_VERSION}.tar.gz"; \
	sha256="e7e2d14a75cbe65f1ab8f7dad092b1ffae36a82436c55accd27530258fe4b194"; \
	[ ! -z ${local_url} ] && localURL=${local_url}/${APP_NAME}; \
	appUrls="${localURL:-} \
		https://www.haproxy.org/download/2.0/src \
		"; \
	download_pkg unpack ${appName} "${appUrls}" -s "${sha256}"; 

# 源码编译软件包
RUN set -eux; \
# 源码编译方式安装: 编译后将原始配置文件拷贝至 ${APP_DEF_DIR} 中
	APP_SRC="/usr/local/${APP_NAME}-${APP_VERSION}"; \
	cd ${APP_SRC}; \
	makeOpts=" \
		PREFIX=/usr/local/${APP_NAME} \
		TARGET=linux-glibc \
		USE_GETADDRINFO=1 \
		USE_LUA=1 LUA_LIB_NAME=lua LUA_LIB=/usr/lib/lua5.3 LUA_INC=/usr/include/lua5.3 \
		USE_OPENSSL=1 \
		USE_PCRE2=1 \
		USE_PCRE2_JIT=1 \
		USE_ZLIB=1 \
		"; \
	extraObjs=" \
		contrib/prometheus-exporter/service-prometheus.o \
		"; \
	make -j "$(nproc)" all ${makeOpts} ${extraObjs}; \
	make install-bin ${makeOpts}; \
	cp -rf ./examples /usr/local/${APP_NAME};

# 检测并生成依赖文件记录
# Alpine: scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/${APP_NAME} | tr ',' '\n' | sort -u | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }'
# Debian: find /usr/local/${APP_NAME} -type f -executable -exec ldd '{}' ';' | awk '/=>/ { print $(NF-1) }' | sort -u | xargs -r dpkg-query --search | cut -d: -f1 | sort -u
RUN set -eux; \
	scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/${APP_NAME} | \
		tr ',' '\n' | \
		sort -u | \
		awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } \
		{ print "so:" $1 }' >/usr/local/${APP_NAME}/runDeps;

# 镜像生成 ========================================================================
FROM colovu/alpine:3.12

ARG apt_source=default
ARG local_url=""

ENV APP_NAME=haproxy \
	APP_USER=haproxy \
	APP_EXEC=haproxy \
	APP_VERSION=2.0.17

ENV	APP_HOME_DIR=/usr/local/${APP_NAME} \
	APP_DEF_DIR=/etc/${APP_NAME} \
	APP_CONF_DIR=/srv/conf/${APP_NAME} \
	APP_DATA_DIR=/srv/data/${APP_NAME} \
	APP_DATA_LOG_DIR=/srv/datalog/${APP_NAME} \
	APP_CACHE_DIR=/var/cache/${APP_NAME} \
	APP_RUN_DIR=/var/run/${APP_NAME} \
	APP_LOG_DIR=/var/log/${APP_NAME} \
	APP_CERT_DIR=/srv/cert/${APP_NAME}

ENV PATH="${APP_HOME_DIR}/sbin:${PATH}"

LABEL \
	"Version"="v${APP_VERSION}" \
	"Description"="Docker image for ${APP_NAME}(v${APP_VERSION})." \
	"Dockerfile"="https://github.com/colovu/docker-${APP_NAME}" \
	"Vendor"="Endial Fang (endial@126.com)"

COPY customer /

# 以包管理方式安装软件包(Optional)
RUN select_source ${apt_source}
RUN install_pkg lua5.3

RUN create_user && prepare_env

# 从预处理过程中拷贝软件包(Optional)
COPY --from=builder /usr/local/haproxy/ /usr/local/haproxy

# 安装依赖软件包
RUN install_pkg `cat ${APP_HOME_DIR}/runDeps`; 

# 执行预处理脚本，并验证安装的软件包
RUN set -eux; \
	cp -rf ${APP_HOME_DIR}/examples/errorfiles ${APP_DEF_DIR}/errors; \
	\
	override_file="/usr/local/overrides/overrides-${APP_VERSION}.sh"; \
	[ -e "${override_file}" ] && /bin/bash "${override_file}"; \
	gosu ${APP_USER} ${APP_EXEC} -v ; \
	:;

# 默认提供的数据卷
VOLUME ["/srv/conf", "/srv/data", "/var/log"]

STOPSIGNAL SIGUSR1

# 默认使用gosu切换为新建用户启动，必须保证端口在1024之上
# EXPOSE 8080 8888 14567

# 容器初始化命令，默认存放在：/usr/local/bin/entry.sh
ENTRYPOINT ["entry.sh"]

# 应用程序的服务命令，必须使用非守护进程方式运行。如果使用变量，则该变量必须在运行环境中存在（ENV可以获取）
#   -W  : "master-worker mode" (similar to the old "haproxy-systemd-wrapper"; allows for reload via "SIGUSR2")
#   -db : disables background mode
CMD [ "${APP_EXEC}", "-W", "-db", "-f", "/srv/conf/haproxy/haproxy.cfg" ]
