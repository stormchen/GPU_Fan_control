# =========================================================
#  Nvidia A10 溫度與 Windows 電源計劃聯動腳本 (免第三方風扇驅動)
# =========================================================

# 取得 Windows 內建電源計劃的 GUID
$HighPerfGUID = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"  # 高效能
$BalancedGUID = "381b4222-f694-41f0-9685-ff5bb260df2e"  # 平衡
$SaverGUID    = "a1841308-3541-4fab-bc81-f71556f20b4a"  # 省電

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Nvidia A10 安全溫控電源調度腳本已啟動" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 預設初始化為平衡模式
powercfg /setactive $BalancedGUID

while ($true) {
    # 1. 取得 A10 當前溫度
    $gpuTempStr = nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits
    
    if ($gpuTempStr -match '\d+') {
        $gpuTemp = [int]$matches[0]
        
        # 2. 依據 A10 溫度切換 Windows 電源狀態
        if ($gpuTemp -lt 55) {
            # 溫度很低，進入省電模式，強迫 Asus 主機板風扇進入極度靜音
            powercfg /setactive $SaverGUID
            $CurrentMode = "省電模式 (靜音風扇)"
            $Color = "Green"
        } elseif ($gpuTemp -ge 55 -and $gpuTemp -lt 72) {
            # 中度負載，切換回平衡
            powercfg /setactive $BalancedGUID
            $CurrentMode = "平衡模式 (標準風扇)"
            $Color = "Yellow"
        } else {
            # A10 開始發熱（大於72度），切換到高效能
            # 這會解鎖 CPU 功耗並提升全機供電，直接誘發 Asus BIOS 判定高載，將風扇暴力拉高
            powercfg /setactive $HighPerfGUID
            $CurrentMode = "高效能模式 (風扇全力運轉中!!)"
            $Color = "Red"
        }
        
        # 3. 印出狀態
        Write-Host "$(Get-Date -Format 'HH:mm:ss') | A10 溫度: ${gpuTemp}°C ──> 當前系統狀態: $CurrentMode" -ForegroundColor $Color
        
    } else {
        Write-Warning "無法取得 GPU 溫度。"
    }
    
    # 每 8 秒檢查一次，避免頻繁切換電源計劃
    Start-Sleep -Seconds 8
}