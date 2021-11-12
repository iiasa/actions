#!/bin/bash

# Change to the directory containing the action's code
pushd $GITHUB_ACTION_PATH

# # Create a temporary directory
# mkdir -p conda
# BASE=$(realpath conda)

anaconda="anaconda"
miniconda="miniconda"

# Conda installer type and source URL fragment
if [ $INSTALLER == $anaconda ]; then
  INSTALLER_TYPE='Anaconda'
  URL_FRAGMENT='archive'
fi

if [ $INSTALLER == $miniconda ]; then
  INSTALLER_TYPE='Miniconda'
  URL_FRAGMENT=$INSTALLER
fi

case $RUNNER_OS in
  Linux)
    EXT=sh
    CACHE_PATH="$GITHUB_ACTION_PATH/conda.$EXT"
    CONDA_OS=Linux
    ;;
  macOS)
    EXT=pkg
    CACHE_PATH="$GITHUB_ACTION_PATH/conda.$EXT"
    CONDA_OS=MacOSX
    ;;
  Windows)
    EXT=exe
    CACHE_PATH="$GHA_PATH\\conda.$EXT"
    CONDA_OS=Windows
    ;;
esac

# Name of the file/application to install
INSTALL_FILE=${INSTALLER_TYPE}3-${VERSION}-${CONDA_OS}-x86_64.${EXT}

# Path fragment for extraction or install
DEST="${INSTALLER_TYPE}3"

# Write to special GitHub Actions environment variable to update $PATH for
# subsequent workflow steps
echo "$GITHUB_ACTION_PATH/$DEST/Scripts" >> $GITHUB_PATH
echo "::set-output name=cache-path::$CACHE_PATH"

ls -l

# Retrieve
BASE_URL=https://repo.anaconda.com
URL=$BASE_URL/$URL_FRAGMENT/$INSTALL_FILE

# curl --time-cond only works if the named file exists
if [ -x "conda.$EXT" ]; then
  # Don't retrieve if the remote file is older than the cached one
  TIME_CONDITION=--remote-time --time-cond "conda.$EXT"
fi

# Download file/application
echo "Download from: $URL"
curl --silent $URL --output "conda.$EXT" $TIME_CONDITION

# Install
case $RUNNER_OS in
  Linux)
    # Extract files
    # -b run install in batch mode (without manual intervention):
    #  Accepts the Licence Agreement and allows Anaconda to be added to the `PATH`.
    # -p PREFIX install prefix, defaults to $PREFIX, must not contain spaces. Default PREFIX=$HOME/anaconda3
    bash "conda.$EXT" -b -p "$GITHUB_ACTION_PATH/$DEST"
    # Load the  `PATH` environment variable in current terminal session
    source ~/.bashrc
    ;;
  macOS)
    # Use the macOS "installer" program to run the .pkg
    installer -pkg "conda.$EXT" -target "$GITHUB_ACTION_PATH/$DEST"
    ;;
  Windows)
    # Write a PowerShell script. Install to the same directory as *nix
    cat << EOF >install-conda.ps1
Start-Process "conda.$EXT" "/SP-", "/SILENT", "/DIR=$GHA_PATH\\$DEST", "/NORESTART" -Wait
EOF
    cat install-conda.ps1

    # Invoke the script
    pwsh install-conda.ps1
    ;;
esac

# Return to the last directory
popd
