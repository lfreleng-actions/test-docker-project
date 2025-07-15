# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 The Linux Foundation

.PHONY: help build run stop check-tools install-tools clean test

# Variables
IMAGE_NAME := lf-hello-nginx
IMAGE_TAG := test
CONTAINER_NAME := lf-hello-container
DOCKER_PORT := 8080
HOST_PORT := 8080

# Detect OS
OS := $(shell uname -s)

# Help message
help:
	@echo 'Linux Foundation Docker Test Project'
	@echo ''
	@echo 'Usage:'
	@echo '  make build          Build the docker image'
	@echo '  make run            Run the container'
	@echo '  make stop           Stop the container'
	@echo '  make check-tools    Check if required tools are installed'
	@echo '  make install-tools  Install required tools (may require sudo)'
	@echo '  make clean          Remove the container and image'
	@echo '  make test           Run tests for the docker image'
	@echo '  make help           Show this help message'

# Check if Docker is installed
check-tools:
	@echo 'Checking for required tools...'
	@if command -v docker >/dev/null 2>&1; then \
		echo '✅ Docker is installed'; \
	else \
		echo '❌ Docker is not installed'; \
		exit 1; \
	fi

# Install Docker if not present
install-tools:
	@echo 'Installing required tools...'
	@if ! command -v docker >/dev/null 2>&1; then \
		echo 'Installing Docker...'; \
		if [ "$(OS)" = 'Darwin' ]; then \
			echo 'Please install Docker Desktop for Mac from https://www.docker.com/products/docker-desktop'; \
			echo 'Or use Homebrew: brew install --cask docker'; \
		elif [ "$(OS)" = 'Linux' ]; then \
			if command -v apt-get >/dev/null 2>&1; then \
				sudo apt-get update && sudo apt-get install -y docker.io; \
				sudo systemctl enable docker && sudo systemctl start docker; \
				sudo usermod -aG docker $$USER; \
				echo 'Please log out and back in for group changes to take effect'; \
			elif command -v dnf >/dev/null 2>&1; then \
				sudo dnf -y install docker; \
				sudo systemctl enable docker && sudo systemctl start docker; \
				sudo usermod -aG docker $$USER; \
				echo 'Please log out and back in for group changes to take effect'; \
			else \
				echo 'Unsupported Linux distribution. Please install Docker manually.'; \
				exit 1; \
			fi; \
		else \
			echo 'Unsupported operating system. Please install Docker manually.'; \
			exit 1; \
		fi; \
	else \
		echo 'Docker is already installed.'; \
	fi

# Build the Docker image
build: check-tools
	@echo 'Building Docker image...'
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) ./docker

# Run the container
run: check-tools
	@echo 'Running container...'
	docker run -d -p $(HOST_PORT):$(DOCKER_PORT) --name $(CONTAINER_NAME) $(IMAGE_NAME):$(IMAGE_TAG)
	@echo "Container is running at http://localhost:$(HOST_PORT)"

# Stop the container
stop: check-tools
	@echo 'Stopping container...'
	-docker stop $(CONTAINER_NAME)
	-docker rm $(CONTAINER_NAME)

# Clean up resources
clean: stop
	@echo 'Removing image...'
	-docker rmi $(IMAGE_NAME):$(IMAGE_TAG)

# Run tests
test: check-tools
	@echo 'Running Docker image tests...'
	@$(CURDIR)/tests/scripts/test_docker.sh
