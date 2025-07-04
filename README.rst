Actions and reusable workflows
******************************

GitHub Actions and reusable workflows used by IIASA repositories.

Actions
=======

``iiasa/actions/setup-conda``
-----------------------------

Set up Anaconda or Miniconda.

- `README <https://github.com/iiasa/actions/tree/main/setup-conda>`__
- For a usage example, see the "conda" workflow of `iiasa/message_ix <https://github.com/iiasa/message_ix/blob/main/.github/workflows/conda.yaml>`__.

``iiasa/actions/setup-gams``
----------------------------

Set up GAMS.

- `README <https://github.com/iiasa/actions/tree/main/setup-gams>`__
- For a usage example, see the "pytest" workflow of `iiasa/ixmp <https://github.com/iiasa/ixmp/blob/main/.github/workflows/pytest.yaml>`__.

Reusable workflows
==================

See GitHub's documentation pages on `“Reusing workflows” <https://docs.github.com/en/actions/using-workflows/reusing-workflows>`__.
The usage examples are from the workflows of the same name in `iiasa/ixmp <https://github.com/iiasa/ixmp/tree/main/.github/workflows>`__

``lint.yaml``
-------------

   **Important:**
   This workflow is no longer used in most IIASA ECE program repositories.
   Instead, an ordinary job is used to invoke `pre-commit <https://pre-commit.com>`_ via `uvx <https://docs.astral.sh/uv/guides/tools/>`_.
   See `iiasa/message_ix/.github/workflows.pytest.yaml <https://github.com/iiasa/message_ix/blob/1edda554fc38d439073f6bdbd6195015cb29fb4d/.github/workflows/pytest.yaml#L220-L236>`_ for an example.
   Pre-commit in turn allows to configure a repo-specific set of checks and check arguments, whereas this reusable action used a fixed set.

Lint and check Python code with black, flake8, isort, and mypy.

- `Source <https://github.com/iiasa/actions/blob/main/.github/workflows/lint.yaml>`__.
- Usage example:

  .. code-block:: yaml

     name: Lint

     on:  # Run the workflow on pushes to `main`, or new commits on PRs into `main`
       push:
         branches: [ main ]
       pull_request:
         branches: [ main ]

     jobs:
       lint:
         uses: iiasa/actions/.github/workflows/lint.yaml@main
         with:
           max-complexity: 15
           python-version: "3.10"
           type-hint-packages: pytest genno GitPython xarray sphinx types-setuptools

``publish.yaml``
----------------

Build Python package distributions, check with ``twine``, and publish to (Test)PyPI.

- `Source <https://github.com/iiasa/actions/blob/main/.github/workflows/publish.yaml>`__
- Usage example:

  .. code-block:: yaml

     name: Build package and publish

     on:
       pull_request:
         branches: [ main ]  # Package is built and checked
       push:
         branches: [ main ]  # Package is built and checked
         tags: [ "v*" ]  # Package is published to PyPI
       release:
         types: [ published ]  # Package is also published to PyPI

     jobs:
       publish:
         uses: iiasa/actions/.github/workflows/publish.yaml@main
         secrets:
           PYPI_TOKEN: ${{ secrets.PYPI_TOKEN }}
         # Publish to TestPyPI; omit with: to publish to PyPI itself
         with:
           repository-url: https://test.pypi.org/legacy/
