
FROM registry.access.redhat.com/ubi9/ubi-minimal

ENV HOME="/opt/technobureau" \
    OS_FLAVOUR="ubi-9" \
    OS_NAME="linux"

COPY prebuildfs /
SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]
# Install required system packages and dependencies
RUN install_packages_chroot coreutils-single glibc-minimal-langpack
RUN curl -L https://download.opensuse.org/repositories/home:/ganapathi/UBI9/home:ganapathi.repo -o /etc/yum.repos.d/technobureau.repo

WORKDIR ${HOME}
USER 1001
ENTRYPOINT ["/bin/bash"]
