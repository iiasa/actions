#!/bin/bash

# Change to the direction containing the action's code
pushd $GITHUB_ACTION_PATH

# Create a temporary directory
mkdir -p conda
BASE=$(realpath conda)

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
DEST="conda/${INSTALLER_TYPE}3-${VERSION}-${CONDA_OS}-x86_64"

# Write to special GitHub Actions environment variable to update $PATH for
# subsequent workflow steps
echo "$GITHUB_ACTION_PATH/$DEST" >> $GITHUB_PATH
echo "::set-output name=cache-path::$CACHE_PATH"


# Retrieve
BASE_URL=https://repo.anaconda.com
URL=$BASE_URL/$URL_FRAGMENT/$INSTALL_FILE

# curl --time-cond only works if the named file exists
if [ -x "conda.${EXT}" ]; then
  # Don't retrieve if the remote file is older than the cached one
  TIME_CONDITION=--remote-time --time-cond "conda.${EXT}"
fi

# Download file/application
curl --silent $URL --output "conda.${EXT}" $TIME_CONDITION

if [ $CONDA_OS == "windows-latest" ]; then
  # Write a PowerShell script. Install to the same directory as *nix
  cat << EOF >install-conda.ps1
Start-Process "$INSTALL_FILE" "/SP-", "/SILENT", "/DIR=${env:GHA_PATH}\${INSTALLER_TYPE}3", "/NORESTART" -Wait
"${env:GHA_PATH}/${INSTALLER_TYPE}3/Scripts" | Out-File -FilePath $env:GITHUB_PATH -Append
EOF
  cat install-conda.ps1

  # Invoke the script
  pwsh install-conda.ps1
fi

if [ $CONDA_OS == "macos-latest" ]; then
  # Extract files
  installer -pkg $INSTALL_FILE -target "${env:GHA_PATH}/${INSTALLER_TYPE}3"
  echo >> "${env:GHA_PATH}/${INSTALLER_TYPE}3/Scripts" $GITHUB_PATH
fi

if [ $CONDA_OS == "ubuntu-latest" ]; then
  # Extract files
  # -b run install in batch mode (without manual intervention):
  #  Accepts the Licence Agreement and allows Anaconda to be added to the `PATH`.
  # -p PREFIX install prefix, defaults to $PREFIX, must not contain spaces. Default PREFIX=$HOME/anaconda3
  bash $INSTALL_FILE -b -p "${env:GHA_PATH}/${INSTALLER_TYPE}3"
  # Load the  `PATH` environment variable in current terminal session
  source ~/.bashrc
fi

# Return to the last directory
popd
