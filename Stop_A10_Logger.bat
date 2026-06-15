@echo off
echo Stopping A10 Temperature Logger...
powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter \"CommandLine like '%%A10_Temp_Logger.ps1%%'\" | ForEach-Object { Stop-Process -Id $_.ProcessId -Force; Write-Host 'Stopped process:' $_.ProcessId }"
echo Done.
pause
