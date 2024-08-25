#!/usr/bin/env just --justfile
# vim:set ft=just ts=2 sts=4 sw=2 et:

# justfile requires https://github.com/casey/just

# https://github.com/casey/just#settings
set allow-duplicate-recipes := false
# Load environment variables from `.env` file.
set dotenv-load := true
set export := false
#set positional-arguments
#set shell := ["bash", "-euo", "pipefail", "-c"]
set shell := ["bash", "-c"]

work_dir := "build"
timestamp := `date +%s`
project_name := env_var('PROJECT_NAME')
project_version := env_var('PROJECT_VERSION')
#semver := env_var('PROJECT_VERSION')
#commit := `git show -s --format=%h`
#project_version := semver + "+" + commit

# Default recipe (equivalent to 'all' in Makefile)

# Lists the tasks and variables in the justfile
@_list:
  just --justfile {{justfile()}} --list --unsorted
  echo ""
  echo "Available variables:"
  just --evaluate | sed 's/^/    /'
  echo ""
  echo "Override variables using 'just key=value ...' (also ALL_UPPERCASE ones)"

# Evaluate and return all just variables
evaluate:
  @just --evaluate

# Show usage information
help:
  @just --justfile {{justfile()}} --list

# Return system information (e.g. os, architecture, etc)
system-info:
  @echo "architecture: {{arch()}}"
  @echo "os: {{os()}}"
  @echo "os family: {{os_family()}}"

# Build the program
build:
  cargo build --release
  test -f target/release/su-exec-rs && cp target/release/su-exec-rs bin/su-exec-rs

# Run the program
run *args:
  cargo run --release -- {{args}}

# Clean build artifacts
clean:
  cargo clean
