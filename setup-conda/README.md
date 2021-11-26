# Set up Anaconda or Miniconda

Supported options:

```yaml
steps:
- uses: iiasa/actions/setup-conda@main
  with:
    # Installer to use: one of "anaconda" or "miniconda" (lower-case only)
    installer: anaconda
    # Version of conda to install; this is the default
    version: 2021.11
```

To select the `version` to install, the following web pages provide an overview:
- Anaconda: https://repo.anaconda.com/archive/
- Miniconda: https://repo.anaconda.com/miniconda/
