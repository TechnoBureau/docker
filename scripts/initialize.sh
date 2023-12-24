#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common_libs.sh"

GITHUB_REF=$1
GITHUB_TOKEN=$2
INPUT_VERSION=$3
IMAGES=$4
ASSET_NAME=release.json
cd "$(dirname "${BASH_SOURCE[0]}")/../builders" || exit 1

get_version() {
  if [[ -n "$INPUT_VERSION" ]]; then
    echo "$INPUT_VERSION"
  elif [[ "$GITHUB_REF" = "refs/heads/main" ]]; then
    echo "${MAJOR:-1}.${MINOR:-0}.${FIX:-0}"
  elif [[ "$GITHUB_REF" =~ "refs/tags/" ]]; then
    echo "${GITHUB_REF##refs/tags/}" | sed 's/^v//'
  else
    echo "${GITHUB_REF##refs/heads/}"
  fi
}

GENERAL_VERSION=$(get_version)

images_metadata=""
if [ -z "$IMAGES" ] || [ "$IMAGES" = "*" ]; then
    # If empty, use * to get all files under a folder
  IMAGES=$(find . -maxdepth 1 -type d -not -name '.*' -exec basename {} \; | tr '\n' ',' | sed 's/,$//')
else
  IMAGES=$(echo "$IMAGES" | tr ' ' ',')
  IMAGES=$(echo "$IMAGES" | tr -cd '[:alnum:],*')
fi
IFS=','
echo $IMAGES
read -a image_array <<< "$IMAGES"

for d in "${image_array[@]}"; do
  if is_valid_image_dir "$d"; then
    image_data=$(get_image_data "$d")
    images_metadata+="${images_metadata:+,}$image_data"
  fi
done

images=$(echo "$(jq -r -n --argjson input "{$images_metadata}" '$input | keys_unsorted | map("\"" + . + "\"") | join(", ")')")

# Upload assets if tagging a release
if [[ "$GITHUB_REF" =~ "refs/tags/" ]]; then
echo "{$images_metadata}" > $ASSET_NAME
RELEASE_ID=$(get_release_id "$GENERAL_VERSION" "$GITHUB_TOKEN")
upload_asset "$RELEASE_ID" "$GITHUB_TOKEN" "$ASSET_NAME"
fi

echo "images=[$images]"
echo "images_metadata={$images_metadata}"
echo "version=${GENERAL_VERSION}"

exit 0
