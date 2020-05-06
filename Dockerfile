FROM endial/ubuntu:18.04

ARG app_major=2.0
ARG app_minor=2.0.14

ENV APP_NAME=haproxy \
	APP_EXEC=haproxy \
	APP_USER=haproxy \
	APP_GROUP=haproxy \
	APP_MAJOR=${app_major} \
	APP_VERSION=${app_minor} \
	\
	APP_DEF_DIR=/etc/haproxy \
	APP_CONF_DIR=/srv/conf/haproxy \
	APP_DATA_DIR=/srv/data/haproxy \
	APP_CACHE_DIR=/var/cache/haproxy \
	APP_RUN_DIR=/var/run/haproxy \
	APP_LOG_DIR=/var/log/haproxy
#	PATH=/usr/local/bin:${PATH}

LABEL \
	"Version"="v${APP_MAJOR}" \
	"Description"="Docker image for ${APP_NAME} ${APP_MAJOR} based on Ubuntu 18.04." \
	"Dockerfile"="https://github.com/endial/docker-${APP_NAME}" \
	"Vendor"="Endial Fang (endial@126.com)"

RUN set -eux; \
# 设置程序使用静默安装，而非交互模式；类似tzdata等程序需要使用静默安装
	export DEBIAN_FRONTEND=noninteractive; \
	\
	groupadd -r ${APP_GROUP}; \
	useradd -r -g ${APP_GROUP} -s /usr/sbin/nologin -d /usr/cache/${APP_NAME} ${APP_USER}; \
	\
	mkdir -p ${APP_DEF_DIR} ${APP_CONF_DIR} ${APP_DATA_DIR} ${APP_CACHE_DIR} ${APP_LOG_DIR} ${APP_RUN_DIR}; \
	\
# 更新源，并安装临时使用的软件包（使用完后可删除）
	fetchDeps=" \
# 编译工具
		autoconf \
		automake \
		gcc \
		g++ \
		gcc-multilib \
		make \
		libc6-dev \
		liblua5.3-dev \
		libpcre2-dev \
		libssl-dev \
		zlib1g-dev \
# 下载工具
		ca-certificates \
		wget \
		tzdata \	
	"; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt update; \
	apt install -y --no-install-recommends ${fetchDeps}; \
	\
	wget -O haproxy-${APP_VERSION}.tar.gz https://www.haproxy.org/download/${APP_MAJOR}/src/haproxy-${APP_VERSION}.tar.gz; \
	wget -O haproxy-${APP_VERSION}.tar.gz.sha256 https://www.haproxy.org/download/${APP_MAJOR}/src/haproxy-${APP_VERSION}.tar.gz.sha256; \
	cat "haproxy-${APP_VERSION}.tar.gz.sha256" | sha256sum -c; \
	mkdir -p /usr/src/haproxy; \
	tar -xzf haproxy-${APP_VERSION}.tar.gz -C /usr/src/haproxy --strip-components=1; \
	rm haproxy-${APP_VERSION}.tar.gz haproxy-${APP_VERSION}.tar.gz.sha256; \
	\
	makeOpts=' \
		TARGET=linux-glibc \
		USE_GETADDRINFO=1 \
		USE_LUA=1 LUA_INC=/usr/include/lua5.3 \
		USE_OPENSSL=1 \
		USE_PCRE2=1 \
		USE_PCRE2_JIT=1 \
		USE_ZLIB=1 \
		\
		EXTRA_OBJS=" \
			contrib/prometheus-exporter/service-prometheus.o \
		" \
	'; \
	eval "make -C /usr/src/haproxy -j $(nproc) all $makeOpts"; \
	eval "make -C /usr/src/haproxy install-bin $makeOpts"; \
	\
	mkdir -p /etc/haproxy; \
	cp -R /usr/src/haproxy/examples/errorfiles ${APP_DEF_DIR}/errors; \
	rm -rf /usr/src/haproxy; \
	\
# 为中国区使用重新配置tzdata信息
	ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
	dpkg-reconfigure -f noninteractive tzdata; \
	\
# 设置临时目录的权限信息，设置为777是为了保证后续使用`--user`或`gosu`时，可以更改目录对应的用户属性信息
	chown -Rf ${APP_USER}:${APP_GROUP} ${APP_DEF_DIR} ${APP_CONF_DIR} ${APP_DATA_DIR} ${APP_CACHE_DIR} ${APP_LOG_DIR} ${APP_RUN_DIR}; \
# this 777 will be replaced by 700 or 755 at runtime (allows semi-arbitrary "--user" values)
	chmod 777 ${APP_DEF_DIR} ${APP_CONF_DIR} ${APP_DATA_DIR} ${APP_CACHE_DIR} ${APP_LOG_DIR} ${APP_RUN_DIR}; \
	\
# 查找新安装的应用相应的依赖软件包，并表示为'manual'，防止后续自动清理时被删除
	apt-mark auto '.*' > /dev/null; \
	{ [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; }; \
	find /usr/local/sbin -type f -executable -exec ldd '{}' ';' \
		| awk '/=>/ { print $(NF-1) }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -r apt-mark manual; \
# 删除临时软件包，清理缓存
	apt purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false ${fetchDeps}; \
	apt autoclean -y; \
	rm -rf /var/lib/apt/lists/*;

STOPSIGNAL SIGUSR1

COPY ./entrypoint.sh /usr/local/bin/
COPY ./haproxy.cfg ${APP_DEF_DIR}/

VOLUME ["/srv/conf", "/srv/data", "/var/log", "/var/run"]

# 如果使用gosu启动，必须保证端口在1024之上
EXPOSE 8080

ENTRYPOINT ["entrypoint.sh"]

#   -W  : "master-worker mode" (similar to the old "haproxy-systemd-wrapper"; allows for reload via "SIGUSR2")
#   -db : disables background mode
CMD [ "haproxy", "-W", "-db", "-f", "/srv/conf/haproxy/haproxy.cfg" ]
