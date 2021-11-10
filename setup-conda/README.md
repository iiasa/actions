# Set up conda

Supported options:

```yaml
steps:
- uses: iiasa/actions/setup-conda@main
  with:
    # Installer of conda to use; this is the default
    installer: Anaconda
    # Version of conda to install; this is the default
    version: 2021.05
```

To select the version to install, the following web pages provide an overview:
- Anaconda: https://repo.anaconda.com/archive/
- Miniconda: https://repo.anaconda.com/miniconda/