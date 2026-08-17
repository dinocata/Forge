#!/bin/sh

set -eu

PROJECT_ROOT="$(git rev-parse --show-toplevel)"

git -C "${PROJECT_ROOT}" config core.hooksPath Scripts/git-hooks
echo "Configured Git to use hooks from Scripts/git-hooks."
