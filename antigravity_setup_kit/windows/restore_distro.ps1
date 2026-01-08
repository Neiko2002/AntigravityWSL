# Interactive WSL Restore Script

$backupPath = Read-Host "Enter the full path to the backup (.tar) file"
if (!(Test-Path $backupPath)) {
    Write-Host "Error: File not found at $backupPath" -ForegroundColor Red
    Pause
    exit
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
Write-Host "This may take several minutes..."

wsl --import $distroName $installDir $backupPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "Restore completed successfully!" -ForegroundColor Green
    Write-Host "You can now start it with: wsl -d $distroName"
} else {
    Write-Host "Restore failed!" -ForegroundColor Red
}

Pause
