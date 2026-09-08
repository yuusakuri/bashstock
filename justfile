set shell := ["bash", "-uc"]

default:
    @just --list

build:
    ./scripts/build

lint:
    ./scripts/lint

test: build
    ./scripts/test

verify: lint test
