# syntax=docker/dockerfile:1.7
# The frontend is plain static files, so there is no build stage: the image is
# just a small, unprivileged nginx (runs as uid 101 and listens on 8080).
FROM nginxinc/nginx-unprivileged:stable-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY public/ /usr/share/nginx/html/

# The root filesystem is read-only in ECS, so nginx writes its pid and temp
# files to a task volume mounted at /tmp. Fargate bind mounts are root-owned
# unless the image declares the path as a VOLUME, in which case they inherit
# the image directory's owner and mode - so make it owned by nginx.
USER root
RUN chown 101:101 /tmp && chmod 1777 /tmp
VOLUME ["/tmp"]

USER 101
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/healthz || exit 1
