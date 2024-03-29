#!/bin/bash
# Copyright VMware, Inc.
# SPDX-License-Identifier: APACHE-2.0
#
# Environment configuration for nginx

# The values for all environment variables will be set in the below order of precedence
# 1. Custom environment variables defined below after Technobureau defaults
# 2. Constants defined in this file (environment variables with no default), i.e. TECHNOBUREAU_ROOT_DIR
# 3. Environment variables overridden via external files using *_FILE variables (see below)
# 4. Environment variables set externally (i.e. current Bash context/Dockerfile/userdata)

# Load logging library
# shellcheck disable=SC1090,SC1091
. /opt/technobureau/scripts/liblog.sh

export TECHNOBUREAU_ROOT_DIR="/opt/technobureau"
export NGINX_ROOT_DIR="/opt/nginx"
export TECHNOBUREAU_VOLUME_DIR="/opt/technobureau/app"

# Logging configuration
export MODULE="${MODULE:-nginx}"
export TECHNOBUREAU_DEBUG="${TECHNOBUREAU_DEBUG:-false}"

# By setting an environment variable matching *_FILE to a file path, the prefixed environment
# variable will be overridden with the value specified in that file
nginx_env_vars=(
    NGINX_HTTP_PORT_NUMBER
    NGINX_HTTPS_PORT_NUMBER
    NGINX_SKIP_SAMPLE_CERTS
    NGINX_ENABLE_ABSOLUTE_REDIRECT
    NGINX_ENABLE_PORT_IN_REDIRECT
)
for env_var in "${nginx_env_vars[@]}"; do
    file_env_var="${env_var}_FILE"
    if [[ -n "${!file_env_var:-}" ]]; then
        if [[ -r "${!file_env_var:-}" ]]; then
            export "${env_var}=$(< "${!file_env_var}")"
            unset "${file_env_var}"
        else
            warn "Skipping export of '${env_var}'. '${!file_env_var:-}' is not readable."
        fi
    fi
done
unset nginx_env_vars
export WEB_SERVER_TYPE="nginx"

# Paths
export NGINX_BASE_DIR="${TECHNOBUREAU_ROOT_DIR}/nginx"
export NGINX_VOLUME_DIR="${TECHNOBUREAU_VOLUME_DIR}/nginx"
export NGINX_SBIN_DIR="${NGINX_SBIN_DIR:-${NGINX_ROOT_DIR}/bin}"
export NGINX_CONF_DIR="${NGINX_BASE_DIR}/conf"
export NGINX_HTDOCS_DIR="${NGINX_BASE_DIR}/html"
export NGINX_TMP_DIR="${NGINX_BASE_DIR}/tmp"
export NGINX_LOGS_DIR="${NGINX_BASE_DIR}/logs"
export NGINX_SERVER_BLOCKS_DIR="${NGINX_CONF_DIR}/server_blocks"
export NGINX_INITSCRIPTS_DIR="${TECHNOBUREAU_ROOT_DIR}/docker-entrypoint-initdb.d"
export NGINX_CONF_FILE="${NGINX_CONF_DIR}/nginx.conf"
export NGINX_PID_FILE="${NGINX_TMP_DIR}/nginx.pid"
export PATH="${NGINX_SBIN_DIR}:${TECHNOBUREAU_ROOT_DIR}/common/bin:${PATH}"

# System users (when running with a privileged user)
export NGINX_DAEMON_USER="daemon"
export WEB_SERVER_DAEMON_USER="$NGINX_DAEMON_USER"
export NGINX_DAEMON_GROUP="daemon"
export WEB_SERVER_DAEMON_GROUP="$NGINX_DAEMON_GROUP"
export NGINX_DEFAULT_HTTP_PORT_NUMBER="8080"
export WEB_SERVER_DEFAULT_HTTP_PORT_NUMBER="$NGINX_DEFAULT_HTTP_PORT_NUMBER" # only used at build time
export NGINX_DEFAULT_HTTPS_PORT_NUMBER="8443"
export WEB_SERVER_DEFAULT_HTTPS_PORT_NUMBER="$NGINX_DEFAULT_HTTPS_PORT_NUMBER" # only used at build time

# NGINX configuration
export NGINX_HTTP_PORT_NUMBER="${NGINX_HTTP_PORT_NUMBER:-}"
export WEB_SERVER_HTTP_PORT_NUMBER="$NGINX_HTTP_PORT_NUMBER"
export NGINX_HTTPS_PORT_NUMBER="${NGINX_HTTPS_PORT_NUMBER:-}"
export WEB_SERVER_HTTPS_PORT_NUMBER="$NGINX_HTTPS_PORT_NUMBER"
export NGINX_SKIP_SAMPLE_CERTS="${NGINX_SKIP_SAMPLE_CERTS:-false}"
export NGINX_ENABLE_ABSOLUTE_REDIRECT="${NGINX_ENABLE_ABSOLUTE_REDIRECT:-no}"
export NGINX_ENABLE_PORT_IN_REDIRECT="${NGINX_ENABLE_PORT_IN_REDIRECT:-no}"

# Custom environment variables may be defined below
