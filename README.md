# Actions and reusable workflows
GitHub Actions and reusable workflows used by IIASA repositories.

## Actions

- [`iiasa/actions/setup-conda`](https://github.com/iiasa/actions/tree/main/setup-conda): set up Anaconda or Miniconda.

  For a usage example, see the "conda" workflow of [iiasa/message_ix](https://github.com/iiasa/message_ix/blob/main/.github/workflows/conda.yaml).

- [`iiasa/actions/setup-gams`](https://github.com/iiasa/actions/tree/main/setup-gams): set up GAMS.

  For a usage example, see the "pytest" workflow of [iiasa/ixmp](https://github.com/iiasa/ixmp/blob/main/.github/workflows/pytest.yaml).

## Reusable workflows

For usage examples, see the workflows of the same name in [iiasa/ixmp](https://github.com/iiasa/ixmp/tree/main/.github/workflows).

- [`iiasa/actions/.github/workflows/lint.yaml`](https://github.com/iiasa/actions/blob/main/.github/workflows/lint.yaml): lint and check Python code with black, flake8, isort, and mypy.
- [`iiasa/actions/.github/workflows/publish.yaml`](https://github.com/iiasa/actions/blob/main/.github/workflows/publish.yaml): build Python package distributions with twine and publish to (Test)PyPI
