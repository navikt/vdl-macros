SHELL = /bin/bash
.DEFAULT_GOAL = install

VENV = .venv
PY = $(VENV)/bin/python -m

VENV_LOCK = .venv-lock
PY_LOCK = $(VENV_LOCK)/bin/python -m

install:
	rm -rf .venv
	python3.11 -m venv $(VENV) && \
		$(PY) pip install --upgrade pip && \
		$(PY) pip install dbt-core dbt-snowflake

doc:
	$(PY) docs.create
