#!/bin/bash

# ==============================================================================
# Antigravity WSL Setup & Update Script
# ==============================================================================
# This script runs inside the Linux environment. It automatically keeps your IDE, 
# dependencies, and system configurations up to date without asking for input.
# It is designed to be "idempotent", meaning it's 100% safe to run multiple times.
# ==============================================================================

set -e

# WHY DEBIAN_FRONTEND=noninteractive?
# Behind the scenes, Ubuntu package installations sometimes show blue terminal screens 
# asking you about keyboard layouts or timezones. This setting skips those screens
# by taking the default choices automatically, preventing the script from freezing.
export DEBIAN_FRONTEND=noninteractive

# Setup Terminal Colors for friendly output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Starting Antigravity WSL Setup / Update...${NC}"

# Switch to the directory where this script is located.
# This ensures that relative files like 'antigravity-repo-key.gpg' are found 
# even if the script is called from another location (like PowerShell).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Security Check: Linux expects normal users to run setup scripts, elevating
# to 'root' via 'sudo' only when necessary.
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}❌ Please run this script as your normal user, not 'root' (It uses sudo internally).${NC}"
  exit 1
fi

CURRENT_USER=$(whoami)
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

# ------------------------------------------------------------------------------
# STEP 1: Setting up Software Repositories
# ------------------------------------------------------------------------------
# WHY DO WE NEED TO CONFIGURE APT?
# Ubuntu's default "App Store" (APT) doesn't know what Antigravity is. We have to 
# give it Google's secure key (antigravity-repo-key.gpg) and the download link 
# so it knows where to pull updates from securely.
echo -e "\n${BLUE}[1/6] 🛠️  Configuring APT and installing/updating dependencies...${NC}"
sudo mkdir -p /etc/apt/keyrings
sudo cp antigravity-repo-key.gpg /etc/apt/keyrings/antigravity-repo-key.gpg

# Write the download location to APT's list of sources.
echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null

echo -e "  ${YELLOW}➔ Updating apt repositories...${NC}"
sudo apt update -y

# ------------------------------------------------------------------------------
# STEP 2: Installing Dependencies and the IDE
# ------------------------------------------------------------------------------
# We install standard Linux graphics and sound drivers so the IDE can run smoothly.
# NOTE: The 't64' package names (like libasound2t64) are required for modern 
# Ubuntu 24.04 compatibility.
echo -e "  ${YELLOW}➔ Installing/Updating system dependencies and Antigravity...${NC}"
sudo apt install -y curl wget git jq wslu lxterminal yaru-theme-gtk libfuse2t64 libnss3 libasound2t64 libsecret-1-0 gnome-keyring libpam-gnome-keyring libatk-bridge2.0-0t64 libgtk-3-0t64 libgbm1 fonts-noto-color-emoji fonts-liberation fonts-font-awesome fonts-noto-cjk

# We explicitly tell APT to upgrade antigravity if it's already installed,
# ensuring you always get the latest version.
sudo apt install --only-upgrade -y antigravity || sudo apt install -y antigravity

# ------------------------------------------------------------------------------
# STEP 3: Setup Node Runtime (Bun) and Gemini CLI
# ------------------------------------------------------------------------------
# WHY BUN?
# Bun is a faster, modern alternative to Node.js. It's required to run the Gemini 
# command line AI tool because it powers our scripts behind the scenes.
echo -e "\n${BLUE}[1.5/6] 🐰 Installing Bun and Gemini CLI...${NC}"
if ! command -v bun &> /dev/null; then
    echo -e "  ${YELLOW}➔ Bun not found. Installing bun...${NC}"
    curl -fsSL https://bun.sh/install | bash
    # Source bun locally for the rest of the script so we can use it immediately
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
fi

# WHY DO WE SYMLINK NODE TO BUN?
# The Gemini CLI (and many npm packages) hardcode "#!/usr/bin/env node" at the 
# top of their files. Since we refuse to install Node.js (we only use Bun), the 
# scripts crash. Creating a 'node' symlink that points to 'bun' tricks the 
# system into using Bun to run Node scripts flawlessly.
echo -e "  ${YELLOW}➔ Creating global 'node' alias to 'bun' to satisfy dependencies...${NC}"
sudo ln -sf "$HOME/.bun/bin/bun" /usr/local/bin/node

echo -e "  ${YELLOW}➔ Installing @google/gemini-cli globally via bun...${NC}"
bun install -g @google/gemini-cli
echo -e "  ${GREEN}✅ gemini-cli installed. Run 'gemini' to authenticate later.${NC}"

# Install the Gemini app icon so you can launch it from the Windows Start Menu.
echo -e "\n${BLUE}[1.6/6] 🖥️  Installing Gemini CLI Desktop Icon...${NC}"
sudo cp gemini.desktop /usr/share/applications/
# Fix CRLF line endings added by Windows editors, which completely breaks WSLg's desktop parser
sudo sed -i 's/\r$//' /usr/share/applications/gemini.desktop
echo -e "  ${GREEN}✅ gemini.desktop installed (fixed line endings).${NC}"

# ------------------------------------------------------------------------------
# STEP 4: Shell Configuration (.bashrc)
# ------------------------------------------------------------------------------
# Here we add environment variables to your terminal startup profile (.bashrc)
# ensuring that things like 'wslu' (which lets Linux open links in your Windows 
# web browser) work properly right out of the box.
echo -e "\n${BLUE}[2/6] ⚙️  Configuring ~/.bashrc...${NC}"
if grep -q "Antigravity Setup Configuration" ~/.bashrc; then
    echo -e "  ${GREEN}✅ .bashrc is already configured.${NC}"
else
    echo -e "\n# --- Antigravity Setup Configuration ---" >> ~/.bashrc
    cat bashrc_snippet.sh >> ~/.bashrc
    echo -e "\n# ---------------------------------------" >> ~/.bashrc
    echo -e "  ${GREEN}✅ Configuration appended to .bashrc.${NC}"
fi

# ------------------------------------------------------------------------------
# STEP 5: IDE Shim Installation
# ------------------------------------------------------------------------------
# WHY DO WE NEED A SHIM?
# Antigravity is an Electron app. To avoid fuzzy, pixelated text on Windows high-DPI 
# screens, we force it to use 'Wayland' (a modern Linux display protocol). The shim 
# is a tiny wrapper script that intercepts the start command and injects these flags automatically.
echo -e "\n${BLUE}[3/6] 📦 Installing Antigravity Shim...${NC}"
sudo cp antigravity_shim.sh /usr/local/bin/antigravity
sudo chmod +x /usr/local/bin/antigravity
echo -e "  ${GREEN}✅ Shim installed.${NC}"

# ------------------------------------------------------------------------------
# STEP 6: Visual Modernization (GTK & Terminal)
# ------------------------------------------------------------------------------
# WHY DO WE DO THIS?
# By default, Linux apps in WSL look like they are from the 90s. We install a 
# modern dark theme (Yaru-dark) and configure a black/white color scheme for 
# lxterminal to match the professional Windows 11 aesthetic.
echo -e "\n${BLUE}[3.5/6] 🎨 Modernizing Visuals (Dark Mode)...${NC}"

# Configure GTK 3 for Dark Mode
mkdir -p ~/.config/gtk-3.0
cat > ~/.config/gtk-3.0/settings.ini <<EOF
[Settings]
gtk-theme-name=Yaru-dark
gtk-icon-theme-name=Yaru
gtk-font-name=Ubuntu 11
gtk-application-prefer-dark-theme=1
EOF

# Configure lxterminal (Gemini CLI) for a clean dark look
mkdir -p ~/.config/lxterminal
cp lxterminal.conf ~/.config/lxterminal/lxterminal.conf
echo -e "  ${GREEN}✅ GTK Dark Mode and lxterminal configuration applied.${NC}"

# ------------------------------------------------------------------------------
# STEP 7: GitKraken Shim Installation (if present)
# ------------------------------------------------------------------------------
# Similar to Antigravity, GitKraken is an Electron app. We apply a Wayland shim 
# to ensure it uses a native-style frame and sharp rendering on Windows.
if [ -f "/usr/bin/gitkraken" ] || [ -f "/usr/share/gitkraken/gitkraken" ]; then
    echo -e "\n${BLUE}[3.6/6] 📦 Installing GitKraken Shim...${NC}"
    sudo cp gitkraken_shim.sh /usr/local/bin/gitkraken
    sudo chmod +x /usr/local/bin/gitkraken
    
    # Patch the desktop file to use the shim
    GK_SYS_FILE="/usr/share/applications/gitkraken.desktop"
    if [ -f "$GK_SYS_FILE" ]; then
        # Robustly replace any Exec= path with our shim
        sudo sed -i 's|^Exec=.*|Exec=/usr/local/bin/gitkraken %U|g' "$GK_SYS_FILE"
    fi
    echo -e "  ${GREEN}✅ GitKraken shim installed and patched.${NC}"
fi

# ------------------------------------------------------------------------------
# STEP 8: AI Context Initialization
# ------------------------------------------------------------------------------
# Copies initial knowledge into the ~/.gemini folder so the AI agent remembers 
# default working directory preferences and rules right from the start.
echo -e "\n${BLUE}[4/6] 🧠 Bootstrapping Agent Context (GEMINI.md)...${NC}"
mkdir -p ~/.gemini
cp GEMINI.md ~/.gemini/
echo -e "  ${GREEN}✅ Agent memory restored to ~/.gemini/GEMINI.md${NC}"

# ------------------------------------------------------------------------------
# STEP 9: Security Hardening (wsl.conf)
# ------------------------------------------------------------------------------
# WHY DO WE MODIFY wsl.conf?
# By default, WSL can read and write to your entire Windows C: drive. If a script goes 
# wrong in Linux (like a rogue "rm -rf"), it could destroy Windows files. 
# We configure this file to mount your C: drive as "Read-Only" (ro). You can still 
# develop safely in ~/lang inside the Linux container without harming the host.
echo -e "\n${BLUE}[5/6] 🛡️  Applying Hardened WSL Configuration...${NC}"
sudo bash -c "cat > /etc/wsl.conf <<EOF
[boot]
systemd=true

[automount]
enabled = true
options = \"metadata,uid=${CURRENT_UID},gid=${CURRENT_GID},ro\"
mountFsTab = true

[user]
default=${CURRENT_USER}
EOF"
echo -e "  ${GREEN}✅ /etc/wsl.conf freshly generated for user '${CURRENT_USER}'.${NC}"

# ------------------------------------------------------------------------------
# STEP 10: Start Menu Cleanup
# ------------------------------------------------------------------------------
# Finally, we hide background tools (like wslview and lxterminal) from 
# the Windows Start Menu so it doesn't get cluttered with useless icons, and 
# we ensure the main Antigravity icon triggers our shim instead of the raw binary.
echo -e "\n${BLUE}[6/6] 🧹 Cleaning Start Menu...${NC}"
for app in wslview lxterminal; do
    SYS_FILE="/usr/share/applications/${app}.desktop"
    if [ -f "$SYS_FILE" ]; then
        # Remove any existing overrides before writing to prevent duplicate lines
        sudo sed -i '/NoDisplay=/d' "$SYS_FILE"
        sudo sed -i '/X-WSL-No-Export=/d' "$SYS_FILE" 2>/dev/null || true
        echo "NoDisplay=true" | sudo tee -a "$SYS_FILE" > /dev/null
        echo "X-WSL-No-Export=true" | sudo tee -a "$SYS_FILE" > /dev/null
    fi
done

# Patch system Antigravity entry to use shim
ANTIGRAVITY_SYS_FILE="/usr/share/applications/antigravity.desktop"
if [ -f "$ANTIGRAVITY_SYS_FILE" ]; then
    echo -e "  ${YELLOW}➔ Patching system antigravity.desktop to use shim...${NC}"
    sudo sed -i 's|Exec=/usr/share/antigravity/antigravity|Exec=/usr/local/bin/antigravity|g' "$ANTIGRAVITY_SYS_FILE"
    sudo sed -i '/NoDisplay=/d' "$ANTIGRAVITY_SYS_FILE"
    sudo sed -i '/X-WSL-No-Export=/d' "$ANTIGRAVITY_SYS_FILE" 2>/dev/null || true
    echo "X-WSL-No-Export=false" | sudo tee -a "$ANTIGRAVITY_SYS_FILE" > /dev/null
fi

# Remove user-level desktop overrides to stick to system defaults
rm -f ~/.local/share/applications/antigravity.desktop ~/.local/share/applications/wslview.desktop
update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
echo -e "  ${GREEN}✅ Start Menu cleaned.${NC}"

echo -e "\n${GREEN}🎉 Done! Antigravity is setup and updated.${NC}"
echo -e "${YELLOW}⚠️  IMPORTANT: If you made changes to wsl.conf, please run 'wsl --shutdown' from Windows PowerShell to apply them.${NC}"