<#
  technocore.ps1
  Combined installer + interactive menu for "technocore-did-starter" on Windows 11
  (PowerShell 5.1 / 7).

  - If not installed yet, this script will automatically: check Python/Git,
    clone the repo, create a virtual environment, install dependencies,
    and verify the installation.
  - Once installed (on any later run), it goes straight to the interactive
    menu for everyday use (view DID, join lobby, publish contribution,
    read rooms, etc).

  Usage: right-click this file -> "Run with PowerShell"
  or: powershell -ExecutionPolicy Bypass -File .\technocore.ps1
#>

$ErrorActionPreference = "Stop"
$RepoUrl = "https://github.com/zunmax/technocore-did-starter.git"
$RepoDir = "technocore-did-starter"

function Write-Step($msg) {
    Write-Host ""
    Write-Host ">> $msg" -ForegroundColor Cyan
}

function Test-Command($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Install-Technocore {
    Write-Step "Checking for Python 3.12..."
    $pyOk = $false
    try {
        $pyVersion = & py -3.12 --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Found: $pyVersion"
            $pyOk = $true
        }
    } catch {}

    if (-not $pyOk) {
        Write-Host "Python 3.12 was not found (other versions like 3.11/3.14 may be installed instead)." -ForegroundColor Yellow
        if (Test-Command "winget") {
            Write-Host "Attempting to install Python 3.12 automatically via winget..."
            try {
                winget install -e --id Python.Python.3.12 --accept-source-agreements --accept-package-agreements
            } catch {
                Write-Host "winget failed to install Python 3.12: $_" -ForegroundColor Red
            }
            # Refresh PATH in this PowerShell session so the new 'py' launcher is detected
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            try {
                $pyVersion = & py -3.12 --version 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Success: $pyVersion"
                    $pyOk = $true
                }
            } catch {}
        }
        if (-not $pyOk) {
            Write-Host "Python 3.12 could not be installed automatically." -ForegroundColor Yellow
            Write-Host "Please install it manually from: https://www.python.org/downloads/windows/"
            Write-Host "During setup, check 'Add python.exe to PATH' and keep the Python Launcher enabled."
            Write-Host "After installation finishes, CLOSE this window and re-run this script (so PATH is refreshed)."
            Read-Host "Press Enter to open the download page in your browser"
            Start-Process "https://www.python.org/downloads/windows/"
            exit 1
        }
    }

    Write-Step "Checking for Git..."
    if (-not (Test-Command "git")) {
        Write-Host "Git was not found." -ForegroundColor Yellow
        if (Test-Command "winget") {
            Write-Host "Attempting to install Git automatically via winget..."
            try {
                winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            } catch {
                Write-Host "winget failed to install Git: $_" -ForegroundColor Red
            }
        }
        if (-not (Test-Command "git")) {
            Write-Host "Git could not be installed automatically." -ForegroundColor Yellow
            Write-Host "Please install it manually from: https://git-scm.com/downloads/win"
            Write-Host "After installation finishes, CLOSE this window and re-run this script."
            Read-Host "Press Enter to open the download page in your browser"
            Start-Process "https://git-scm.com/downloads/win"
            exit 1
        }
    }
    Write-Host "Git found: $(git --version)"

    Write-Step "Setting up the repository folder..."
    if (Test-Path $RepoDir) {
        Write-Host "Folder '$RepoDir' already exists, using it (not re-cloning)."
    } else {
        git clone $RepoUrl $RepoDir
    }
    Set-Location $RepoDir

    Write-Step "Creating virtual environment (.venv)..."
    if (-not (Test-Path ".venv")) {
        py -3.12 -m venv .venv
    } else {
        Write-Host ".venv already exists, skipping."
    }

    Write-Step "Activating virtual environment..."
    Activate-Venv

    Write-Step "Upgrading pip and installing dependencies..."
    python -m pip install --upgrade pip
    python -m pip install -r requirements.txt

    Write-Step "Verifying installation..."
    python --version
    python -c "import cryptography; print('cryptography', cryptography.__version__)"
    python technocore_agent.py --version

    Write-Host ""
    Write-Host "=== Installation complete ===" -ForegroundColor Green
    Write-Host "Project folder: $(Get-Location)"

    $runInit = Read-Host "`nDo you want to create your DID identity now? (y/n)"
    if ($runInit -eq "y" -or $runInit -eq "Y") {
        Write-Host ""
        Write-Host "IMPORTANT: an identity is created only ONCE. Never share your passphrase or identity.pem file with anyone." -ForegroundColor Yellow
        python technocore_agent.py init
    }
}

function Activate-Venv {
    try {
        . .\.venv\Scripts\Activate.ps1
    } catch {
        Write-Host "Activate.ps1 was blocked, attempting to allow it for this process..." -ForegroundColor Yellow
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
        . .\.venv\Scripts\Activate.ps1
    }
}

function Show-Menu {
    Write-Host ""
    Write-Host "=== Technocore DID Starter - Menu ===" -ForegroundColor Cyan
    Write-Host "1) View my DID (does not create a new identity)"
    Write-Host "2) Create a NEW DID identity (only if you have never run init)"
    Write-Host "3) Send an introduction message to the 'lobby' room"
    Write-Host "4) Announce a contribution to the 'technocore' room"
    Write-Host "5) Read the latest messages in a room"
    Write-Host "6) Watch a room continuously (follow mode)"
    Write-Host "7) Create & verify a proof for a Git commit (optional)"
    Write-Host "0) Exit"
}

function Run-Menu {
    do {
        Show-Menu
        $choice = Read-Host "`nChoose an option"

        switch ($choice) {
            "1" { python technocore_agent.py did }
            "2" {
                Write-Host "WARNING: only run this once. Do not create a new identity if you already have one." -ForegroundColor Yellow
                $confirm = Read-Host "Type 'yes' to proceed with creating a new identity"
                if ($confirm -eq "yes") { python technocore_agent.py init } else { Write-Host "Cancelled." }
            }
            "3" {
                $msg = Read-Host "Type your introduction message (English is recommended)"
                python technocore_agent.py say lobby "$msg"
            }
            "4" {
                $url = Read-Host "Public URL of your contribution"
                $topic = Read-Host "Short description of what this contribution helps people understand"
                $text = "I published a Technocore contribution: $url. It helps people understand $topic."
                python technocore_agent.py say technocore "$text"
            }
            "5" {
                $room = Read-Host "Room name (e.g. lobby)"
                $limit = Read-Host "Number of recent messages to read (e.g. 20)"
                python technocore_agent.py read $room --limit $limit
            }
            "6" {
                $room = Read-Host "Room name (e.g. lobby)"
                Write-Host "Press Ctrl+C to stop watching."
                python technocore_agent.py read $room --follow
            }
            "7" {
                $repoUrl = Read-Host "Public Git repository URL"
                $hash = Read-Host "Full commit hash"
                python technocore_agent.py proof $repoUrl $hash --output contribution-proof.json
                python technocore_agent.py verify-proof contribution-proof.json
            }
            "0" { Write-Host "Goodbye." }
            default { Write-Host "Unrecognized option." -ForegroundColor Yellow }
        }
    } while ($choice -ne "0")
}

# ---- Main logic ----
# Detect whether the tool is already installed: repo folder + .venv + dependency present.
$alreadyInstalled = $false
if (Test-Path $RepoDir) {
    Set-Location $RepoDir
    if ((Test-Path ".venv") -and (Test-Path "technocore_agent.py")) {
        Activate-Venv
        $checkImport = & python -c "import cryptography" 2>$null
        if ($LASTEXITCODE -eq 0) {
            $alreadyInstalled = $true
        }
    }
    if (-not $alreadyInstalled) { Set-Location .. }
}

if (-not $alreadyInstalled) {
    Install-Technocore
} else {
    Write-Host "Existing installation detected in '$RepoDir'. Going straight to the menu." -ForegroundColor Green
}

Run-Menu

Read-Host "`nPress Enter to close"
