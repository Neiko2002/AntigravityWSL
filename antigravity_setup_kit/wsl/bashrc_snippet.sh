# Export Browser to use wslview (opens Windows browser)
export BROWSER=wslview

# Suppress WSL Install Prompt for VSCode-forks
export DONT_PROMPT_WSL_INSTALL=1

# Bun Setup
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Antigravity Force Scale Factor (Fix for Blurry Text)
alias antigravity='antigravity --force-device-scale-factor=1'

# Keyring & Secret Service Integration
# Ensures that apps (like gemini-cli) can securely access stored credentials.
if [ -n "$DISPLAY" ]; then
    dbus-update-activation-environment --all > /dev/null 2>&1
fi
# Start gnome-keyring-daemon components if not already active
eval $(gnome-keyring-daemon --start --components=secrets 2>/dev/null)
export SSH_AUTH_SOCK
