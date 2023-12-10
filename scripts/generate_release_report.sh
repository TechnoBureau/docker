#!/usr/bin/env bash

# Usage: generate_release_report.sh <release_version> <github_token>
source "$(dirname "${BASH_SOURCE[0]}")/common_libs.sh"

RELEASE_VERSION="$1"
GITHUB_TOKEN="$2"

# Initialize release report and header
RELEASE_REPORT="#  Released Packages $RELEASE_VERSION \n"
RELEASE_REPORT+="|  Package | Image Tag | SHA | Created Date |\n"
RELEASE_REPORT+="| :-: | :-: | :-: | :-: |"

# Get release ID
RELEASE_ID=$(get_release_id "$RELEASE_VERSION" "$GITHUB_TOKEN")

# Define asset name
ASSET_NAME=release.json

download_asset "$RELEASE_ID" "$GITHUB_TOKEN" "$ASSET_NAME"

# Loop through image data and update report
for image in $(jq -r 'keys[]' < $ASSET_NAME); do
  # Extract image details
  BUILD_TAG=$(jq -r ".[\"$image\"].BUILD_TAG" < $ASSET_NAME)
  IMAGE_ID=$(jq -r ".[\"$image\"].IMAGE_ID" < $ASSET_NAME)
  CREATED=$(jq -r ".[\"$image\"].CREATED" < $ASSET_NAME)

  # Update report with extracted details
  RELEASE_REPORT+="\n|$image|$BUILD_TAG|$IMAGE_ID|$CREATED|"
done

# Print final release report
echo -e "$RELEASE_REPORT"
echo -e "\n"

update_release_notes "$RELEASE_ID" "$GITHUB_TOKEN" "$RELEASE_REPORT"

exit 0
