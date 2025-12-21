#!/bin/bash

# Robust installer for Schmudpilot on comma 3X
# This script is intended to be run via the 'customsoftware' URL prompt

set -e

REPO_URL="https://github.com/rschmud/Pilot.git"
BRANCH="Schmudpilot"
INSTALL_PATH="/data/openpilot"

echo "--- Schmudpilot Installer ---"

# 1. Stop openpilot services if they are running
echo "Stopping openpilot services..."
if [ -f /data/openpilot/launch_openpilot.sh ]; then
  /data/openpilot/launch_openpilot.sh --stop || true
fi

# 2. Prepare /data directory
echo "Preparing installation directory..."
cd /data
if [ -d "$INSTALL_PATH" ]; then
  echo "Removing existing installation..."
  rm -rf "$INSTALL_PATH"
fi

# 3. Clone the repository
echo "Cloning $REPO_URL (branch: $BRANCH)..."
git clone -b "$BRANCH" --depth 1 "$REPO_URL" "$INSTALL_PATH"

# 4. Navigate to the new installation
cd "$INSTALL_PATH"

# 5. Initialize and update submodules
echo "Updating submodules..."
git submodule update --init --recursive

# 6. Build openpilot
echo "Building openpilot... this may take a while."
# Ensure we are using the environment expected by the build system
if [ -f "tools/install_base_packages.sh" ]; then
  # Usually not needed on a stock comma device as packages are pre-installed
  # but kept for compatibility with other environments.
  echo "Checking for base packages..."
  # ./tools/install_base_packages.sh # Skipping to save time on device
fi

# Use scons to build
# -j$(nproc) uses all available CPU cores
scons -j$(nproc)

echo "Build complete!"

# 7. Finalize and Restart
echo "Installation successful. Restarting..."

# The comma device will usually handle the restart after the custom software script finishes,
# but we can trigger it or just start the services.
if [ -f "./launch_openpilot.sh" ]; then
  exec ./launch_openpilot.sh
else
  echo "Launch script not found, please reboot your device."
fi
