#!/usr/bin/env bash

# Usage: generate_release_report.sh <images_json> <images_metadata_json> <release_version> <github_token>

images=($(echo "$1" | jq -r '.[]'))
JSON_DATA="$2"
RELEASE_VERSION="$3"
GITHUB_TOKEN="$4"
RELEASE_REPORT="# 🚀 Released Packages $RELEASE_VERSION 🚀\n"
RELEASE_REPORT+="| 📦 Package | Image Tag | SHA | Created Date |\n"
RELEASE_REPORT+="| :-: | :-: | :-: | :-: |"
echo "DEBUG: Metadata : $JSON_DATA"

for image in "${images[@]}"; do
  BUILD_TAG=$(echo "$JSON_DATA" | jq -r ".[\"${image}\"].BUILD_TAG")
  IMAGE_ID=$(echo "$JSON_DATA" | jq -r ".[\"${image}\"].IMAGE_ID")
  CREATED=$(echo "$JSON_DATA" | jq -r ".[\"${image}\"].CREATED")
  RELEASE_REPORT+="\n|$image|${BUILD_TAG}|${IMAGE_ID}|${CREATED}|"
done

echo -e "$RELEASE_REPORT" >> $GITHUB_STEP_SUMMARY
echo -e "\n" >> $GITHUB_STEP_SUMMARY

RELEASE_ID=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/$GITHUB_REPOSITORY/releases/tags/$RELEASE_VERSION" | jq -r '.id')
echo "RELEASE_ID=${RELEASE_ID}" >> $GITHUB_ENV

curl -X PATCH -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" -d '{"body": "'"$RELEASE_REPORT"'"}' "https://api.github.com/repos/$GITHUB_REPOSITORY/releases/$RELEASE_ID"
