# Windows server deploy (IIS + waitress + scheduled tick)

IIS owns ports 80/443 and proxies the game's domain to waitress on `127.0.0.1:8015`.
No firewall changes are needed: waitress only listens on localhost.

## First install (elevated PowerShell)

```powershell
git clone -b main https://github.com/RMagician/15-Minute-War C:\FifteenMinuteWar
cd C:\FifteenMinuteWar
& "C:\Program Files\Python312\python.exe" -m venv venv
venv\Scripts\pip install -r requirements.txt

# Machine-level env vars, read by the SYSTEM scheduled tasks
setx /M DJANGO_DEBUG 0
setx /M DJANGO_SECRET_KEY "<long random string>"
setx /M DJANGO_ALLOWED_HOSTS "15minutewar.starkingdoms.net"
setx /M DJANGO_CSRF_TRUSTED_ORIGINS "https://15minutewar.starkingdoms.net"
# Open a new shell so the variables apply, then:

venv\Scripts\python manage.py migrate
venv\Scripts\python manage.py init_round      # fresh DB only, it wipes round data
venv\Scripts\python manage.py collectstatic --noinput
deploy\windows\install_tasks.ps1
deploy\windows\setup_round.ps1 -Start "2026-11-10 12:00"   # US Eastern; prints admin + test passwords once
```

The first tick after the start time starts the round. Re-run `setup_round.ps1` to move the start; existing accounts are left unchanged.

## IIS site

DNS: an A record `15minutewar` on starkingdoms.net (Namecheap) pointing at `195.252.207.79`.

```powershell
New-Item -ItemType Directory C:\inetpub\15mw-proxy
Copy-Item C:\FifteenMinuteWar\deploy\windows\web.config C:\inetpub\15mw-proxy
New-Website -Name "15 Minute War" -PhysicalPath C:\inetpub\15mw-proxy -HostHeader 15minutewar.starkingdoms.net -Port 80
C:\tools\win-acme\wacs.exe --source iis --siteid (Get-Website "15 Minute War").id --host 15minutewar.starkingdoms.net --validation selfhosting --installation iis --accepttos
```

win-acme adds the `https` binding, and its existing scheduled task renews the certificate.

## Update

```powershell
cd C:\FifteenMinuteWar
git pull
venv\Scripts\pip install -r requirements.txt
venv\Scripts\python manage.py migrate
venv\Scripts\python manage.py collectstatic --noinput
Get-CimInstance Win32_Process -Filter "Name='python.exe'" | ? CommandLine -like '*waitress*8015*' | % { Stop-Process -Id $_.ProcessId }
```

The `15MW Web` task restarts waitress within 5 minutes (or run it now with `Start-ScheduledTask "15MW Web"`).
Logs: `C:\FifteenMinuteWar\logs\`.
