#!/bin/bash
# Copyright VMware, Inc.
# SPDX-License-Identifier: APACHE-2.0

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load libraries
. /opt/technobureau/scripts/libnginx.sh
. /opt/technobureau/scripts/liblog.sh

# Load NGINX environment
. /opt/technobureau/scripts/nginx-env.sh

info "** Reloading NGINX configuration **"
exec "${NGINX_SBIN_DIR}/nginx" -s reload
