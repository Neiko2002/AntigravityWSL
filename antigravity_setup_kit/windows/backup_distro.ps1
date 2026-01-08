# Interactive WSL Backup Script

$distros = wsl --list --quiet
Write-Host "Available distributions:"
$distros

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

Write-Host "Shutting down WSL to ensure consistency..."
wsl --shutdown

Write-Host "Exporting $distroName to $backupFile..."
Write-Host "This may take several minutes depending on the size of your distribution."

wsl --export $distroName $backupFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "Backup completed successfully!" -ForegroundColor Green
    Write-Host "File location: $backupFile"
} else {
    Write-Host "Backup failed!" -ForegroundColor Red
}

Pause
