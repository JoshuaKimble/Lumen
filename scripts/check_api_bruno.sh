#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COLLECTION_DIR="$ROOT_DIR/apps/api/bruno/lumen-api"
ENV_NAME="local"
ENV_FILE=""
EXTRA_ARGS=()

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/check_api_bruno.sh [options] [-- <bru-run-args>]

Options:
  --env <name>       Environment name to resolve in collection environments.
                     Default: local
  --env-file <path>  Explicit environment file (.bru or .json).
  -h, --help         Show this help.

Environment file resolution when --env-file is not provided:
  1. apps/api/bruno/lumen-api/environments/<env>.local.json
  2. apps/api/bruno/lumen-api/environments/<env>.local.bru
  3. apps/api/bruno/lumen-api/environments/<env>.json
  4. apps/api/bruno/lumen-api/environments/<env>.bru
  5. apps/api/bruno/lumen-api/environments/<env>.example.json
  6. apps/api/bruno/lumen-api/environments/<env>.example.bru

Examples:
  ./scripts/check_api_bruno.sh
  ./scripts/check_api_bruno.sh --env cloud-shared
  ./scripts/check_api_bruno.sh --env-file apps/api/bruno/lumen-api/environments/cloud-shared.local.json
  ./scripts/check_api_bruno.sh -- --tags=smoke
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)
      ENV_NAME="${2:-}"
      if [[ -z "$ENV_NAME" ]]; then
        echo "Missing value for --env" >&2
        exit 1
      fi
      shift 2
      ;;
    --env-file)
      ENV_FILE="${2:-}"
      if [[ -z "$ENV_FILE" ]]; then
        echo "Missing value for --env-file" >&2
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      EXTRA_ARGS=("$@")
      break
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ! -d "$COLLECTION_DIR" ]]; then
  echo "Bruno collection not found: $COLLECTION_DIR" >&2
  exit 1
fi

if [[ -z "$ENV_FILE" ]]; then
  CANDIDATES=(
    "$COLLECTION_DIR/environments/${ENV_NAME}.local.json"
    "$COLLECTION_DIR/environments/${ENV_NAME}.local.bru"
    "$COLLECTION_DIR/environments/${ENV_NAME}.json"
    "$COLLECTION_DIR/environments/${ENV_NAME}.bru"
    "$COLLECTION_DIR/environments/${ENV_NAME}.example.json"
    "$COLLECTION_DIR/environments/${ENV_NAME}.example.bru"
  )
  for candidate in "${CANDIDATES[@]}"; do
    if [[ -f "$candidate" ]]; then
      ENV_FILE="$candidate"
      break
    fi
  done
fi

if [[ -z "$ENV_FILE" ]]; then
  echo "No environment file found for env '$ENV_NAME'." >&2
  echo "Checked under: $COLLECTION_DIR/environments" >&2
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Environment file not found: $ENV_FILE" >&2
  exit 1
fi

if command -v bru >/dev/null 2>&1; then
  BRU_CMD=(bru)
elif command -v npx >/dev/null 2>&1; then
  BRU_CMD=(npx --yes @usebruno/cli)
else
  echo "Bruno CLI not found. Install bru, or install Node.js so npx can run @usebruno/cli." >&2
  exit 1
fi

echo "[bruno-check] collection: $COLLECTION_DIR"
echo "[bruno-check] env file:   $ENV_FILE"
if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  echo "[bruno-check] extra args: ${EXTRA_ARGS[*]}"
fi

cd "$COLLECTION_DIR"
"${BRU_CMD[@]}" run --env-file "$ENV_FILE" "${EXTRA_ARGS[@]}"
