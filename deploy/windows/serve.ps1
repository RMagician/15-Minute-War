# Watchdog: starts waitress on 127.0.0.1:$Port if nothing is listening there.
# Scheduled at boot and every 5 minutes by install_tasks.ps1. IIS proxies the domain to this port.
param([int]$Port = 8015)
$app = Split-Path (Split-Path $PSScriptRoot)
if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) { exit 0 }
New-Item -ItemType Directory -Force "$app\logs" | Out-Null
Start-Process -FilePath "$app\venv\Scripts\python.exe" -WorkingDirectory $app -WindowStyle Hidden `
    -ArgumentList "-m", "waitress", "--listen=127.0.0.1:$Port", "odalike.wsgi:application" `
    -RedirectStandardOutput "$app\logs\waitress.out.log" -RedirectStandardError "$app\logs\waitress.err.log"
