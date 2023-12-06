ARG basebuilder=registry.access.redhat.com/ubi9/ubi
ARG baseruntime=scratch
ARG VERSION=4.1.6

FROM ${basebuilder} AS builder

COPY scripts/*.sh docker.yaml django-admin libs/oracle /tmp/
RUN chmod +rx /tmp/*.sh
RUN bash /tmp/install.sh && rm -rf /tmp/*

FROM ${baseruntime} AS runtime

COPY --from=builder /mnt/rootfs/ /

ENV HOME /opt/technobureau

COPY --from=builder --chown=1724:0 ${HOME}/ ${HOME}/

ENV LANG=en_US.UTF8 \
    LC_ALL=en_US.UTF8

ENV SECRET_KEY=technobureau

USER 1724
WORKDIR ${HOME}

ENV PATH=/opt/technobureau:/opt/technobureau/bin:/opt/technobureau/.venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ENV PYTHONPATH=/opt/technobureau/.venv/lib/python3.9 \
    PYTHONUNBUFFERED=1

EXPOSE 8000

#change to `worker` to run the docker as worker instead of app.
ENV app=web

#Disable Debug on production. Also Django won't service static file while debug is false,
#so enable true on development setup to serve static files
ENV DEBUG=false

ENV LOG_LEVEL=info app_name=config
ENV DJANGO_SUPERUSER_USERNAME=admin DJANGO_SUPERUSER_EMAIL=admin@example.com DJANGO_SUPERUSER_PASSWORD=password
ENV ORACLE_USER=ADMIN ORACLE_PASSWORD= ORACLE_DB=

ENV REDIS_URL=redis://redis:6379/0

ENV LD_LIBRARY_PATH=/opt/technobureau/oracle/lib:$LD_LIBRARY_PATH
ENV TNS_ADMIN=/opt/technobureau/oracle/lib/network/admin

ENTRYPOINT entrypoint.sh