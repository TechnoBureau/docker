FROM registry.access.redhat.com/ubi9/ubi AS builder

COPY *.sh docker.yaml /tmp/
RUN chmod +rx /tmp/*.sh
RUN bash /tmp/install.sh && rm -rf /tmp/*

FROM scratch

ARG BUILD_DATE
ARG BUILD_VERSION

COPY --from=builder /mnt/rootfs/ /

ENV SAG_HOME /opt/technobureau

COPY --from=builder --chown=1724:0 ${SAG_HOME}/ ${SAG_HOME}/

ENV LANG=en_US.UTF8 \
    LC_ALL=en_US.UTF8
    
USER 1724
WORKDIR ${SAG_HOME}

ENV PATH=/opt/technobureau:/opt/technobureau/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

CMD ["/bin/bash"]

LABEL maintainer="TechnoBureau" \
      name="TechnoBureau/ubi" \
      version="9" \
      summary="ubi9 micro image" \
      description="Very small image which doesn't install the package manager." \
      io.k8s.display-name="Ubi9-micro" \
      com.technobureau.component="ubi9-micro-container" \
      com.technobureau.build-date=${BUILD_DATE} \
      com.technobureau.version=${BUILD_VERSION}
