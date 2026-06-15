# Nvidia A10 GPU 風扇控制 — Linux 版

兩套 Bash 腳本，依據 **Nvidia A10 GPU** 溫度控制主機板 PWM 接頭上的機箱風扇（例如 AIO_PUMP），透過 **Nuvoton NCT6799D** Super I/O 晶片的 sysfs 介面直接控速。

## 需求

- **Nvidia A10 GPU**，已安裝 NVIDIA 專有驅動（提供 `nvidia-smi`）
- **ASUS TUF GAMING B650M-PLUS WIFI**（或任何配備 NCT6799D/NCT6775 相容晶片的主機板）
- **Linux 核心 ≥6.3**（內建 `nct6775` WMI 支援）
- 風扇接在主機板 PWM 接頭上（例如 AIO_PUMP）

## 快速開始

### 1. 安裝

```bash
sudo ./install.sh
```

安裝腳本會：
- 載入 `nct6775` 核心模組
- 自動偵測 Nuvoton hwmon 裝置
- 驗證 AIO_PUMP 的 PWM 控制
- 安裝腳本到 `/opt/a10-fan-control/`
- 建立設定檔 `/etc/a10-fan-control.conf`
- 安裝 systemd 服務單元

### 2. 啟動

```bash
# 風扇控制常駐程式（開機自動啟動）
sudo systemctl enable --now a10-fanctrl

# 溫度紀錄器（選擇性）
sudo systemctl enable --now a10-temp-logger
```

### 3. 監控

```bash
sudo journalctl -u a10-fanctrl -f
```

## 運作原理

| GPU 溫度 | 風扇轉速 | PWM | 效果 |
|---|---|---|---|
| < 55°C | 20% | 51 | 靜音 |
| 55–72°C | 20–100%（線性） | 51–255 | 依溫度加強散熱 |
| > 72°C | 100% + GPU 功率上限降至 120W | 255 | 最大散熱 |

腳本每 8 秒透過 `nvidia-smi` 讀取 GPU 溫度，寫入對應的 PWM 值到 `/sys/class/hwmon/hwmon*/pwm7`（AIO_PUMP）。高溫時同時調降 GPU 功率上限加速降溫。

## 手動測試

```bash
sudo /opt/a10-fan-control/A10_FanCtrl.sh
```

## 溫度紀錄器（供 FanControl 或其他監控工具使用）

```bash
# 以系統服務執行（每 2 秒寫入 /opt/a10-fan-control/gpu_temp.sensor）
sudo systemctl start a10-temp-logger

# 停止
sudo /opt/a10-fan-control/stop_logger.sh
```

## 設定

編輯 `/etc/a10-fan-control.conf`：

```bash
HWMON_PATH="/sys/class/hwmon/hwmonX"   # 自動偵測
PWM_CHANNEL=7                           # AIO_PUMP
TEMP_LOW=55                             # °C，低於此溫度風扇最低速
TEMP_HIGH=72                            # °C，高於此溫度風扇全速
PWM_MIN=51                              # 20%  duty cycle
PWM_MAX=255                             # 100% duty cycle
INTERVAL=8                              # 輪詢間隔（秒）
GPU_POWER_LIMIT=120                     # 瓦特，超過 TEMP_HIGH 時啟用
```

## 檔案一覽

| 檔案 | 用途 |
|---|---|
| `A10_FanCtrl.sh` | 主控迴圈（8 秒間隔） |
| `A10_Temp_Logger.sh` | 溫度感應器檔案寫入器（2 秒間隔） |
| `stop_logger.sh` | 終止紀錄器 |
| `install.sh` | 一鍵安裝 |
| `a10-fanctrl.service` | systemd 服務單元 |
| `a10-temp-logger.service` | systemd 服務單元 |
| `/etc/a10-fan-control.conf` | 執行時期設定 |

## 故障排除

**`nct6775` 模組無法載入：**
```bash
sudo modprobe nct6775 force_id=0xd420
```

**找不到 hwmon 裝置（核心 <6.3）：**
```bash
# 在 /etc/default/grub 的 GRUB_CMDLINE_LINUX 中加上
acpi_enforce_resources=lax
sudo update-grub && reboot
```

**無法寫入 PWM：**
腳本/服務需以 root 執行。sysfs hwmon 檔案屬於 root。
