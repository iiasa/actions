#!/bin/bash

# Change to the direction containing the action's code
pushd $GITHUB_ACTION_PATH

# Create a temporary directory
mkdir -p gams
BASE=$(realpath gams)

# GAMS source URL fragment, and path fragment for extracted files
case $RUNNER_OS in
  Linux)
    GAMS_OS=linux
    FRAGMENT=${GAMS_OS}_x64_64_sfx
    ;;
  macOS)
    GAMS_OS=macosx
    FRAGMENT=osx_x64_64_sfx
    ;;
  Windows)
    GAMS_OS=windows
    FRAGMENT=${GAMS_OS}_x64_64
    ;;
esac

# Retrieve
BASE_URL=https://d37drm4t2jghv5.cloudfront.net/distributions
URL=$BASE_URL/$GAMS_VERSION/$GAMS_OS/$FRAGMENT.exe

# NB this currently has no effect, because caching is not configured for this
#    action
if [ -x gams.exe ]; then
  # Don't retrieve if the remote file is older than the cached one
  TIME_CONDITION=--remote-time --time-cond gams.exe
fi

curl --silent $URL --output gams.exe $TIME_CONDITION

# TODO confirm checksum

# Path fragment for extraction or install
DEST=gams$(echo $GAMS_VERSION | cut -d. -f1-2)_$FRAGMENT

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

# Write to special GitHub Actions environment variable to update $PATH for
# subsequent workflow steps
echo "$GITHUB_ACTION_PATH/$DEST" >> $GITHUB_PATH

# Confirm the executable is on $PATH
which gams

# Return to the last directory
popd
