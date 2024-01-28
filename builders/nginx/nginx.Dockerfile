# Copyright VMware, Inc.
# SPDX-License-Identifier: APACHE-2.0
ARG ubi9=registry.access.redhat.com/ubi9/ubi-minimal
ARG baseruntime=${ubi9}
ARG VERSION=1.24.0

FROM ${baseruntime} AS runtime

ENV HOME="/" \
    OS_FLAVOUR="ubi-9" \
    OS_NAME="linux"
ENV OS_ARCH=amd64
COPY prebuildfs /
SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]
# Install required system packages and dependencies
RUN install_packages ca-certificates curl-minimal openssl procps tar findutils
RUN curl -L https://download.opensuse.org/repositories/home:/ganapathi/UBI9/home:ganapathi.repo -o /etc/yum.repos.d/technobureau.repo
RUN install_packages nginx-core nginx-mod-headers-more nginx-mod-http-sticky nginx-mod-http-geoip2 nginx-mod-http-vts


COPY nginx/rootfs /
RUN /opt/technobureau/scripts/nginx/postunpack.sh
ENV APP_VERSION="1.24.0" \
    TECHNOBUREAU_APP_NAME="nginx" \
    NGINX_HTTPS_PORT_NUMBER="8443" \
    NGINX_HTTP_PORT_NUMBER="8080" \
    PATH="/opt/technobureau/common/bin:/opt/technobureau/nginx/bin:/opt/technobureau/scripts/nginx/:/opt/nginx/bin:$PATH"

EXPOSE 8080 8443

HEALTHCHECK CMD curl --fail http://localhost:8080/status/ || exit 1

WORKDIR /opt/technobureau
USER 1001
ENV HOME="/opt/technobureau"
ENTRYPOINT [ "/opt/technobureau/scripts/nginx/entrypoint.sh" ]
CMD [ "/opt/technobureau/scripts/nginx/run.sh" ]
