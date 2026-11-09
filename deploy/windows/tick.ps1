# Runs one game tick. Scheduled every 15 minutes by install_tasks.ps1.
$app = Split-Path (Split-Path $PSScriptRoot)
New-Item -ItemType Directory -Force "$app\logs" | Out-Null
Set-Location $app
& "$app\venv\Scripts\python.exe" manage.py do_tick *>> "$app\logs\tick.log"
