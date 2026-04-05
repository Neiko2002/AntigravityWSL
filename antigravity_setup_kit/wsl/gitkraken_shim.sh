#!/bin/bash
# GitKraken Shim for Wayland/Ozone
# Wraps the binary to force Wayland support on WSLg
# (Fixes X11 frame and strange edges)

BIN_PATH="/usr/share/gitkraken/gitkraken"

if [ ! -f "$BIN_PATH" ]; then
    echo "Error: GitKraken binary not found at $BIN_PATH."
    exit 1
fi

# Launch with Wayland support
# We add WaylandWindowDecorations to encourage modern decoration handling
exec "$BIN_PATH" --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland "$@"
