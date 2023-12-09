#!/usr/bin/env bash

# Usage: generate_release_report.sh <release_version> <github_token>
RELEASE_VERSION="$1"
GITHUB_TOKEN="$2"

# Initialize release report and header
RELEASE_REPORT="#  Released Packages $RELEASE_VERSION \n"
RELEASE_REPORT+="|  Package | Image Tag | SHA | Created Date |\n"
RELEASE_REPORT+="| :-: | :-: | :-: | :-: |"

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

# Update release body on GitHub
curl -s -X PATCH -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" -d '{"body": "'"$RELEASE_REPORT"'"}' "https://api.github.com/repos/$GITHUB_REPOSITORY/releases/$RELEASE_ID" > /dev/null

fi
exit 0
