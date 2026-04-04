# Antigravity Setup Kit

This kit is the **Master Source of Truth** for the Antigravity IDE environment. It is designed to provision a reproducible, hardened, and high-performance development environment on WSL, and to seamlessly keep it updated over time.

## 1. Automated Setup (Recommended)
**Location:** `windows/wsl_dev_setup.ps1`

The easiest way to get started is to use the automated installer:

1. Open PowerShell in the `windows` directory.
2. Run the master script:
   ```powershell
   .\wsl_dev_setup.ps1
   ```
3. Select **Option 1**. This will:
   * Configure your Windows host for proper graphical scaling.
   * Create or update the `Antigravity` WSL distribution.
   * **Automatically reach inside Linux** and run the internal `install.sh` for you.

---

## 2. Manual Linux Setup (Alternative)
**Location:** `wsl/`

If you prefer to run the internal Linux setup manually, or if you need to troubleshoot:

1. Start your WSL terminal (`wsl -d Antigravity`).
2. Navigate to the `wsl` folder:
   ```bash
   cd /mnt/c/Lang/wsl_agent/antigravity_setup_kit/wsl
   ```
3. Run the installer:
   ```bash
   bash install.sh
   ```

### What does `install.sh` do?
*   **Updates Repositories:** Pulls the newest apt lists.
*   **Installs & Upgrades:** Sets up necessary libraries (Ubuntu 24.04 `t64` libraries) and explicitly forces an upgrade of the `antigravity` package to the latest version.
*   **Installs Gemini CLI:** Sets up Bun and the `@google/gemini-cli` environment.
*   **Configures IDE Shim:** Installs the `antigravity_shim.sh` wrapper (adds Wayland scaling flags) and the `.desktop` UI icons for Antigravity and Gemini.
*   **Applies Hardened `wsl.conf`:** Enforces Read-Only mounting for `/mnt/c` to protect Windows from runaway commands.
*   **Cleans Menus:** Removes redundant app icons (like `wslview`) from the Windows Start menu.

**Finalize (Initial Setup Only):**
If this is your first time setting up and the script modified `wsl.conf`, you must restart WSL from PowerShell:
```powershell
wsl --shutdown
```