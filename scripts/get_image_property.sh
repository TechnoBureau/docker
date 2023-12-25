#!/bin/bash
set -x
source "$(dirname "${BASH_SOURCE[0]}")/common_libs.sh"

json_data="$1"
image_name="$2"
property="$3"
$prefix="$4"

get_property "$json_data" "$image_name" "$property" "$prefix"
