# WSL Agent & Antigravity Environment

**Root Directory:** `[Current Project Folder]`

This repository serves as the central documentation and configuration hub for the hybrid Windows/WSL Development Agent. It defines how to set up, maintain, and work within the WSL 2 environment using the Antigravity IDE (Cursor/VSCode fork).

## 1. Quick Start (Restore Environment)

If you need to set up a fresh WSL instance or fix a broken one, use the **Antigravity Setup Kit**.

**Location:** [`./antigravity_setup_kit/`](./antigravity_setup_kit/)

The kit handles:
*   **Windows Host:** High-DPI scaling fixes (`.wslgconfig`).
*   **WSL Guest:** 
    *   **Security Hardening:** Enforces **Read-Only** access to Windows drives to prevent data loss.
    *   **Scaling Fixes:** Installs a shim to force crisp Wayland rendering.
    *   **Integration:** Installs `wslu` (browser), configures `.bashrc`, and restores Agent memory (`GEMINI.md`).

See [`antigravity_setup_kit/README.md`](./antigravity_setup_kit/README.md) for execution instructions.

## 2. Usage Guide

### How to Open Projects
Always launch the IDE **from within WSL**. This ensures the "Remote - WSL" context is active, giving the IDE direct access to Linux tools (Git, Bun, Python) and the high-performance file system.

**Terminal Method (Recommended):**
```bash
# Inside WSL
cd ~/lang/js/my-project
antigravity .
```

**PowerShell One-Liner:**
```powershell
# Replace <username> with your WSL user
wsl -u <username> --cd /home/<username>/lang/js/my-project antigravity .
```

### Browser & Authentication
If setup correctly (via the Kit), clicking "Sign in with Google" or opening links in the IDE will automatically launch your **default Windows browser**. This is handled by `wslu` and `wslview`.

## 3. Directory Structure & Conventions

### Hybrid Layout
*   **Windows (Host):** `[Project Root]`
    *   Stores this documentation, the Setup Kit, and high-level agent context.
    *   Acts as the "Safe Harbor" for recovery.
*   **WSL (Guest):** `~/lang/`
    *   Stores all actual source code and projects.
    *   **Do not** store active projects on the Windows partition (`/mnt/c/...`) due to poor performance.

### Project Organization (WSL)
Projects are organized by language in the home directory:
```text
~/lang/
├── js/        # JavaScript/TypeScript (Use Bun!)
├── python/    # Python (Use uv!)
├── rust/      # Rust (Use Cargo)
└── ...
```

### Development Rules
1.  **TypeScript:** Use TypeScript for all JS-ecosystem projects.
2.  **Bun:** Use `bun` instead of `npm`/`node` wherever possible.
3.  **Python:** Use `uv` for dependency management.
4.  **User:** Always work as the primary non-root user (not root).

## 4. Agent Protocol: Infrastructure as Code

**CRITICAL INSTRUCTION FOR AI AGENTS:**

This directory (`[Project Root]`) is the **Single Source of Truth** for the entire development environment.

1.  **No Ad-Hoc Fixes:** You are **strictly forbidden** from applying "one-off" fixes to the live system (e.g., editing `/etc/wsl.conf` directly or manually hacking a script in `~/.local/bin`).
2.  **Commit First, Apply Second:**
    *   If a configuration change is needed (e.g., adding a flag to Antigravity, changing a mount option), you **MUST** first edit the corresponding file in `antigravity_setup_kit/`.
    *   Only *after* the file is updated in the kit, you may execute the `install.sh` or copy command to apply it to the live system.
3.  **Documentation is Mandatory:** Every change to the kit must be accompanied by an update to the relevant `README.md` to explain *why* the change was made.
4.  **Preserve Reproducibility:** The goal is that if the WSL distro is deleted today, running `install.sh` from this kit tomorrow will restore the *exact* same hardened, optimized environment.