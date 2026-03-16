#!/usr/bin/env bash
set -euo pipefail

# Push project Docker image to Docker Hub.
# Usage:
#   DOCKERHUB_USER=<user> ./scripts/push_dockerhub.sh
#   DOCKERHUB=<user> ./scripts/push_dockerhub.sh
# Optional:
# DOCKER_IMAGE_NAME=qlik-sense-mcp-server
# DOCKER_IMAGE_TAG=1.0.0
# PUSH_LATEST=true

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if [[ -f .dockerhub.env ]]; then
  # shellcheck disable=SC1091
  source .dockerhub.env
fi

DOCKERHUB_USER="${DOCKERHUB_USER:-${DOCKERHUB:-}}"
if [[ -z "${DOCKERHUB_USER}" ]]; then
  echo "Set DOCKERHUB_USER (or DOCKERHUB) via env var or .dockerhub.env" >&2
  exit 1
fi

DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-qlik-sense-mcp-server}"
DOCKER_IMAGE_TAG="${DOCKER_IMAGE_TAG:-$(grep '^version = ' pyproject.toml | sed 's/version = "\(.*\)"/\1/')}"
PUSH_LATEST="${PUSH_LATEST:-false}"

LOCAL_IMAGE="${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
REMOTE_VERSION="${DOCKERHUB_USER}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
REMOTE_LATEST="${DOCKERHUB_USER}/${DOCKER_IMAGE_NAME}:latest"

echo "Building ${LOCAL_IMAGE}"
docker build -t "${LOCAL_IMAGE}" .

echo "Tagging ${LOCAL_IMAGE} -> ${REMOTE_VERSION}"
docker tag "${LOCAL_IMAGE}" "${REMOTE_VERSION}"

echo "Pushing ${REMOTE_VERSION}"
docker push "${REMOTE_VERSION}"

if [[ "${PUSH_LATEST}" == "true" ]]; then
  echo "Tagging ${LOCAL_IMAGE} -> ${REMOTE_LATEST}"
  docker tag "${LOCAL_IMAGE}" "${REMOTE_LATEST}"

  echo "Pushing ${REMOTE_LATEST}"
  docker push "${REMOTE_LATEST}"
fi

echo "Done"
