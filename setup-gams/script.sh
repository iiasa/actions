#!/bin/bash

# Change to the direction containing the action's code
pushd $GITHUB_ACTION_PATH

# Create a temporary directory
mkdir -p gams
BASE=$(realpath gams)

# GAMS source URL fragment, and path fragment for extracted files
case $RUNNER_OS in
  Linux)
    CACHE_PATH="$GITHUB_ACTION_PATH/gams.exe"
    GAMS_OS=linux
    FRAGMENT=${GAMS_OS}_x64_64_sfx
    ;;
  macOS)
    CACHE_PATH="$GITHUB_ACTION_PATH/gams.exe"
    GAMS_OS=macosx
    FRAGMENT=osx_x64_64_sfx
    ;;
  Windows)
    CACHE_PATH="$GHA_PATH\\gams.exe"
    GAMS_OS=windows
    FRAGMENT=${GAMS_OS}_x64_64
    ;;
esac

# Path fragment for extraction or install
DEST=gams$(echo $GAMS_VERSION | cut -d. -f1-2)_$FRAGMENT

# Write to special GitHub Actions environment variable to update $PATH for
# subsequent workflow steps
echo "$GITHUB_ACTION_PATH/$DEST" >> $GITHUB_PATH
echo "::set-output name=cache-path::$CACHE_PATH"

# Retrieve
BASE_URL=https://d37drm4t2jghv5.cloudfront.net/distributions
URL=$BASE_URL/$GAMS_VERSION/$GAMS_OS/$FRAGMENT.exe

# curl --time-cond only works if the named file exists
if [ -x gams.exe ]; then
  # Don't retrieve if the remote file is older than the cached one
  TIME_CONDITION=--remote-time --time-cond gams.exe
fi

curl --silent $URL --output gams.exe $TIME_CONDITION

# TODO confirm checksum

if [ $GAMS_OS = "windows" ]; then
  # Write a PowerShell script. Install to the same directory as *nix unzip
  cat << EOF >install-gams.ps1
Start-Process "gams.exe" "/SP-", "/SILENT", "/DIR=$GHA_PATH\\$DEST", "/NORESTART" -Wait
EOF
  cat install-gams.ps1

  # Invoke the script
  pwsh install-gams.ps1
else
  # Extract files
  unzip -q gams.exe
fi

# Return to the last directory
popd
