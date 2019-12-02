ARG     NGINX_TAG=1.17-alpine
FROM    nginx:${NGINX_TAG} AS builder
ARG     HTTP_PROXY
ARG     HTTPS_PROXY

#       NGINX_VERSION                 from nginx:alpine
ENV     NGINX_HEADERS_MORE_VERSION    0.33
ENV     NGINX_HTTP_AUTH_PAM_VERSION   1.5.1
ENV     NGINX_DEV_KIT_VERSION         0.3.1
ENV     NGINX_AUTH_LDAP_VERSION       0.1
ENV     NGINX_NAXSI_VERSION           0.56
ENV     NGINX_LUA_JIT_VERSION         2.1-20190912
ENV     NGINX_LUA_VERSION             0.10.15
ENV     NGINX_LUA_RUSTY_CORE          0.1.17
ENV     NGINX_LUA_LRUCACHE            0.09
ENV     NGINX_ECHO_VERSION            0.61
ENV     NGINX_FANCYINDEX_VERSION      0.4.3
ENV     NGINX_SUBS_FILTER_VERSION     0.6.4
ENV     NGINX_CACHE_PURGE_VERSION     2.3
ENV     NGINX_PUSH_STREAM_VERSION     0.5.4
ENV     NGINX_RTMP_VERSION            1.2.1
ENV     NGINX_UPLOAD_PROGRESS_VERSION 0.9.2
ENV     NGINX_DAV_EXT_VERSION         3.0.0
ENV     NGINX_BROTLI_COMMIT           e505dce68acc190cc5a1e780a3b0275e39f160ca
ENV     NGINX_GEOIP2_VERSION          3.3


ADD     https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz /tmp/nginx.tar.gz
ADD     https://github.com/openresty/headers-more-nginx-module/archive/v${NGINX_HEADERS_MORE_VERSION}.tar.gz /tmp/headers-more-nginx-module.tar.gz
ADD     https://github.com/sto/ngx_http_auth_pam_module/archive/v${NGINX_HTTP_AUTH_PAM_VERSION}.tar.gz /tmp/ngx_http_auth_pam_module.tar.gz
ADD     https://github.com/simplresty/ngx_devel_kit/archive/v${NGINX_DEV_KIT_VERSION}.tar.gz /tmp/ngx_devel_kit.tar.gz
ADD     https://github.com/kvspb/nginx-auth-ldap/archive/v${NGINX_AUTH_LDAP_VERSION}.tar.gz /tmp/nginx-auth-ldap.tar.gz
ADD     https://github.com/nbs-system/naxsi/archive/${NGINX_NAXSI_VERSION}.tar.gz /tmp/naxsi.tar.gz
ADD     https://github.com/openresty/lua-nginx-module/archive/v${NGINX_LUA_VERSION}.tar.gz /tmp/lua-nginx-module.tar.gz
ADD     https://github.com/openresty/luajit2/archive/v${NGINX_LUA_JIT_VERSION}.tar.gz /tmp/luajit2.tar.gz
ADD     https://github.com/openresty/echo-nginx-module/archive/v${NGINX_ECHO_VERSION}.tar.gz /tmp/echo-nginx-module.tar.gz
ADD     https://github.com/aperezdc/ngx-fancyindex/archive/v${NGINX_FANCYINDEX_VERSION}.tar.gz /tmp/ngx-fancyindex.tar.gz
ADD     https://github.com/yaoweibin/ngx_http_substitutions_filter_module/archive/v${NGINX_SUBS_FILTER_VERSION}.tar.gz /tmp/ngx_http_substitutions_filter_module.tar.gz
ADD     https://github.com/FRiCKLE/ngx_cache_purge/archive/${NGINX_CACHE_PURGE_VERSION}.tar.gz /tmp/ngx_cache_purge.tar.gz
ADD     https://github.com/wandenberg/nginx-push-stream-module/archive/${NGINX_PUSH_STREAM_VERSION}.tar.gz /tmp/nginx-push-stream-module.tar.gz
ADD     https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_VERSION}.tar.gz /tmp/nginx-rtmp-module.tar.gz
ADD     https://github.com/masterzen/nginx-upload-progress-module/archive/v${NGINX_UPLOAD_PROGRESS_VERSION}.tar.gz /tmp/nginx-upload-progress-module.tar.gz
ADD     https://github.com/arut/nginx-dav-ext-module/archive/v${NGINX_DAV_EXT_VERSION}.tar.gz /tmp/nginx-dav-ext-module.tar.gz
ADD     https://github.com/openresty/lua-resty-core/archive/v${NGINX_LUA_RUSTY_CORE}.tar.gz /tmp/lua-resty-core.tar.gz
ADD     https://github.com/openresty/lua-resty-lrucache/archive/v${NGINX_LUA_LRUCACHE}.tar.gz /tmp/lua-resty-lrucache.tar.gz
ADD     https://github.com/leev/ngx_http_geoip2_module/archive/${NGINX_GEOIP2_VERSION}.tar.gz /tmp/ngx_http_geoip2_module.tar.gz

RUN     \
        mkdir -p /usr/src \
        && find /tmp/ -name '*.tar.gz' -exec tar -C /usr/src -xzvf '{}' \; \
        && \
        if [ ! -z "$HTTP_PROXY" ]; then \
            export http_proxy=${HTTP_PROXY}; \
        fi \
        && \
        if [ ! -z "$HTTPS_PROXY" ]; then \
            export https_proxy=${HTTPS_PROXY}; \
        fi \
        && apk add --no-cache --virtual .build-deps \
        gcc \
        libc-dev \
        make \
        openssl-dev \
        pcre-dev \
        zlib-dev \
        libtool \
        linux-headers \
        libxslt-dev \
        gd-dev \
        geoip-dev \
        git \
        perl-dev \
        linux-pam-dev \
        libedit-dev \
        mercurial \
        bash \
        alpine-sdk \
        openldap-dev \
        findutils \
        libmaxminddb-dev \
        \
        # luajit2
        && cd /usr/src/luajit2-${NGINX_LUA_JIT_VERSION} \
        && make \
        && make install \
        \
        # brotli
        && \
        if [ -z "$HTTPS_PROXY" ]; then \
            git config --global http.proxy ${HTTPS_PROXY}; \
            git config --global http.sslVerify false; \
        fi \
        && cd /usr/src \
        && git clone --recursive https://github.com/google/ngx_brotli.git \
        && cd /usr/src/ngx_brotli \
        && git checkout -b $NGINX_BROTLI_COMMIT \
        \
        # Build Nginx - Use the same nginx:alpine build arguments to build ours
        && CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
        && CONFARGS=${CONFARGS/-Os -fomit-frame-pointer/-Wimplicit-fallthrough=0} \
        && CONFARGS=${CONFARGS/-Wl,/-Wl,-rpath,\/usr\/local\/lib,} \
        && export LUAJIT_LIB=/usr/local/lib \
        && export LUAJIT_INC=/usr/local/include/luajit-2.1 \
        && cd /usr/src/nginx-$NGINX_VERSION \
        && ./configure --with-compat $CONFARGS \
        --add-module=/usr/src/echo-nginx-module-${NGINX_ECHO_VERSION} \
        --add-module=/usr/src/naxsi-${NGINX_NAXSI_VERSION}/naxsi_src \
        --add-module=/usr/src/headers-more-nginx-module-${NGINX_HEADERS_MORE_VERSION} \
        --add-module=/usr/src/nginx-auth-ldap-${NGINX_AUTH_LDAP_VERSION} \
        --add-module=/usr/src/nginx-dav-ext-module-${NGINX_DAV_EXT_VERSION} \
        --add-module=/usr/src/nginx-push-stream-module-${NGINX_PUSH_STREAM_VERSION} \
        --add-module=/usr/src/nginx-rtmp-module-${NGINX_RTMP_VERSION} \
        --add-module=/usr/src/nginx-upload-progress-module-${NGINX_UPLOAD_PROGRESS_VERSION} \
        --add-module=/usr/src/ngx_brotli \
        --add-module=/usr/src/ngx_cache_purge-${NGINX_CACHE_PURGE_VERSION} \
        --add-module=/usr/src/ngx-fancyindex-${NGINX_FANCYINDEX_VERSION} \
        --add-module=/usr/src/ngx_http_geoip2_module-${NGINX_GEOIP2_VERSION} \
        --add-module=/usr/src/ngx_http_substitutions_filter_module-${NGINX_SUBS_FILTER_VERSION} \
        --add-module=/usr/src/lua-nginx-module-${NGINX_LUA_VERSION} \
        --add-module=/usr/src/ngx_http_auth_pam_module-${NGINX_HTTP_AUTH_PAM_VERSION} \
        --add-module=/usr/src/ngx_devel_kit-${NGINX_DEV_KIT_VERSION} \
        && make \
        && make install \
        && strip /usr/sbin/nginx* \
        && strip /usr/lib/nginx/modules/*.so \
        && rm -f /usr/lib/nginx/modules/*-debug.so \
        && cp -R /usr/src/lua-resty-lrucache-${NGINX_LUA_LRUCACHE}/* /usr/src/lua-resty-core-${NGINX_LUA_RUSTY_CORE}/ \
        && mv /usr/src/lua-resty-core-${NGINX_LUA_RUSTY_CORE} /usr/local/lua-resty-core \
        && apk del .build-deps \
        && rm -rf \
        /usr/src/* \
        /var/cache/apk/* \
        /tmp/*

FROM    nginx:${NGINX_TAG}
ARG     HTTP_PROXY
ARG     HTTPS_PROXY

ARG     BUILD_DATE
ARG     VCS_REF
ARG     BUILD_VERSION

ARG     S6_OVERLAY_VERSION="v1.22.1.0"
ARG     S6_OVERLAY_ARCH="amd64"
ADD     https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.gz /tmp/s6-overlay.tar.gz
ENV     S6_BEHAVIOUR_IF_STAGE2_FAILS=2

COPY    --from=builder /usr/lib/nginx/modules/ /usr/lib/nginx/modules/
COPY    --from=builder /usr/sbin/nginx /usr/sbin/
COPY    --from=builder /usr/local/lib/ /usr/local/lib/
COPY    --from=builder /usr/local/lua-resty-core/ /usr/local/lua-resty-core/
COPY    root /

RUN     \
        if [ ! -z "$HTTP_PROXY" ]; then \
            export http_proxy=${HTTP_PROXY}; \
        fi \
        && \
        if [ ! -z "$HTTPS_PROXY" ]; then \
            export https_proxy=${HTTPS_PROXY}; \
        fi \
        && apk add --no-cache \
        dnsmasq \
        libgcc \
        libldap \
        libmaxminddb \
        libxml2 \
        libxslt \
        procps \
        shadow \
        && (getent passwd xfs > /dev/null 2>&1 && userdel -f xfs || true) \
        && (getent group xfs > /dev/null 2>&1 && groupdel -f xfs || true) \
        && (getent group www-data > /dev/null 2>&1 && true || addgroup -g 1000 -S www-data) \
        && adduser -S -D -H -u 1000 -h /var/www -s /sbin/nologin -G www-data -g www-data www-data \
        && tar xvfz /tmp/s6-overlay.tar.gz -C / \
        && mkdir -p \
      	/defaults \
        && rm -rf \
        /var/cache/apk/* \
        /tmp/* \
        && rm -f /usr/lib/nginx/modules/*-debug.so \
        /usr/sbin/nginx-debug

EXPOSE 80 443
ENTRYPOINT [ "/init" ]
CMD []
VOLUME [ "/etc/nginx" ]
