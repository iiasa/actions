#!/usr/bin/env python

import os
import platform
import sys
from pathlib import Path
from subprocess import CompletedProcess, run
from typing import Tuple


def get_info(uname, version: str) -> Tuple[str, str]:
    """Return GAMS source URL fragment, and path fragment for extracted files."""
    if uname.system == "Darwin":
        arch = {"arm64": "arm64", "x86_64": "x64_64"}[uname.machine]
        sfx = "_sfx" if version < "43" else ""
        filename, fragment = f"macosx/osx_{arch}_sfx.exe", f"osx_{arch}{sfx}"
    elif uname.system == "Linux":
        filename, fragment = "linux/linux_x64_64_sfx.exe", "linux_x64_64_sfx"
    elif uname.system == "Windows":
        filename, fragment = "windows/windows_x64_64.exe", "windows_x64_64"
    else:
        raise ValueError(f"Unsupported platform: {uname}")

    v_major, v_minor, _ = version.split(".", maxsplit=2)
    return filename, f"gams{v_major}.{v_minor}_{fragment}"


if __name__ == "__main__":
    uname, version = platform.uname(), sys.argv[2]

    # GAMS source URL fragment, and directory name for extracted files
    url_fragment, install_dir_name = get_info(uname, version)

    # Base path containing this script and files
    base = Path(os.environ["GITHUB_ACTION_PATH"])

    # Change to this directory
    os.chdir(base)

    # Path to the downloaded installer
    dl_path = base.joinpath("gams.exe")

    # Directory for extracted files
    install_dir = base.joinpath(install_dir_name)

    if sys.argv[1] == "pre":
        # Set "steps.{id}.outputs.*" values for use with actions/cache
        with open(os.environ["GITHUB_OUTPUT"], "a") as f:
            f.write(f"dist={dl_path}\n")
            f.write(f"install={install_dir}\n")
        sys.exit(0)
    elif sys.argv[1] != "install":
        raise ValueError(f"Unrecognized CLI args {sys.argv}")

    # Construct the arguments
    args = ["curl", "--output", str(dl_path)]

    # Don't retrieve if the remote file is older than the cached one
    # Use curl --time-cond, but only if the named file exists
    if dl_path.exists():
        args.extend(["--remote-time", "--time-cond", str(dl_path)])

    # Construct the URL
    args.append(
        f"https://d37drm4t2jghv5.cloudfront.net/distributions/{version}/{url_fragment}"
    )

    # Retrieve the installer
    print(f"Run: {' '.join(args)}")
    run(args)
    assert dl_path.exists()

    # TODO Detect an error message, e.g. a non-existent distribution
    # TODO confirm checksum

    if (
        install_dir.joinpath("gams").is_file()
        or install_dir.joinpath("gams.exe").is_file()
    ):
        # Already exists, e.g. restored from cache → skip install
        result: "CompletedProcess" = CompletedProcess([], returncode=0)
    elif uname.system == "Windows":
        # Write and invoke a PowerShell script that invokes the installer
        script_path = Path("setup-gams.ps1")
        script_path.write_text(
            f'Start-Process "gams.exe" "/SP-", "/SILENT", "/DIR={install_dir}", '
            '"/NORESTART" -Wait'
        )
        result = run(["pwsh", str(script_path)])
    else:
        # Extract files (in the current working directory)
        result = run(["unzip", "-q", str(dl_path)])

    # Propagate any exception
    if result.returncode:
        sys.exit(result.returncode)

    # Install license
    license = os.environ.pop("GAMS_LICENSE")
    if len(license):
        print(f"Obtained {len(license)} bytes for gamslice.txt")
        install_dir.joinpath("gamslice.txt").write_text(license)

    # Write to GitHub Actions environment variable to update $PATH for subsequent steps
    with open(os.environ["GITHUB_PATH"], "a") as f:
        f.write(str(install_dir) + "\n")
