set shell := ["bash", "-uc"]

default:
    @just --list

bump version *flags:
    ./scripts/release bump {{version}} {{flags}}

build:
    ./scripts/build

docs:
    ./scripts/docs

lint:
    ./scripts/lint

test: build
    ./scripts/test

verify: lint test
