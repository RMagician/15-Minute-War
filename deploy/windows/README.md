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
setx /M DJANGO_ALLOWED_HOSTS "game.example.com"
setx /M DJANGO_CSRF_TRUSTED_ORIGINS "https://game.example.com"
# Open a new shell so the variables apply, then:

venv\Scripts\python manage.py migrate
venv\Scripts\python manage.py init_round      # fresh DB only, it wipes round data
venv\Scripts\python manage.py collectstatic --noinput
venv\Scripts\python manage.py createsuperuser
deploy\windows\install_tasks.ps1
```

Set the round `start_time` in `/admin`.

## IIS site

1. Create folder `C:\inetpub\15mw` and copy `deploy\windows\web.config` into it.
2. IIS Manager: add a site with that path, binding `http` + host name of the domain.
3. Get a certificate with win-acme for the new site (it adds the `https` binding).

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
