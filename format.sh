#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

shopt -s globstar

stylua $SCRIPT_DIR/**/*.lua