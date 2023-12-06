ARG basebuilder=registry.access.redhat.com/ubi9/ubi
ARG baseruntime=scratch
ARG VERSION=3.9.x

FROM ${basebuilder} AS builder

COPY scripts/*.sh docker.yaml python /tmp/
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

ENV PATH=/opt/technobureau:/opt/technobureau/bin:/opt/technobureau/.venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ENV PYTHONPATH=/opt/technobureau/.venv/lib/python3.9

EXPOSE 8000

CMD /bin/bash