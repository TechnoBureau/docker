#!/bin/bash
# Copyright VMware, Inc.
# SPDX-License-Identifier: APACHE-2.0
#
# Technobureau custom library

# shellcheck disable=SC1091

# Load Generic Libraries
. /opt/technobureau/scripts/liblog.sh

# Constants
BOLD='\033[1m'

# Functions

########################
# Print the welcome page
# Globals:
#   DISABLE_WELCOME_MESSAGE
#   TECHNOBUREAU_APP_NAME
# Arguments:
#   None
# Returns:
#   None
#########################
print_welcome_page() {
    if [[ -z "${DISABLE_WELCOME_MESSAGE:-}" ]]; then
        if [[ -n "$TECHNOBUREAU_APP_NAME" ]]; then
            print_image_welcome_page
        fi
    fi
}

########################
# Print the welcome page for a Technobureau Docker image
# Globals:
#   TECHNOBUREAU_APP_NAME
# Arguments:
#   None
# Returns:
#   None
#########################
print_image_welcome_page() {
    local github_url="https://github.com/TechnoBureau/dockers"

    info ""
    info "${BOLD}Welcome to the Technobureau ${TECHNOBUREAU_APP_NAME} container${RESET}"
    info "Subscribe to project updates by watching ${BOLD}${github_url}${RESET}"
    info "Submit issues and feature requests at ${BOLD}${github_url}/issues${RESET}"
    info ""
}

