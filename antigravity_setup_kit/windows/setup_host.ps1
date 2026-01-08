Write-Host "Setting up Antigravity Windows Host Requirements..."

# 1. Copy .wslgconfig to User Profile
$SourceConfig = ".\.wslgconfig"
$DestConfig = "$env:USERPROFILE\.wslgconfig"

Write-Host "Copying .wslgconfig to $DestConfig..."
Copy-Item -Force $SourceConfig $DestConfig

Write-Host "Windows setup complete."

$backupChoice = Read-Host "Would you like to create a backup of a WSL distribution now? (y/n)"
if ($backupChoice -eq 'y') {
    .\backup_distro.ps1
}

Write-Host "Please run 'wsl --shutdown' to apply any pending changes (like the DPI scaling fix)."
