set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

default:
  @just --list

setup:
  prek install

lint:
  prek run --all-files

hooks:
  prek install
