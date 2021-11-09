#!/bin/bash

# Change to the direction containing the action's code
pushd $GITHUB_ACTION_PATH

# Create a temporary directory
mkdir -p conda
BASE=$(realpath conda)

# GAMS source URL fragment, and path fragment for extracted files
if [$INSTALLER] == 'anaconda'; then
  INSTALLER_TYPE == 'Anaconda'
  case $RUNNER_OS in
    Linux)
      PATH_ENDING = conda.sh
      CACHE_PATH="$GITHUB_ACTION_PATH/$PATH_ENDING"
      CONDA_OS=Linux
      FRAGMENT=${INSTALLER_TYPE}3-${VERSION_ANACONDA}-${CONDA_OS}-x86_64.sh
      ;;
    macOS)
      PATH_ENDING = conda.pkg
      CACHE_PATH="$GITHUB_ACTION_PATH/$PATH_ENDING"
      CONDA_OS=MacOSX
      FRAGMENT=${INSTALLER_TYPE}3-${VERSION_ANACONDA}-${CONDA_OS}-x86_64.pkg
      ;;
    Windows)
      PATH_ENDING = conda.exe
      CACHE_PATH="$GHA_PATH\\$PATH_ENDING"
      CONDA_OS=Windows
      FRAGMENT=${INSTALLER_TYPE}3-${VERSION_ANACONDA}-${CONDA_OS}-x86_64.exe
      ;;
  esac

  # Retrieve
  BASE_URL=https://repo.anaconda.com/archive
  URL=$BASE_URL/$FRAGMENT

fi

if [$INSTALLER] == 'miniconda'; then
  INSTALLER_TYPE == 'Miniconda'
  case $RUNNER_OS in
    Linux)
      PATH_ENDING = conda.sh
      CACHE_PATH="$GITHUB_ACTION_PATH/$PATH_ENDING"
      CONDA_OS=Linux
      FRAGMENT=${INSTALLER_TYPE}3-$VERSION_MINICONDA-${CONDA_OS}-x86_64.sh
      ;;
    MacOS)
      PATH_ENDING = conda.pkg
      CACHE_PATH="$GITHUB_ACTION_PATH/$PATH_ENDING"
      CONDA_OS=MacOSX
      FRAGMENT=${INSTALLER_TYPE}3-${VERSION_MINICONDA}-${CONDA_OS}-x86_64.pkg
      ;;
    Windows)
      PATH_ENDING = conda.exe
      CACHE_PATH="$GHA_PATH\\$PATH_ENDING"
      CONDA_OS=Windows
      FRAGMENT=${INSTALLER_TYPE}3-${VERSION_MINICONDA}-${CONDA_OS}-x86_64.exe
      ;;
  esac

  # Retrieve
  BASE_URL=https://repo.anaconda.com/miniconda
  URL=$BASE_URL/$FRAGMENT

fi

# curl --time-cond only works if the named file exists
if [ -x $PATH_ENDING ]; then
  # Don't retrieve if the remote file is older than the cached one
  TIME_CONDITION=--remote-time --time-cond $PATH_ENDING
fi

curl --silent $URL --output $PATH_ENDING $TIME_CONDITION

if [ $CONDA_OS = "windows" ]; then
  # Write a PowerShell script. Install to the same directory as *nix
  cat << EOF >install-conda.ps1
Start-Process "$FRAGMENT" "/S", "/D=${env:GHA_PATH}\${INSTALLER_TYPE}3" -Wait
"${env:GHA_PATH}/${INSTALLER_TYPE}3/Scripts" | Out-File -FilePath $env:GITHUB_PATH -Append
EOF
  cat install-conda.ps1

  # Invoke the script
  pwsh install-conda.ps1
else
  # Extract files
  installer -pkg $FRAGMENT -target $env:GITHUB_PATH
  echo >> "${env:GHA_PATH}/${INSTALLER_TYPE}3/Scripts" $GITHUB_PATH
fi

# Return to the last directory
popd
