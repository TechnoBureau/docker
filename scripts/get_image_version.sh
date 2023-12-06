#!/bin/bash

json_data="$1"
image_name="$2"

# Extract the VERSION from the JSON data
VERSION=$(jq -r ".[].${image_name}.version" <<< "$json_data")
echo "VERSION=${VERSION}"
