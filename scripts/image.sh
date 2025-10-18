#!/bin/bash
# Minimal subset of the start script to try and setup the runner during image build time

# 'set +e' continues the execution of a script even when a command or pipeline has an error.
set +e

log() {
  dt_stamp=$(date -u +"%Y-%m-%d %H:%M:%SZ")
  echo "${dt_stamp}: $1"
}

# Get to the current directory
current_dir="$(dirname "$(realpath "$0")")"
source "${current_dir}/detector.sh"
source "${current_dir}/download.sh"

download_runner
