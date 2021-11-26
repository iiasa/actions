#!/bin/bash

# Change to the directory containing the action's code
pushd "$GITHUB_ACTION_PATH" || exit

# # Create a temporary directory
mkdir -p conda
# BASE=$(realpath conda)

anaconda="anaconda"
miniconda="miniconda"

# Conda installer type and source URL fragment
case $INSTALLER in
  anaconda)
    INSTALLER_TYPE="Anaconda3"
    URL_FRAGMENT="archive"
    ;;
  miniconda)
    INSTALLER_TYPE="Miniconda3"
    URL_FRAGMENT=$INSTALLER
    ;;
esac

case $RUNNER_OS in
  Linux)
    EXT="sh"
    CACHE_PATH="$GITHUB_ACTION_PATH/conda.$EXT"
    CONDA_OS="Linux"
    BINDIR="bin"
    ;;
  macOS)
    EXT="sh"
    CACHE_PATH="$GITHUB_ACTION_PATH/conda.$EXT"
    CONDA_OS="MacOSX"
    BINDIR="bin"
    ;;
  Windows)
    EXT="exe"
    CACHE_PATH="$GHA_PATH\\conda.$EXT"
    CONDA_OS="Windows"
    BINDIR="Scripts"
    ;;
esac

# Name of the file/application to install
INSTALL_FILE=${INSTALLER_TYPE}-${VERSION}-${CONDA_OS}-x86_64.${EXT}

# Write to special GitHub Actions environment variable to update $PATH for
# subsequent workflow steps
echo "$GITHUB_ACTION_PATH/$INSTALLER_TYPE/$BINDIR" >> "$GITHUB_PATH"
echo "::set-output name=cache-path::$CACHE_PATH"

# Retrieve
URL=https://repo.anaconda.com/$URL_FRAGMENT/$INSTALL_FILE

# curl --time-cond only works if the named file exists
if [ -x "conda.$EXT" ]; then
  # Don't retrieve if the remote file is older than the cached one
  # shellcheck disable=SC2037
  TIME_CONDITION=--remote-time --time-cond "conda.$EXT"
fi

# Download file/application
echo "Download from: $URL"
curl --silent "$URL" --output "conda.$EXT" $TIME_CONDITION

# Install
case $RUNNER_OS in
  Linux|macOS)
    # Run the installer script
    #
    # -b run install in batch mode (without manual intervention):
    #  Accepts the Licence Agreement and allows Anaconda to be added to the `PATH`.
    # -p PREFIX install prefix, defaults to $PREFIX, must not contain spaces. Default PREFIX=$HOME/anaconda3
    bash "conda.$EXT" -b -p "$GITHUB_ACTION_PATH/$INSTALLER_TYPE"
    ;;
  Windows)
    # Convert any "/" in $GHA_PATH to "\". This occurs if the action is checked
    # out from a branch/ref whose name contains "/".
    DEST_ARG=$(echo "$GHA_PATH\\$INSTALLER_TYPE" | tr "/" "\\\\")
    # Write a PowerShell script. Install to the same directory as *nix
    cat << EOF >install-conda.ps1
Start-Process "conda.$EXT" "/S", "/D=$DEST_ARG" -Wait
EOF
    cat install-conda.ps1

    # Invoke the script
    pwsh install-conda.ps1
    ;;
esac

# Return to the last directory
popd || exit
