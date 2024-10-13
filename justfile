#!/usr/bin/env just --justfile

set unstable := false
set allow-duplicate-recipes := false
set allow-duplicate-variables := false
#set positional-arguments := true
# Export all variables as environment variables.
set export := false
set dotenv-required := false
set dotenv-load := true
#set dotenv-path := env_var('PWD')
set dotenv-filename := ".env"

#set working-directory := env_var('PWD')
#set tempdir := env_var('TMPDIR')

# Set command used to invoke recipes and evaluate backticks.
set shell := ["bash", "-c"]
#set shell := ["bash", "-euo", "pipefail", "-c"]
#set shell := ["zsh", "-cu"]
#set shell := ["bun", "exec"]
set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]
# Set command used to invoke recipes with empty [script] attribute.
#script-interpreter := ['bash', '-c']

################################################################################

project_root            := justfile_directory()
project_name            := env_var('PROJECT_NAME')
project_version         := env_var('PROJECT_VERSION')

#_arch                  := trim(lowercase(justfile())) + arch()
_timestamp              := `date +%s`
_commit                 := `git show -s --format=%h`
version                 := project_version + "+" + _commit

path                    := env_var('PATH')
#tmpdir                 := env_var('TMPDIR')
#workdir                := env_var('PWD')
#worklog                := _workdir / "build.log"
#tardir                 := _tmpdir / "su-exec-rs-" + version
#tarball                := _tardir + ".tgz"

#bt                     := env_var('RUST_BACKTRACE')
#export RUST_BACKTRACE  := bt

################################################################################

# Default recipe (equivalent to 'all' in Makefile).
# If no default recipe, first recipe will become default.

# Lists the tasks and variables in the justfile.
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

# List available recipes
help:
    @just --justfile {{justfile()}} --list

# Just format
justfmt:
    just --justfile {{justfile()}} --fmt

# Return system information
system-info:
    @echo "os: {{os()}}"
    @echo "family: {{os_family()}}"
    @echo "architecture: {{arch()}}"
    @echo "home directory: {{ home_directory() }}"

# Install and setup rust toolchain
rust-install:
    #!/usr/bin/env bash
    curl --proto '=https' --tlsv1.2 -sSf 'https://sh.rustup.rs' | sh -s -- -y
    echo "sourcing $HOME/.cargo/env..."
    source $HOME/.cargo/env

rustup *args:
    rustup {{ args }}

rust-add-component *args:
    rustup component add {{ args }}

rust-update:
    just rustup update

rust-add-rustfmt:
    just rust-add-component rustfmt

rust-add-clippy:
    just rust-add-component clippy

rust-add-rust-src:
    just rust-add-component rust-src

# Edit this project in VSCode
edit:
    code {{ project_root }}

# Ensure cargo command is installed
ensure-installed *args:
    #!/usr/bin/env bash
    cargo --list | grep -q {{ args }}
    if [[ "$?" -ne 0 ]]; then
        echo "ERROR: cargo-{{ args }} is not installed. Aborting."
        exit 1
    fi

# Lint code with clippy
lint:
    cargo fmt --all -- --check
    cargo sort --workspace --check
    cargo clippy --tests --workspace -- -D warnings

# format code with fmt
format:
    cargo fmt
    cargo sort --workspace

# Format code with rustfmt
rustfmt:
    find {{invocation_directory()}} -name \*.rs -exec rustfmt {} \;

#rustfmt *args:
#    cargo run --bin rustfmt -- {{args}}

# Bump all deps, including incompatible version upgrades
bump:
    just ensure-installed upgrade
    cargo update
    cargo upgrade --incompatible
    cargo test --workspace

# Clean build artifacts
[doc('Clean build artifacts')]
clean:
    cargo clean

# Build the program for release
[doc('Build {{su-exec-rs}} program')]
build:
    export $(grep -v '^#' .env | xargs) && cargo build --release
    test -f target/release/su-exec-rs && cp target/release/su-exec-rs bin/su-exec-rs

# Build the program for release
[doc('Build {{su-exec-rs}} program for release')]
build-release:
    export $(grep -v '^#' .env | xargs) && cargo build --release
    test -f target/release/su-exec-rs && cp target/release/su-exec-rs bin/su-exec-rs

# Run the program with arguments
[doc('Run stuff')]
run *args:
    cargo run --release -- {{ args }}

# Run tests in parallel with verbose output
test:
    cargo test -- --test-threads=1 --verbose

# Run the test suite with nexttest
nexttest:
    cargo nextest run --workspace