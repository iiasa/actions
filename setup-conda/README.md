# Set up Anaconda or Miniconda

Supported options:

```yaml
steps:
- uses: iiasa/actions/setup-conda@main
  with:
    # Installer to use: one of "anaconda" or "miniconda" (lower-case only)
    installer: anaconda
    # Version of conda to install; this is the default. See note below.
    version: 2021.11
```

To select the `version` to install, the following web pages provide an overview:
- Anaconda: https://repo.anaconda.com/archive/
- Miniconda: https://repo.anaconda.com/miniconda/

Note that on `windows-latest` runners only, versions of Anaconda after 2019.03 do not install correctly. This is an unfixed upstream bug. Recent versions, including the latest/default (2021.11) *do* work on `ubuntu-latest` and `macos-latest`.
