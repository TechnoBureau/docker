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
  curl -s -X PATCH \
    -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.github.v3+json" \
    -d '{"body": "'"$body"'"}' \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/releases/$release_id" > /dev/null
}


is_valid_image_dir() {
  if [[ -n "$IMAGE_INPUT" && "$IMAGE_INPUT" != "*" ]]; then
    # Skip file existence check when IMAGES is set and not "*"
    [[ -d "$1" &&  -f "$1/$1.Dockerfile" ]]
  else
    [[ -d "$1" && ! -f "$1/skip" ]]
  fi
}
get_image_data() {
  local image_name="$1"
    local version=$(_get_value_from_arg_env "$image_name/$image_name.Dockerfile" "VERSION")
    local arch=$(_get_value_from_arg_env "$image_name/$image_name.Dockerfile" "OS_ARCH")
    version="${version:-${GENERAL_VERSION}}"
    arch="${arch:-amd64,arm64}"
    echo "\"${image_name}\": { \"version\": \"$version\",\"platform\": \"$arch\" }"
}

# Function to get the value of ARG or ENV variable by key from Dockerfile
_get_value_from_arg_env() {
    local dockerfile_path=$1
    local key=$2
    local val
    local vname

    # Extract ARG values from the Dockerfile
    local arg_value=$(awk -v key="$key" '$1 == "ARG" && $2 ~ "^" key "=" {gsub(/[^=]+=/, "", $0); gsub(/[\r\n]/, "", $0); print $0}' "$dockerfile_path")

    # Extract ENV values from the Dockerfile
    local env_value=$(awk -v key="$key" '$1 == "ENV" && $2 ~ "^" key "=" {gsub(/[^=]+=/, "", $0); gsub(/[\r\n]/, "", $0); print $0}' "$dockerfile_path")
   # local env_value=$(awk -v key="$key" '$1 == "ENV" && $2 == key {gsub(/[^=]+=/, "", $0); gsub(/[\r\n]/, "", $0); print $0}' "$dockerfile_path")

    # Print the value if found, otherwise print a message
    if [ -n "$arg_value" ]; then
         val=$arg_value
    elif [ -n "$env_value" ]; then
        val=$env_value
    else
        val=""
    fi

    if [[ $val == \${*} ]]; then
      vname=$(echo "$val" | cut -c 3- | sed 's/.$//')
      _get_value_from_arg_env "$dockerfile_path" "$vname"
      return
    fi
    echo "$val"
}

# Function to get the property value for a particular property with an optional prefix
get_property() {
    local metadata=$1
    local key=$2
    local property=$3
    local prefix=$4
    local property_value

    # Check if the key exists in the JSON data
    if jq -e ".[\"$key\"]" <<< "$metadata" >/dev/null; then
        # Check if the property key exists
        if jq -e ".[\"$key\"].$property" <<< "$metadata" >/dev/null; then
            property_value=$(jq -r ".[\"$key\"].$property" <<< "$metadata")

            # Check if prefix is provided
            if [ -n "$prefix" ]; then
                # Concatenate property value with prefix
                echo "${prefix}${property_value//,/,$prefix}"
            else
                echo "${property_value}"
            fi
        else
            # Return empty string if property key is not found
            echo ""
        fi
    else
        # Return empty string if key is not found
        echo ""
    fi
}