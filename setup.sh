#!/bin/bash

# Copyright (c) 2021, the Flutter project.
#
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

###############################################################################
# Bash script that downloads and does setup for a Dart SDK.                   #
# Takes three params; first listed is the default:                            #
# $1: Flutter SDK channel: stable|beta|dev|main                                   #
# $2: Flutter version: latest|<version_string>                                #
# $3: OS: Linux|Windows|macOS                                                 #
###############################################################################

### ARGUMENT HANDLING ###
# Parse channel and version args.
CHANNEL="${1:-stable}"
VERSION="${2:-latest}"
OS="${3:-Linux}"

if [[ $CHANNEL == main ]]; then
  if [[ $VERSION != "latest" ]]; then
    echo -e "::error::Versions cannot be specified for builds from the main channel."
    exit 1
  fi
fi

OS=$(echo "$OS" | awk '{print tolower($0)}')

echo "Installing Flutter SDK version \"${VERSION}\" from the \"${CHANNEL}\" channel on \"${OS}\"."

### SETUP FOR MAIN CHANNEL ###
if [[ $CHANNEL == main ]]; then
  # For 'main' channel we simply git clone
  cd ${HOME}
  echo "Downloading the Flutter SDK from GitHub..."
  git clone https://github.com/flutter/flutter.git
  ./flutter/bin/flutter precache
fi

### SETUP FOR OTHER CHANNELS ###
if [[ $CHANNEL != main ]]; then
  echo "Getting list of available SDKs..."
  # For non-main channels we get the bundle url from the list of available bundles.
  BUNDLES="https://storage.googleapis.com/flutter_infra/releases/releases_${OS}.json"
  curl --connect-timeout 15 --retry 5 "$BUNDLES" > "${HOME}/releases.json"
  if [ $? -ne 0 ]; then
    echo -e "::error::Download of available releases list failed!"
    exit 1
  fi

  # Calculate download Url.
  PREFIX="https://storage.googleapis.com/flutter_infra_release/releases"
  if [[ $VERSION == latest ]]; then
    ZIP=`jq ".releases [] | select(.channel==\"${CHANNEL}\") | .archive" ${HOME}/releases.json --raw-output | head -1`
  else
    ZIP=`jq ".releases [] | select(.version==\"${VERSION}\" and .channel==\"${CHANNEL}\") | .archive" ${HOME}/releases.json --raw-output`
  fi
  URL="${PREFIX}/${ZIP}"
  echo "Downloading the Flutter SDK from \"${URL}\"..."
  curl --connect-timeout 15 --retry 5 "$URL" > "${HOME}/sdk"
  if [[ $OS == linux ]]; then
    mv "${HOME}/sdk" "${HOME}/sdk.tar.xz"
    tar xf "${HOME}/sdk.tar.xz" -d "${RUNNER_TOOL_CACHE}" > /dev/null
  else
    mv "${HOME}/sdk" "${HOME}/sdk.zip"
    unzip "${HOME}/sdk.zip" -d "${RUNNER_TOOL_CACHE}" > /dev/null
  fi
  if [ $? -ne 0 ]; then
    echo -e "::error::Download failed! Please check passed arguments."
    exit 1
  fi
  rm "${HOME}/sdk.zip"
  ${RUNNER_TOOL_CACHE}/flutter/bin/flutter --version
fi

### SETUP ENVIRONMENT ###

# Configure pub to use a fixed location.
if [[ $OS == windows ]]; then
  PUBCACHE="${USERPROFILE}\\.pub-cache"
else
  PUBCACHE="${HOME}/.pub-cache"
fi
echo "PUB_CACHE=${PUBCACHE}" >> $GITHUB_ENV
echo "Pub cache set to: ${PUBCACHE}"

# Update paths.
echo "${PUBCACHE}/bin" >> $GITHUB_PATH
echo "${RUNNER_TOOL_CACHE}/flutter/bin" >> $GITHUB_PATH

# Report success, and print version.
echo -e "Successfully installed the Flutter SDK:"
${RUNNER_TOOL_CACHE}/flutter/bin/flutter --version
