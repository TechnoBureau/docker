#!/usr/bin/env bash

# Usage: generate_release_report.sh <images_metadata_json> <release_version> <github_token>
source "$(dirname "${BASH_SOURCE[0]}")/common_libs.sh"

metadata=$(jq -r <<< "$1")
RELEASE_VERSION="$2"
GITHUB_TOKEN="$3"

# Initialize release report and header

# Get release ID
RELEASE_ID=$(get_release_id "$RELEASE_VERSION" "$GITHUB_TOKEN")

# Define asset name
ASSET_NAME=release.json

download_asset "$RELEASE_ID" "$GITHUB_TOKEN" "$ASSET_NAME" "true"

existing_data=$(cat $ASSET_NAME)

# Use jq to merge and update report
merged_data=$(echo "$existing_data" "$metadata" | jq -s '.[0] * .[1]')

if [ $? -eq 0 ]; then
jq '.' > "$ASSET_NAME" <<< "$merged_data"

upload_asset "$RELEASE_ID" "$GITHUB_TOKEN" "$ASSET_NAME"
fi
