#!/bin/bash

# Script to generate SEMP client code using Docker volumes instead of bind mounts
# This allows the script to work with remote Docker daemons over TCP

set -e

# Configuration
IMAGE_TAG="solace-semp-swagger-codegen-cli:3.0.27"
VOLUME_NAME="semp-generation-vol-$$"
# VOLUME_NAME="semp-generation-vol-$(date +%s)-$(hostname)-$(openssl rand -hex 4)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cleanup() {
    docker volume rm "$VOLUME_NAME" 2>/dev/null || true
}
trap cleanup EXIT

# Step 1: Build the Docker image
echo "Building image..."
docker buildx build -f "$SCRIPT_DIR/Dockerfile" -t "$IMAGE_TAG" --build-arg SWAGGER_VER=3.0.27 "$SCRIPT_DIR" --load

# Step 2: Create a Docker volume
echo "Creating volume..."
docker volume create "$VOLUME_NAME"

# Copy input files to volume
TEMP_CONTAINER="temp-setup-$$"
docker run --name "$TEMP_CONTAINER" -v "$VOLUME_NAME:/workspace" alpine:latest true
docker cp "$SCRIPT_DIR/spec" "$TEMP_CONTAINER:/workspace/"
docker rm "$TEMP_CONTAINER"

# Step 3: Run the 3 codegen commands
echo "Generating clients..."
docker run --rm -v "$VOLUME_NAME:/workspace" -w /workspace "$IMAGE_TAG" \
    generate -l go -i /workspace/spec/spec_action.json -o /workspace/action \
    --type-mappings boolean=*bool --additional-properties packageName=action

docker run --rm -v "$VOLUME_NAME:/workspace" -w /workspace "$IMAGE_TAG" \
    generate -l go -i /workspace/spec/spec_config.json -o /workspace/config \
    --type-mappings boolean=*bool --additional-properties packageName=config

docker run --rm -v "$VOLUME_NAME:/workspace" -w /workspace "$IMAGE_TAG" \
    generate -l go -i /workspace/spec/spec_monitor.json -o /workspace/monitor \
    --type-mappings boolean=*bool --additional-properties packageName=monitor

# Step 4: Run and mount a dummy container to the volume
echo "Copying generated files..."
DUMMY_CONTAINER="temp-output-$$"
docker run --name "$DUMMY_CONTAINER" -v "$VOLUME_NAME:/workspace" alpine:latest true

# Step 5: Docker cp from the dummy container
docker cp "$DUMMY_CONTAINER:/workspace/action" "$SCRIPT_DIR/"
docker cp "$DUMMY_CONTAINER:/workspace/config" "$SCRIPT_DIR/"
docker cp "$DUMMY_CONTAINER:/workspace/monitor" "$SCRIPT_DIR/"

# Step 6: Cleanup resources
docker rm "$DUMMY_CONTAINER"
echo "Generation complete!"
