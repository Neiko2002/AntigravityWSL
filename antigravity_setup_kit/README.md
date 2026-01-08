# Antigravity Setup Kit

This kit is the **Master Source of Truth** for the Antigravity IDE environment. It is designed to provision a reproducible, hardened, and high-performance development environment on a fresh WSL instance.

## 0. Provisioning a New Distro (Optional)

If you are starting with a completely fresh environment or want a dedicated "Antigravity" distro:

1.  **Install the Base Image:**
    ```powershell
    wsl --install Ubuntu-24.04 --name Antigravity --no-launch --web-download
    ```
2.  **Bootstrap the User:**
    Run these as root to ensure the agent's environment matches expectations (Replace `<username>` with the user's preferred name - **Ask the user for this before proceeding**):
    ```powershell
    wsl -d Antigravity -u root -- bash -c "useradd -m -s /bin/bash <username> && usermod -aG sudo <username> && echo '<username> ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/<username>"
    ```

## 1. Windows Host Setup
**Location:** `windows/`

This step configures the Windows host to support the specific needs of the WSL environment, particularly for graphics scaling.

**Files:**
*   `.wslgconfig`: Configuration file for WSLg (WSL GUI) to ensure proper DPI scaling.
*   `setup_host.ps1`: PowerShell automation script.

**Instructions:**
1.  Open PowerShell in the `windows` directory.
2.  Run `.\setup_host.ps1`.
3.  **Action:** Copies `.wslgconfig` to `%USERPROFILE%`.
4.  **Restart Required:** Run `wsl --shutdown` to apply changes.

## 2. WSL Guest Setup
**Location:** `wsl/`

This step provisions the Linux environment with necessary tools, configurations, and security policies.

**Files:**
*   `install.sh`: The master provisioning script. **Now automatically configures the APT repository.**
*   `antigravity-repo-key.gpg`: **APT Keyring for the IDE.**
*   `wsl.conf`: **Hardened System Configuration.**
    *   Enforces **Read-Only** mounting of Windows drives (`/mnt/c`) to prevent accidental data corruption or "rm -rf" disasters on the host OS.
    *   Enables `systemd` and metadata support.
*   `antigravity_shim.sh`: **Scaling Fix Wrapper.**
    *   Installed to `/usr/local/bin/antigravity`.
    *   Forces the IDE to use the `Wayland` backend (`--ozone-platform=wayland`) to resolve blurriness on High-DPI screens.
*   `antigravity.desktop`: Start Menu shortcut pointing to the shim.
*   `GEMINI.md`: The Agent's long-term memory bootstrap file.
*   `bashrc_snippet.sh`: Shell configuration for browser integration (`wslu`).

**Instructions:**
1.  Start your WSL terminal (e.g., Ubuntu).
2.  Navigate to the `wsl` folder within the setup kit on your Windows mount (e.g., `/mnt/c/path/to/antigravity_setup_kit/wsl`):
    ```bash
    cd /mnt/c/.../antigravity_setup_kit/wsl
    ```
3.  Run the installer:
    ```bash
    chmod +x install.sh
    ./install.sh
    ```
4.  **Actions Performed:**
    *   Installs system dependencies (Ubuntu 24.04 compatible).
    *   Configures `~/.bashrc` for browser integration.
    *   Installs the **Antigravity Shim** and **Desktop Entry**.
    *   Restores Agent Memory (`~/.gemini/GEMINI.md`).
    *   Applies **Hardened `wsl.conf`** to `/etc/wsl.conf`.
    *   **Cleans Start Menu:** Hides `wslview` and `zutty` icons from Windows.

5.  **Finalize:**
    You must restart WSL to apply the security hardening and filesystem changes:
    ```powershell
    wsl --shutdown
    ```