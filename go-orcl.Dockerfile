FROM registry.access.redhat.com/ubi9/ubi AS builder

COPY *.sh docker.yaml go-orcl libs/oracle /tmp/
RUN chmod +rx /tmp/*.sh
RUN bash /tmp/install.sh && rm -rf /tmp/*

FROM scratch

COPY --from=builder /mnt/rootfs/ /

ENV HOME /opt/technobureau

COPY --from=builder --chown=1724:0 ${HOME}/ ${HOME}/

ENV LANG=en_US.UTF8 \
    LC_ALL=en_US.UTF8

USER 1724
WORKDIR ${HOME}

ENV PATH=/opt/technobureau:/opt/technobureau/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ENV GIN_MODE=release

ENV LD_LIBRARY_PATH=/opt/technobureau/oracle/lib:$LD_LIBRARY_PATH
ENV TNS_ADMIN=/opt/technobureau/oracle/lib/network/admin

EXPOSE 8080

ENTRYPOINT entrypoint.sh