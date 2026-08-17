#!/bin/sh

set -eu

PROJECT_ROOT="$(git rev-parse --show-toplevel)"

# Forge is a pure SwiftPM package, so there is no Xcode build phase and no
# SwiftLint plugin dependency to resolve a binary from — adding one would push a
# build-tool dependency onto every consumer of the package. The pinned binary an
# Xcode project already resolved is preferred over whatever is on PATH so that
# this script and the consuming app agree on a SwiftLint version; a bare checkout
# falls back to PATH.
SWIFTLINT=""

for candidate in "${HOME}/Library/Developer/Xcode/DerivedData/"*/SourcePackages/artifacts/swiftlintplugins/SwiftLintBinary/SwiftLintBinary.artifactbundle/macos/swiftlint; do
    if [ -x "${candidate}" ]; then
        SWIFTLINT="${candidate}"
        break
    fi
done

if [ -z "${SWIFTLINT}" ] && command -v swiftlint >/dev/null 2>&1; then
    SWIFTLINT="$(command -v swiftlint)"
fi

if [ -z "${SWIFTLINT}" ]; then
    echo "error: SwiftLint executable not found. Install SwiftLint, or resolve the Swift packages of an Xcode project that pins it."
    exit 1
fi

SWIFTLINT_CONFIG="${PROJECT_ROOT}/.swiftlint.yml"

cd "${PROJECT_ROOT}"

if [ "${SWIFTLINT_AUTOCORRECT:-0}" = "1" ]; then
    "${SWIFTLINT}" lint --fix --config "${SWIFTLINT_CONFIG}"
fi

set -- lint --config "${SWIFTLINT_CONFIG}"

if [ "${SWIFTLINT_STRICT:-0}" = "1" ]; then
    set -- "$@" --strict
fi

if [ "${SWIFTLINT_COLOR:-0}" != "1" ]; then
    exec "${SWIFTLINT}" "$@"
fi

OUTPUT_FILE="$(mktemp)"
trap 'rm -f "${OUTPUT_FILE}"' EXIT

set +e
"${SWIFTLINT}" "$@" >"${OUTPUT_FILE}" 2>&1
SWIFTLINT_STATUS=$?
set -e

RED="$(printf '\033[31m')"
YELLOW="$(printf '\033[33m')"
RESET="$(printf '\033[0m')"

while IFS= read -r line; do
    case "${line}" in
        *"Found 0 violations"*)
            printf '%s\n' "${line}"
            ;;
        *" 0 serious in "*)
            printf '%s%s%s\n' "${YELLOW}" "${line}" "${RESET}"
            ;;
        *": error:"*|*" serious in "*)
            printf '%s%s%s\n' "${RED}" "${line}" "${RESET}"
            ;;
        *": warning:"*|*" violation in "*)
            printf '%s%s%s\n' "${YELLOW}" "${line}" "${RESET}"
            ;;
        *)
            printf '%s\n' "${line}"
            ;;
    esac
done <"${OUTPUT_FILE}"

exit "${SWIFTLINT_STATUS}"
