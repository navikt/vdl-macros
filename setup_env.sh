#!/bin/bash

if [ ! -f .venv/bin/pip ]; then
  make install
fi

source .venv/bin/activate

code .
