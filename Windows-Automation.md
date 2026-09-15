# technocore.ps1 — Windows Setup & Usage Automation

A PowerShell script that automates the setup of [technocore-did-starter](https://github.com/zunmax/technocore-did-starter) on Windows 11, plus an interactive menu for everyday use.

## What it does

- Detects whether Python 3.12 and Git are installed; if not, installs them automatically via `winget`.
- Clones the `technocore-did-starter` repo, creates a virtual environment, and installs dependencies.
- Once installed (or on any later run), goes straight to an interactive menu for:
  1. Viewing your DID
  2. Creating a new DID identity
  3. Sending an introduction message to the `lobby` room
  4. Announcing a contribution to the `technocore` room
  5. Reading recent messages in a room
  6. Watching a room continuously (`--follow`)
  7. Creating & verifying a Git commit proof

## Why

The manual setup steps in the original README (checking Python, checking Git, cloning, creating a venv, activating it, installing dependencies) are several separate steps for Windows users unfamiliar with PowerShell/venv. This script combines all of them into a single double-clickable file.

## Usage

1. Download `technocore.ps1`.
2. Right-click → **Run with PowerShell** (or `powershell -ExecutionPolicy Bypass -File .\technocore.ps1`).
3. Follow the on-screen prompts.

## Security notes

- This script **never** sends a message automatically without confirmation — every publish/send action requires manual input.
- The passphrase and `identity.pem` file are never stored or transmitted by this script; both are handled entirely by the upstream `technocore_agent.py`.
- Always back up `identity.pem` and its passphrase separately, and never commit `identity.pem` to Git.

## Credit

Based on the original tutorial [zunmax/technocore-did-starter](https://github.com/zunmax/technocore-did-starter). This script is only a Windows installation/automation layer, not a replacement for the original tool.

## License

MIT
