#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONOREPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TESTS_DIR="${MONOREPO_ROOT}/tests"
LIBS_DIR="${TESTS_DIR}/libs"

BATS_EXECUTABLE="${LIBS_DIR}/bats-core/bin/bats"

if [[ ! -x "${BATS_EXECUTABLE}" ]]; then
    echo "ERROR: bats-core not found at ${BATS_EXECUTABLE}" >&2
    echo "Please ensure bats-core is installed in ${LIBS_DIR}/bats-core" >&2
    exit 1
fi

echo "Running BATS tests..."
echo "Test directory: ${TESTS_DIR}"
echo "============================================"

if [[ -n "${1:-}" ]]; then
    "${BATS_EXECUTABLE}" "${1}"
else
    "${BATS_EXECUTABLE}" "${TESTS_DIR}"/*.bats
fi

echo "============================================"
echo "All tests completed!"
