#!/bin/bash
# Copyright VMware, Inc.
# SPDX-License-Identifier: APACHE-2.0

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load libraries
. /opt/technobureau/scripts/libtechnobureau.sh
. /opt/technobureau/scripts/libnginx.sh

# Load NGINX environment variables
. /opt/technobureau/scripts/nginx-env.sh

print_welcome_page

if [[ "$1" = "/opt/technobureau/scripts/nginx/run.sh" ]]; then
    info "** Starting NGINX setup **"
    /opt/technobureau/scripts/nginx/setup.sh
    info "** NGINX setup finished! **"
fi

echo ""
exec "$@"
