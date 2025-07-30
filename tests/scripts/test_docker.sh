#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 The Linux Foundation

set -e

# Enable exit on error and better error messages
trap 'echo "Error: Command \"$BASH_COMMAND\" failed at line $LINENO"; exit 1' ERR

# Test script for Docker image

# Variables
IMAGE_NAME='lf-hello-nginx'
IMAGE_TAG='test'
CONTAINER_NAME='test-container'
# Use environment variable if set, otherwise use default port
HOST_PORT=${TEST_HOST_PORT:-8080}
DOCKER_PORT=8080
MAX_RETRIES=5

# Find project root directory regardless of where script is called from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DOCKER_DIR="${PROJECT_ROOT}/docker"

# Print test header
echo 'Running Docker image tests...'
echo '----------------------------'

# Check if Docker is installed and running
if ! command -v docker >/dev/null 2>&1; then
    echo '❌ Error: Docker is not installed'
    exit 1
fi

# Check if Docker daemon is running
if ! docker info >/dev/null 2>&1; then
    echo '❌ Error: Docker daemon is not running'
    exit 1
fi

# Clean up any existing containers with the same name
echo 'Cleaning up any existing test containers...'
docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

# Build the Docker image
echo "Building Docker image..."
echo "Using Docker directory: ${DOCKER_DIR}"
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" "${DOCKER_DIR}"

# Check if port is already in use
if command -v nc >/dev/null 2>&1 && nc -z localhost "${HOST_PORT}" 2>/dev/null; then
    echo "⚠️ Warning: Port ${HOST_PORT} is already in use"

    # Try to find an available port
    for PORT in {8081..8100}; do
        if ! nc -z localhost "${PORT}" 2>/dev/null; then
            echo "ℹ️ Switching to available port: ${PORT}"
            HOST_PORT="${PORT}"
            break
        fi
    done
fi

# Run the container
echo "Starting container on port ${HOST_PORT}..."
docker run -d --name "${CONTAINER_NAME}" -p "${HOST_PORT}:${DOCKER_PORT}" \
    "${IMAGE_NAME}:${IMAGE_TAG}"

# Check if container started successfully
if ! docker ps | grep -q "${CONTAINER_NAME}"; then
    echo "❌ Error: Container failed to start properly"
    echo "Container logs:"
    docker logs "${CONTAINER_NAME}"
    docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    exit 1
fi

# Wait for container to start
echo 'Waiting for container to start...'
for i in $(seq 1 ${MAX_RETRIES}); do
    sleep 2
    if docker exec "${CONTAINER_NAME}" pgrep nginx >/dev/null 2>&1; then
        echo "✅ Nginx process is running"
        break
    fi
    if [ "$i" -eq ${MAX_RETRIES} ]; then
        echo "❌ Error: Nginx process failed to start after 10 seconds"
        echo "Container logs:"
        docker logs "${CONTAINER_NAME}"
        docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
        exit 1
    fi
    echo "Waiting for Nginx to start (attempt $i of ${MAX_RETRIES})..."
done

# Test the container
echo "Testing container on http://localhost:${HOST_PORT}..."
CURL_CMD="curl"
if ! command -v curl >/dev/null 2>&1; then
    if command -v wget >/dev/null 2>&1; then
        CURL_CMD="wget -qO-"
    else
        echo "❌ Error: Neither curl nor wget is installed"
        docker rm -f "${CONTAINER_NAME}"
        exit 1
    fi
fi

RESPONSE=$($CURL_CMD --max-time 5 "http://localhost:${HOST_PORT}" 2>&1) || true
if echo "${RESPONSE}" | grep -q "Hello Linux Foundation"; then
    echo "✅ Test passed: Found 'Hello Linux Foundation' message"
else
    echo '❌ Test failed: Message not found'
    echo "Curl response:"
    echo "${RESPONSE}"
    echo "Container logs:"
    docker logs "${CONTAINER_NAME}"
    echo "Container status:"
    docker inspect --format '{{.State.Status}}' "${CONTAINER_NAME}"
    docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    exit 1
fi

# Test health endpoint
echo 'Testing health endpoint...'
HEALTH_RESPONSE=$($CURL_CMD --max-time 5 "http://localhost:${HOST_PORT}/health" 2>&1) || true
if echo "${HEALTH_RESPONSE}" | grep -q "healthy"; then
    echo "✅ Test passed: Health endpoint working"
else
    echo "❌ Test failed: Health endpoint not working"
    echo "Curl response:"
    echo "${HEALTH_RESPONSE}"
    echo "Container logs:"
    docker logs "${CONTAINER_NAME}"
    echo "Container process list:"
    docker exec "${CONTAINER_NAME}" ps aux || true
    docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    exit 1
fi

# Clean up
echo 'Cleaning up...'
docker rm -f "${CONTAINER_NAME}"

echo '----------------------------'
echo '✅ All tests passed successfully!'
