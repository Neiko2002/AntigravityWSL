#!/bin/bash
# Antigravity Shim for Wayland/Ozone
# Wraps the binary to force Wayland support on WSLg

BIN_PATH="/opt/antigravity-ide/antigravity-ide"
if [ ! -f "$BIN_PATH" ]; then
    BIN_PATH="/usr/share/antigravity/antigravity"
fi

if [ ! -f "$BIN_PATH" ]; then
    echo "Error: Antigravity binary not found."
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
