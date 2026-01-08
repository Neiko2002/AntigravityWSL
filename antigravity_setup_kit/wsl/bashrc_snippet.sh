# Export Browser to use wslview (opens Windows browser)
export BROWSER=wslview

# Suppress WSL Install Prompt for VSCode-forks
export DONT_PROMPT_WSL_INSTALL=1

# Bun Setup
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Antigravity Force Scale Factor (Fix for Blurry Text)
alias antigravity='antigravity --force-device-scale-factor=1'
