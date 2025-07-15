<!--
SPDX-License-Identifier: Apache-2.0
SPDX-FileCopyrightText: 2025 The Linux Foundation
-->

# 🐳 Test Docker Project

Sample project that builds a Docker image container.

The container runs NGINX and hosts a web page displaying:

`Hello Linux Foundation!`

## Overview

This project demonstrates a simple Docker container build with GitHub Actions
workflow integration. It includes:

- Docker configuration for an NGINX web server
- GitHub Actions workflow for automated builds
- Makefile for local development
- Pre-commit hooks for code quality

## Usage Example

### Local Development

```bash
# Build the Docker image
make build

# Run the container
make run

# Stop and remove the container
make stop

# Remove the container and image
make clean
```

### GitHub Actions Workflow

<!-- markdownlint-disable MD046 -->

```yaml
name: Build Docker Image
uses: lfreleng-actions/test-docker-project/.github/workflows/testing.yaml@main
```

<!-- markdownlint-enable MD046 -->

## Implementation Details

The project builds a lightweight NGINX container that serves a static HTML page.
Key features:

- Multi-platform build support via Docker Buildx
- Layer caching for faster builds
- Non-root container user for better security
- Custom Nginx configuration to support running as non-root
- Temporary files stored in non-privileged directories
- Health check endpoint at `/health`
- Automated testing in CI/CD pipeline

## Requirements

- Docker
- Make (for local development)
- Git (for version control)

Run `make install-tools` to automatically install dependencies on supported platforms.

## Testing

### Automated Tests

The project includes automated tests to check the Docker image functionality:

```bash
# Run tests (works from any directory)
./tests/scripts/test_docker.sh

# Run tests with a custom port
TEST_HOST_PORT=9090 ./tests/scripts/test_docker.sh
```

The test script validates:

- Building the Docker image
- Running a container from the image
- Checking the web page shows the expected message
- Verifying the health endpoint is working
- Cleaning up all test resources

The script is path-independent and works on both macOS and Linux platforms.
It automatically detects if the default port (8080) is in use and will try
alternative ports if necessary. You can also specify a custom port by setting
the `TEST_HOST_PORT` environment variable.

### Non-Root Nginx Configuration

The Docker container runs Nginx as a non-root user for improved security.
To achieve this, we use:

- Custom main Nginx configuration file that sets the PID file location to a
  non-privileged directory
- Temporary directories created and owned by the non-root user
- Proper file permissions set before switching to the non-root user
- All logging and cache files redirected to writable locations
- Comprehensive process monitoring in the test script to ensure proper startup
