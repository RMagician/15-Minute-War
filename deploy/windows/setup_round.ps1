# Creates the admin account (random password, printed once), reserves the "test" username
# (it unlocks /run_tick_view) and sets the round start time. The 15MW Tick task starts the
# round on the first tick after -Start.
# Example: .\setup_round.ps1 -Admin admin -Start "2026-11-10 12:00"   (US Eastern)
param(
    [string]$Admin = "admin",
    [string]$Start = (Get-Date).Date.AddDays(1).AddHours(12).ToString("yyyy-MM-dd HH:mm")
)
$app = Split-Path (Split-Path $PSScriptRoot)
Set-Location $app
$py = "$app\venv\Scripts\python.exe"
$code = @"
import secrets
from datetime import datetime
from zoneinfo import ZoneInfo
from django.contrib.auth.models import User
from maingame.models import Round

for name, su in (("$Admin", True), ("test", False)):
    if User.objects.filter(username=name).exists():
        print(f"{name}: already exists, left unchanged")
        continue
    pw = secrets.token_urlsafe(12)
    (User.objects.create_superuser if su else User.objects.create_user)(name, password=pw)
    print(f"{name}: created, password {pw}")

r = Round.objects.first()
r.start_time = datetime.strptime("$Start", "%Y-%m-%d %H:%M").replace(tzinfo=ZoneInfo("America/New_York"))
r.save()
print("Round starts", r.start_time, "US Eastern,", r.ticks_to_end, "ticks until endgame")
"@
# Piped via stdin: PowerShell 5.1 mangles double quotes in native-exe arguments.
$code | & $py manage.py shell
