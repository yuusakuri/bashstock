set shell := ["bash", "-uc"]

default:
    @just --list

build:
    ./scripts/build

docs:
    ./scripts/docs

lint:
    ./scripts/lint

test: build
    ./scripts/test

verify: lint test
