Write-Host "Setting up Antigravity Windows Host Requirements..."

# 1. Copy .wslgconfig to User Profile
$SourceConfig = ".\.wslgconfig"
$DestConfig = "$env:USERPROFILE\.wslgconfig"

Write-Host "Copying .wslgconfig to $DestConfig..."
Copy-Item -Force $SourceConfig $DestConfig

Write-Host "Windows setup complete."
Write-Host "Please run 'wsl --shutdown' to apply the DPI scaling fix."
