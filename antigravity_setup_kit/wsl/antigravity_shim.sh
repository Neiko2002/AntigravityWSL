#!/bin/bash
# Antigravity Shim for Wayland/Ozone
# Wraps the binary to force Wayland support on WSLg

# Check if we are running as a node process (used by internal CLI tools)
if [ -n "$ELECTRON_RUN_AS_NODE" ]; then
    # Pass through without graphics flags
    exec "/usr/share/antigravity/antigravity" "$@"
else
    # Launch with Wayland support
    exec "/usr/share/antigravity/antigravity" --enable-features=UseOzonePlatform --ozone-platform=wayland "$@"
fi
