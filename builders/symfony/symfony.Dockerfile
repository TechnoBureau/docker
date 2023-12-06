ARG basebuilder=registry.access.redhat.com/ubi9/ubi
ARG baseruntime=scratch
ARG VERSION=6.3.x

FROM ${basebuilder} AS builder

COPY scripts/*.sh docker.yaml symfony /tmp/
RUN chmod +rx /tmp/*.sh
RUN bash /tmp/install.sh && rm -rf /tmp/*

FROM ${baseruntime} AS runtime

COPY --from=builder /mnt/rootfs/ /

ENV HOME /opt/technobureau

COPY --from=builder --chown=1724:0 ${HOME}/ ${HOME}/

ENV LANG=en_US.UTF8 \
    LC_ALL=en_US.UTF8

USER 1724
WORKDIR ${HOME}

# Allow to use development versions of Symfony
ARG STABILITY="stable"
ENV STABILITY ${STABILITY}
ENV PHP_VERSION=8.1
# Allow to select Symfony version
ARG SYMFONY_VERSION="6.3.*"
ENV SYMFONY_VERSION ${SYMFONY_VERSION}

ENV APP_ENV=prod

ENV PATH=/opt/technobureau:/opt/technobureau/bin:/opt/technobureau/app/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

STOPSIGNAL SIGQUIT

ENTRYPOINT ["entrypoint.sh"]
CMD ["php-fpm"]

EXPOSE 8000

LABEL org.opencontainers.image.authors="ganapathi.rj@gmail.com"