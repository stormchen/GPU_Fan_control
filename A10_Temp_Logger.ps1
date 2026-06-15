# =========================================================
#  Nvidia A10 Temperature Writer (For FanControl File Sensor)
# =========================================================

$OutputFile = "d:\GPU_Fan_control\gpu_temp.sensor"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Nvidia A10 Temperature Logger Started" -ForegroundColor Cyan
Write-Host " Writing to: $OutputFile" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Ensure output directory exists
$dir = Split-Path $OutputFile
if (!(Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

while ($true) {
    # 1. Get current A10 temperature
    $gpuTempStr = nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits
    
    if ($gpuTempStr -match '\d+') {
        $gpuTemp = [int]$matches[0]
        
        # 2. Write temperature value to file (overwrite, only the number)
        # Use Out-File -Encoding ascii to ensure compatibility with FanControl
        $gpuTemp | Out-File -FilePath $OutputFile -Encoding ascii -Force
        
        # 3. Print status to console
        Write-Host "$(Get-Date -Format 'HH:mm:ss') | A10 Temp: ${gpuTemp} C -> Written to file" -ForegroundColor Green
    } else {
        Write-Warning "Failed to get GPU temperature."
    }
    
    # Update every 2 seconds for responsive fan reaction
    Start-Sleep -Seconds 2
}
