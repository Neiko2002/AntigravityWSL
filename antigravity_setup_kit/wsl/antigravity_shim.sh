#!/bin/bash
# Antigravity Shim for Wayland/Ozone
# Wraps the binary to force Wayland support on WSLg

BIN_PATH="/usr/share/antigravity/antigravity"

if [ ! -f "$BIN_PATH" ]; then
    echo "Error: Antigravity binary not found at $BIN_PATH."
    echo "Please ensure the installation process finished correctly."
    exit 1
fi

# Check if we are running as a node process (used by internal CLI tools)
if [ -n "$ELECTRON_RUN_AS_NODE" ]; then
    # Pass through without graphics flags
    exec "$BIN_PATH" "$@"
else
    # Launch with Wayland support
    exec "$BIN_PATH" --enable-features=UseOzonePlatform --ozone-platform=wayland "$@"
fi
