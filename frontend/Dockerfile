# Base image: official nginx (stable branch) by default, so the public image keeps its historical
# behaviour (runs as root, ports 80/443, crond + logrotate).
# It can be replaced at build time by any compatible nginx Alpine image, e.g. a hardened one that runs
# as a non-root user with a read-only root filesystem. `./gradlew buildDocker` forwards these build
# arguments from the environment when they are set (unset = defaults below):
#   export WEBUI_NGINX_BASE_IMAGE=<registry>/<nginx-hardened>:<tag>@sha256:<digest>
#   export WEBUI_RUNTIME_USER=101 WEBUI_APK_PACKAGES=
#   ./gradlew buildDocker      # web-ui only: :ui:web-ui:buildDocker (<= 4.10), :frontend:buildDocker (>= 4.11)
#
# Default base: nginx 1.30.7, latest fixed release of the stable branch (= nginx:stable-alpine on 2026-11-22).
# It is the nginx.org security release of 2026-11-18 (1.30.7 stable / 1.31.9 mainline,
# https://nginx.org/en/security_advisories.html), which fixes 10 CVEs, among them:
#   CVE-2026-123007  HTTP/2 flow control memory corruption: remote code execution without authentication,
#                    public exploit (nginx.org "major", CVSS 4.0 9.2 by third parties)
#   CVE-2026-118899  infinite loop while reading a request body over TLS 1.3: denial of service ("major")
#   CVE-2026-123634  use-after-free in the resolver: reachable with the OperatorFabric configuration, which
#                    uses `resolver` and `proxy_pass $variable`
# The previous base, nginx 1.29.1, belongs to an end-of-life branch that receives no fix at all.
# Keep the digest pinned and update it with each nginx security release of the stable branch.
ARG WEBUI_NGINX_BASE_IMAGE=nginx:1.30.7-alpine@sha256:caf4e1e032a20f9c3c5e28fc7f25ffd768ad8677b4975c54193075997b3a97e3
FROM ${WEBUI_NGINX_BASE_IMAGE}

# User running nginx: root (default, historical behaviour) or 101 (user "nginx" of the official image)
ARG WEBUI_RUNTIME_USER=root
# Extra Alpine packages: bash + logrotate are only useful when running as root (crond rotates /var/log/nginx)
ARG WEBUI_APK_PACKAGES="bash logrotate"

# The base image may run as a non-root user: install as root, then switch to WEBUI_RUNTIME_USER
USER root
VOLUME /tmp
# image-filter: unused dynamic module deleted for security reason (may already be removed by the base image)
RUN if [ -n "$WEBUI_APK_PACKAGES" ]; then apk --no-cache add $WEBUI_APK_PACKAGES; fi \
    && if apk info -e nginx-module-image-filter >/dev/null 2>&1; then apk del --no-cache nginx-module-image-filter; fi
COPY build/distribution/browser /usr/share/nginx/html/
COPY nginx/start-webui.sh /
COPY nginx/nginx-logrotate-conf /etc/logrotate.d/nginx
USER ${WEBUI_RUNTIME_USER}
CMD ["/bin/sh", "/start-webui.sh"]
