#!/bin/bash
#
# Expected environment variables from action.yml:
# - INSTALLER, VERSION: user inputs
#
# Defined by GitHub Actions:
# - GITHUB_ACTION_PATH: path in which the action is checked out/run
# - RUNNER_OS

# Change to the directory containing the action's code
pushd "$GITHUB_ACTION_PATH" || exit

# Set options based on the installer:
# - INSTALLER_TYPE used in the download URL *and* installation path
# - a URL_FRAGMENT used in the download URL
case $INSTALLER in
  anaconda)
    INSTALLER_TYPE="Anaconda3-${VERSION}"
    BASE_URL="https://repo.anaconda.com/archive"
    ;;
  mambaforge)
    INSTALLER_TYPE="Mambaforge"
    BASE_URL="https://github.com/conda-forge/miniforge/releases/${VERSION}/download"
    ;;
  miniconda)
    INSTALLER_TYPE="Miniconda3-${VERSION}"
    BASE_URL="https://repo.anaconda.com/miniconda"
    ;;
  *)
    echo "::error::'installer:' must be one of (anaconda, mambaforge, miniconda); got '$INSTALLER'"
    exit 1
esac

# Installation path
DEST="$GITHUB_ACTION_PATH/$INSTALLER_TYPE"

# Set options based on the OS:
# - EXT: file extension for the installer
# - BINDIR: directory under DEST containg executables
case $RUNNER_OS in
  Linux|macOS)
    EXT="sh"
    BINDIR="bin"
    ;;
  Windows)
    EXT="exe"
    BINDIR="Scripts"
    # Convert any "/" in $GHA_PATH to "\". This occurs if the action is checked
    # out from a branch/ref whose name contains "/".
    DEST=$(echo "$DEST" | tr "/" "\\\\")
    ;;
esac

# Set OS, used to construct the URL
OS=$(echo "$RUNNER_OS" | sed "s/macOS/MacOSX/")

# URL for installer
URL="${BASE_URL}/${INSTALLER_TYPE}-${OS}-x86_64.${EXT}"

# curl --time-cond only works if the named file exists
if [ -x "conda.$EXT" ]; then
  # Don't retrieve if the remote file is older than the cached one
  TIME_CONDITION=--remote-time --time-cond "conda.$EXT"
fi

# Download installer
echo "Download from: $URL"
curl --location --silent "$URL" --output "conda.$EXT" $TIME_CONDITION

# Run the installer
# - Run in batch/silent mode ("-b" on *nix, "/S" on Windows), accept the licence
#   agreement, etc.
# - Set the installation path ("-p" on *nix, "/D" on Windows).
case $RUNNER_OS in
  Linux|macOS)
    bash "conda.$EXT" -b -p "$DEST"
    ;;
  Windows)
    # Write a PowerShell script, then invoke it
    cat << EOF >install-conda.ps1
Start-Process "conda.$EXT" "/S", "/D=$DEST" -Wait
EOF
    cat install-conda.ps1
    pwsh install-conda.ps1
    ;;
esac

# Write to GitHub Actions environment variable to update $PATH for subsequent
# workflow steps. Note that this uses GITHUB_ACTION_PATH ("/" separated) even on
# Windows, because this is what GHA expects.
echo "$GITHUB_ACTION_PATH/$INSTALLER_TYPE/$BINDIR" >> "$GITHUB_PATH"

# Return to the last directory
popd || exit
