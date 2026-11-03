FROM nginx:1.31.7-alpine3.24@sha256:892bb2152464f0c5d8972593a5f5afaf8054552580b699d95f8ff4af08c2d33d
VOLUME /tmp
RUN apk upgrade --no-cache && apk --no-cache add bash logrotate \
    && apk del nginx-module-image-filter nginx-module-xslt nginx-module-njs
    # deleted unused lib for security reason 
COPY build/distribution/browser /usr/share/nginx/html/
COPY nginx/start-webui.sh /
COPY nginx/nginx-logrotate-conf /etc/logrotate.d/nginx
CMD ["/bin/sh", "/start-webui.sh"]
