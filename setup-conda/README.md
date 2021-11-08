# Set up GAMS

Supported options:

```yaml
steps:
- uses: iiasa/actions/setup-gams@main
  with:
    # Version of GAMS to install; this is the default
    version: 25.1.1
    # Content for gamslice.txt, e.g. from a repository secret
    license: ${{ secrets.GAMS_LICENSE }}
```
