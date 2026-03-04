ARG BUILD_FROM
FROM $BUILD_FROM

RUN apk add --no-cache \
  nginx \
  git \
  bash \
  jq \
  python3

COPY rootfs/ /

RUN chmod +x /run.sh /usr/local/bin/updater.sh /usr/local/bin/webhook_server.py \
  && mkdir -p /data/site /data/repo /run/nginx

EXPOSE 8099 8098

ENTRYPOINT ["/init"]
CMD ["/run.sh"]