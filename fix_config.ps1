# Read the current user configuration for FanControl
$path = "C:\Program Files (x86)\FanControl\Configurations\userConfig.json"

if (Test-Path $path) {
    # Backup the original configuration
    Copy-Item $path "$path.bak" -Force
    Write-Host "Backup created at $path.bak"

    # Parse and modify settings
    $config = Get-Content $path -Raw | ConvertFrom-Json
    $config.Sensors.NvAPIWrapperSettings.Enabled = $false
    $config.Sensors.LibreHardwareMonitorSettings.GPU = $false

    # Save back to file
    $config | ConvertTo-Json -Depth 10 | Set-Content $path
    Write-Host "Config modified successfully: Disabled Nvidia NVApi and GPU monitoring to prevent crash."
} else {
    Write-Error "Configuration file not found at $path"
}
