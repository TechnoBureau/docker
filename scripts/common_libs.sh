#!/usr/bin/env bash

get_release_id() {
  local release_version="$1"
  local github_token="$2"

  curl -s -H "Authorization: Bearer $github_token" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/releases/tags/$release_version" |
    jq -r '.id'
}
get_asset_id() {
  local release_id="$1"
  local asset_name="$2"
  local asset_id=$(curl -L -s -H "Authorization: Bearer $token" "https://api.github.com/repos/$GITHUB_REPOSITORY/releases/$release_id/assets" | jq -r '.[] | select(.name == '\"$asset_name\"') | .id')
  echo $asset_id
}
download_asset() {
  local release_id="$1"
  local token="$2"
  local asset_name="$3"
  local delete_flag="$4"

  local asset_id=$(get_asset_id $release_id $asset_name)

  if [[ ! -z "$asset_id" ]]; then
    curl -s -L \
      -H "Accept: application/octet-stream" \
      -H "Authorization: Bearer $token" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/repos/$GITHUB_REPOSITORY/releases/assets/$asset_id" > "$asset_name"

    if [[ ! -z "$delete_flag" ]]; then
      # Delete the asset
      curl -s -L -X DELETE \
        -H "Authorization: Bearer $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$GITHUB_REPOSITORY/releases/assets/$asset_id" > /dev/null
    fi
  fi
}

# Define function to upload asset
upload_asset() {
  local release_id="$1"
  local token="$2"
  local asset_name="$3"

  local asset_id=$(get_asset_id $release_id $asset_name)

  curl -s -L -X POST \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/vnd.github+json" \
    --data-binary "@$asset_name" \
    "https://uploads.github.com/repos/$GITHUB_REPOSITORY/releases/$release_id/assets?name=$asset_name" > /dev/null

}
update_release_notes() {
  local release_id="$1"
  local token="$2"
  local body="$3"

  # Update release body on GitHub
  curl -s -L -X PATCH \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/vnd.github.v3+json" \
    -d '{"body": "'"$body"'"}' \
    "https://uploads.github.com/repos/$GITHUB_REPOSITORY/releases/$release_id" > /dev/null
}

# Define function to extract version from Dockerfile
get_version_from_dockerfile() {
  local dockerfile="$1"
  awk -F= '/^ARG VERSION=/ {print $2}' "$dockerfile" | tr -d ' '
}

is_valid_image_dir() {
  [[ -d "$1" && ! -f "$1/skip" ]]
}
get_image_data() {
  local image_name="$1"
    local version=$(get_version_from_dockerfile "$image_name/$image_name.Dockerfile")
    version="${version:-${GENERAL_VERSION}}"
    echo "\"${image_name}\": { \"version\": \"$version\" }"
}
