## Gemini Agent Context (WSL Edition)

- **Environment:** WSL 2 (Linux)
- **User:** [Current WSL User]
- **Shell:** Bash

## Development Conventions
- **JavaScript/TypeScript:**
  - Runtime/Package Manager: **Bun** (Do not use Node/NPM unless strictly forced).
  - Language: **TypeScript** exclusively.
- **Python:**
  - Package Manager: **uv** (Do not use Pip/Conda).
- **Project Location:**
  - All source code resides in `~/lang/<language>/`.

## Agent Memory
- This file resides in `~/.gemini/GEMINI.md`.
- Documentation and logs are maintained in `~/agent_docs/`.

## Infrastructure Protocol
- **No Ad-Hoc Config:** NEVER modify system files (`/etc/wsl.conf`, `/usr/local/bin/antigravity`, etc.) directly.
- **Workflow:**
  1. Modify the file in `antigravity_setup_kit/wsl/` (on the Windows mount).
  2. Run `install.sh` (or specific copy commands) to apply the change to the Linux system.
  3. This ensures the environment is always reproducible from the kit.
