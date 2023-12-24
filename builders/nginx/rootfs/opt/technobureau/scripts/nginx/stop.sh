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
. /opt/technobureau/scripts/libos.sh
. /opt/technobureau/scripts/liblog.sh

# Load NGINX environment variables
. /opt/technobureau/scripts/nginx-env.sh

error_code=0

if is_nginx_running; then
    TECHNOBUREAU_QUIET=1 nginx_stop
    if ! retry_while "is_nginx_not_running"; then
        error "nginx could not be stopped"
        error_code=1
    else
        info "nginx stopped"
    fi
else
    info "nginx is not running"
fi

exit "$error_code"
