# =========================================================
#  Enable Autostart for A10 Temperature Logger
# =========================================================

$ShortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\A10_Temp_Logger.lnk"
$TargetFile = "d:\GPU_Fan_control\Run_A10_Logger_Hidden.vbs"

if (Test-Path $TargetFile) {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $TargetFile
    $Shortcut.WorkingDirectory = "d:\GPU_Fan_control"
    $Shortcut.Save()
    
    Write-Host "Success! Shortcut created in Startup folder:" -ForegroundColor Green
    Write-Host $ShortcutPath -ForegroundColor Cyan
    Write-Host "The A10 logger script will now run automatically when Windows starts." -ForegroundColor Green
} else {
    Write-Error "Target file not found: $TargetFile"
}
