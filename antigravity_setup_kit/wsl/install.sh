#!/bin/bash

# Antigravity WSL Setup Script
# Run this INSIDE the WSL environment.

set -e

echo "Starting WSL Setup..."

# 1. Configure APT and Install Dependencies
echo "[1/7] Configuring APT and installing dependencies..."
sudo mkdir -p /etc/apt/keyrings
sudo cp antigravity-repo-key.gpg /etc/apt/keyrings/antigravity-repo-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | sudo tee /etc/apt/sources.list.d/antigravity.list
sudo apt update
sudo apt install -y antigravity wslu libfuse2t64 libnss3 libasound2t64 libatk-bridge2.0-0t64 libgtk-3-0t64 libgbm1

# 2. Configure .bashrc
echo "[2/7] Configuring ~/.bashrc..."
if grep -q "BROWSER=wslview" ~/.bashrc; then
    echo "  - .bashrc already configured."
else
    cat bashrc_snippet.sh >> ~/.bashrc
    echo "  - Configuration appended."
fi

# 3. Install Shim
echo "[3/7] Installing Antigravity Shim..."
sudo cp antigravity_shim.sh /usr/local/bin/antigravity
sudo chmod +x /usr/local/bin/antigravity

# 4. Setup Desktop Entry
echo "[4/7] Installing Desktop Entry..."
mkdir -p ~/.local/share/applications
cp antigravity.desktop ~/.local/share/applications/
update-desktop-database ~/.local/share/applications/ 2>/dev/null || true

# 5. Bootstrap Agent Context
echo "[5/7] Bootstrapping Agent Context (GEMINI.md)..."
mkdir -p ~/.gemini
cp GEMINI.md ~/.gemini/
echo "  - Agent memory restored to ~/.gemini/GEMINI.md"

# 6. Apply Hardened Configuration
echo "[6/7] Applying Hardened WSL Configuration..."
CURRENT_USER=$(whoami)
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

# Copy base config
sudo cp wsl.conf /etc/wsl.conf

# Inject user-specific settings
echo -e "\n[user]\ndefault=${CURRENT_USER}" | sudo tee -a /etc/wsl.conf > /dev/null
sudo sed -i "s/options = \"metadata,ro\"/options = \"metadata,uid=${CURRENT_UID},gid=${CURRENT_GID},ro\"/" /etc/wsl.conf

echo "  - /etc/wsl.conf updated for user '${CURRENT_USER}'. Windows drives will be Read-Only after restart."

# 7. Clean Start Menu
echo "[7/7] Cleaning Start Menu (Hiding 'wslview', 'zutty', and patching 'antigravity')..."
for app in wslview zutty; do
    SYS_FILE="/usr/share/applications/${app}.desktop"
    if [ -f "$SYS_FILE" ]; then
        echo "  - Hiding ${app} system-wide..."
        sudo sed -i '/NoDisplay=/d' "$SYS_FILE"
        sudo sed -i '/X-WSL-No-Export=/d' "$SYS_FILE"
        echo "NoDisplay=true" | sudo tee -a "$SYS_FILE" > /dev/null
        echo "X-WSL-No-Export=true" | sudo tee -a "$SYS_FILE" > /dev/null
    fi
done

# Patch the system-wide Antigravity entry to use our shim
ANTIGRAVITY_SYS_FILE="/usr/share/applications/antigravity.desktop"
if [ -f "$ANTIGRAVITY_SYS_FILE" ]; then
    echo "  - Patching system antigravity.desktop to use shim..."
    sudo sed -i 's|Exec=/usr/share/antigravity/antigravity|Exec=/usr/local/bin/antigravity|g' "$ANTIGRAVITY_SYS_FILE"
    # Ensure it's exported and visible
    sudo sed -i '/NoDisplay=/d' "$ANTIGRAVITY_SYS_FILE"
    sudo sed -i '/X-WSL-No-Export=/d' "$ANTIGRAVITY_SYS_FILE"
    echo "X-WSL-No-Export=false" | sudo tee -a "$ANTIGRAVITY_SYS_FILE" > /dev/null
fi

# Remove local override to ensure the system one is the single source of truth
rm -f ~/.local/share/applications/antigravity.desktop
rm -f ~/.local/share/applications/wslview.desktop ~/.local/share/applications/zutty.desktop
update-desktop-database ~/.local/share/applications/ 2>/dev/null || true

echo "Done! Please run 'wsl.exe --shutdown' from PowerShell to apply the hardening changes."