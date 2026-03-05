ARG BUILD_FROM
FROM $BUILD_FROM

RUN apk add --no-cache \
  nginx \
  git \
  bash \
  jq

COPY rootfs/ /

RUN chmod +x /run.sh /usr/local/bin/updater.sh \
  && mkdir -p /data/site /data/repo /run/nginx

EXPOSE 8099

ENTRYPOINT ["/init"]
CMD ["/run.sh"]