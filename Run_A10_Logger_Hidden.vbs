Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File d:\GPU_Fan_control\A10_Temp_Logger.ps1", 0, false
