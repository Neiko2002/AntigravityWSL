<#
.SYNOPSIS
Antigravity WSL Dev Environment Manager - A unified interface for managing your developer environment.

.DESCRIPTION
This script acts as the main gateway for Windows users to:
1. Create a fresh WSL distribution or Update an existing one.
2. Backup the entire WSL container to a .tar archive so work is not lost.
3. Restore a previous backup.
#>

function Show-Menu {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "   Antigravity WSL Dev Environment Setup  " -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "1) Create or Update WSL Distro (Includes Host Fixes)"
    Write-Host "2) Backup an existing WSL Distro"
    Write-Host "3) Restore a WSL Distro from Backup"
    Write-Host "q) Quit"
    Write-Host "==========================================" -ForegroundColor Cyan
}

function Setup-Distro {
    # ---------------------------------------------------------
    # PART 1: WINDOWS HOST CONFIGURATION (.wslgconfig)
    # ---------------------------------------------------------
    # WHY WE DO THIS: 
    # WSLg (the graphics subsystem for WSL) often scales Linux GUI apps incorrectly 
    # on high-DPI Windows laptops, making text look permanently blurry. 
    # Copying `.wslgconfig` to your Windows user profile folder forces WSLg 
    # to render the IDE purely at 1x scale. The IDE itself then handles the scaling 
    # internally (via Wayland overrides) to stay razor sharp.
    # ---------------------------------------------------------
    Write-Host "1. Setting up Antigravity Windows Host Requirements..." -ForegroundColor Cyan
    
    $SourceConfig = ".\.wslgconfig"
    $DestConfig = "$env:USERPROFILE\.wslgconfig"
    
    if (Test-Path $SourceConfig) {
        Write-Host "Copying .wslgconfig to $DestConfig..."
        Copy-Item -Force $SourceConfig $DestConfig
        Write-Host "Windows host config updated." -ForegroundColor Green
    } else {
        Write-Host "Warning: .wslgconfig not found in current directory. Skipping host config." -ForegroundColor Yellow
    }

    # ---------------------------------------------------------
    # PART 2: DISTRO CREATION & UPDATE 
    # ---------------------------------------------------------
    Write-Host "`n2. Checking for existing Antigravity Distro..." -ForegroundColor Cyan

    # WHY WE CHANGE THE ENCODING HERE:
    # `wsl.exe -l -q` outputs text in UTF-16LE. By default, PowerShell text search 
    # (Select-String) struggles with this encoding. Temporarily changing 
    # the Console OutputEncoding to Unicode ensures we correctly detect 
    # if the 'Antigravity' distro is already built.
    $oldEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
    $distroExists = wsl -l -q | Select-String "Antigravity"
    [Console]::OutputEncoding = $oldEncoding

    if ($distroExists) {
        Write-Host "✅ Distro 'Antigravity' is already installed." -ForegroundColor Green
    } else {
        # The user does not have the environment. Download and install a fresh Ubuntu 24.04 instance.
        Write-Host "➔ Distro 'Antigravity' not found. Installing fresh Ubuntu 24.04..." -ForegroundColor Yellow
        wsl --install Ubuntu-24.04 --name Antigravity --no-launch --web-download
        
        if ($LASTEXITCODE -eq 0) {
            # Since we used --no-launch, the system doesn't prompt for a default user natively. 
            # We must ask for a username and configure sudo rights manually here.
            Write-Host "`nSetup requires a default user for the new container."
            $username = Read-Host "Please enter your preferred Linux username (e.g., nico)"
            
            Write-Host "`nConfiguring user '$username'..."
            wsl -d Antigravity -u root -- bash -c "useradd -m -s /bin/bash $username && usermod -aG sudo $username && echo '$username ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$username"
            
            Write-Host "`n✅ Fresh distro created." -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to create the Antigravity WSL instance." -ForegroundColor Red
            Pause
            return
        }
    }

    # ---------------------------------------------------------
    # PART 3: AUTOMATED LINUX SETUP
    # ---------------------------------------------------------
    # WHY WE DO THIS:
    # Instead of making you manually open the terminal and type commands, we 
    # can tell Windows to "reach inside" the Linux container and run the 
    # install/update script for us. This makes the whole setup a "One-Click" experience.
    # ---------------------------------------------------------
    Write-Host "`n3. Starting internal Linux setup/update..." -ForegroundColor Cyan
    
    # We find where this script is, move to the 'wsl' folder, and format the path for Linux.
    $ScriptDir = Get-Location
    $InstallShWindowsPath = Join-Path $ScriptDir "..\wsl\install.sh"
    
    if (Test-Path $InstallShWindowsPath) {
        # Convert C:\Path\... to /mnt/c/Path/... so Linux understands it.
        $WslPath = $InstallShWindowsPath.Replace('\', '/').Replace('C:', '/mnt/c').Replace('c:', '/mnt/c')
        
        Write-Host "Executing: bash $WslPath inside 'Antigravity'..." -ForegroundColor Gray
        
        # Run the script inside WSL. We use 'bash' explicitly because the C: mount might be Read-Only.
        wsl -d Antigravity bash $WslPath
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✅ Linux setup/update completed successfully!" -ForegroundColor Green
            
        } else {
            Write-Host "`n❌ Linux setup script returned an error." -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Error: Could not find install.sh at $InstallShWindowsPath" -ForegroundColor Red
    }
    
    # WSL needs to restart for changes to the .wslgconfig to take effect.
    Write-Host "`nNote: If this is your first time, any Windows changes (like the DPI scaling fix) take effect after the next WSL restart ('wsl --shutdown')."
    Pause
}

function Backup-Distro {
    # ---------------------------------------------------------
    # EXPORT / BACKUP LOGIC
    # ---------------------------------------------------------
    # WHY WE DO THIS:
    # A WSL instance is effectively a virtual hard disk (VHDX). If it gets corrupted, 
    # you lose everything not mounted in /mnt/c. Exporting creates a flat .tar file 
    # of the entire filesystem state which can be restored instantly on any PC.
    # ---------------------------------------------------------
    Write-Host "Available distributions:"
    wsl --list --quiet

    $defaultDistro = "Antigravity"
    $distroName = Read-Host "Enter the name of the distribution to backup (default: $defaultDistro)"
    if ([string]::IsNullOrWhiteSpace($distroName)) { $distroName = $defaultDistro }

    $defaultBackupDir = "C:\WSL_Backups"
    $backupDir = Read-Host "Enter the directory to save the backup (default: $defaultBackupDir)"
    if ([string]::IsNullOrWhiteSpace($backupDir)) { $backupDir = $defaultBackupDir }

    if (!(Test-Path $backupDir)) {
        Write-Host "Creating directory $backupDir..."
        New-Item -ItemType Directory -Path $backupDir | Out-Null
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = Join-Path $backupDir "$($distroName)_$timestamp.tar"

    # Always ensure WSL is completely stopped before backing up to avoid corrupted/incomplete data 
    Write-Host "Shutting down WSL to ensure consistency..."
    wsl --shutdown

    Write-Host "Exporting $distroName to $backupFile..."
    Write-Host "This may take several minutes depending on the size of your distribution..." -ForegroundColor Yellow

    wsl --export $distroName $backupFile

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Backup completed successfully!" -ForegroundColor Green
        Write-Host "File location: $backupFile"
    } else {
        Write-Host "Backup failed!" -ForegroundColor Red
    }
    Pause
}

function Restore-Distro {
    # ---------------------------------------------------------
    # IMPORT / RESTORE LOGIC
    # ---------------------------------------------------------
    # Takes a previously exported .tar file and reconstructs a working WSL container.
    # ---------------------------------------------------------
    $backupPath = Read-Host "Enter the full path to the backup (.tar) file"
    if (!(Test-Path $backupPath)) {
        Write-Host "Error: File not found at $backupPath" -ForegroundColor Red
        Pause
        return
    }

    $defaultDistro = "Antigravity"
    $distroName = Read-Host "Enter the name for the restored distribution (default: $defaultDistro)"
    if ([string]::IsNullOrWhiteSpace($distroName)) { $distroName = $defaultDistro }

    $defaultInstallDir = "C:\WSL\$distroName"
    $installDir = Read-Host "Enter the installation directory (where the VHDX will live) (default: $defaultInstallDir)"
    if ([string]::IsNullOrWhiteSpace($installDir)) { $installDir = $defaultInstallDir }

    if (!(Test-Path $installDir)) {
        Write-Host "Creating directory $installDir..."
        New-Item -ItemType Directory -Path $installDir | Out-Null
    }

    Write-Host "Importing $distroName from $backupPath into $installDir..."
    Write-Host "This may take several minutes..." -ForegroundColor Yellow

    wsl --import $distroName $installDir $backupPath

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Restore completed successfully!" -ForegroundColor Green
        Write-Host "You can now start it with: wsl -d $distroName"
    } else {
        Write-Host "Restore failed!" -ForegroundColor Red
    }
    Pause
}

do {
    Show-Menu
    $selection = Read-Host "Enter an option (1-3, q)"
    switch ($selection) {
        '1' { Setup-Distro }
        '2' { Backup-Distro }
        '3' { Restore-Distro }
        'q' { exit }
        default {
            Write-Host "Invalid selection. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($true)
