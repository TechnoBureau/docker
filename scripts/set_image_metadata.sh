#!/usr/bin/env bash

# Usage: generate_release_report.sh <images_metadata_json> <release_version> <github_token>
metadata=$(jq -r <<< "$1")
RELEASE_VERSION="$2"
GITHUB_TOKEN="$3"

# Initialize release report and header

# Get release ID
RELEASE_ID=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/$GITHUB_REPOSITORY/releases/tags/$RELEASE_VERSION" | jq -r '.id')

# Define asset name
ASSET_NAME=release.json

# Download existing asset (if exists)
ASSET_ID=$(curl -L -s -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/repos/$GITHUB_REPOSITORY/releases/$RELEASE_ID/assets | jq -r '.[] | select(.name == '\"$ASSET_NAME\"') | .id')

if [[ ! -z "$ASSET_ID" ]]; then
  # Download and store existing data
  curl -s -L \
    -H "Accept: application/octet-stream" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/$GITHUB_REPOSITORY/releases/assets/$ASSET_ID > $ASSET_NAME

  existing_data=$(cat $ASSET_NAME)

# Use jq to merge and update report
merged_data=$(echo "$existing_data" "$metadata" | jq -s '.[0] * .[1]')

jq '.' > "$ASSET_NAME" <<< "$merged_data"

#If existing asset exists, delete it
curl -s -L -X DELETE \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/$GITHUB_REPOSITORY/releases/assets/$ASSET_ID > /dev/null

# Upload updated data as new asset
curl -s -L -X POST \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Content-Type: application/vnd.github+json" \
    --data-binary "@$ASSET_NAME" \
    https://uploads.github.com/repos/$GITHUB_REPOSITORY/releases/$RELEASE_ID/assets?name=$ASSET_NAME > /dev/null
fi
exit 0
