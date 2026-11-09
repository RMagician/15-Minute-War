# 15 Minute War

A free, text-based strategy game in a medieval fantasy setting. Petty kingdoms ("dominions") build, train armies, and invade each other. The game advances in **ticks**: one tick every 15 minutes, 4 per hour.

Built with Django 5.1 and SQLite. Server-rendered templates, with htmx, jQuery and Tom Select loaded from CDNs.

## Requirements

- **Python 3.10 or newer** (Django 5.1 needs at least 3.10). On Windows, install it from python.org. The Microsoft Store `python` alias does not count as an install.
- **pip** and **venv** (included with Python).
- **Git**.
- Internet access in the browser. The pages load CSS and JS from CDNs (jsdelivr, unpkg, cdnjs, code.jquery.com, Google Fonts, canvasjs).

You do not need a separate database server. The game uses SQLite (`db.sqlite3`, which git ignores).

Python packages (`requirements.txt`): Django, whitenoise (static files), gunicorn (production only), python-dotenv (installed but not used yet).

## Local setup

```bash
git clone https://github.com/RMagician/15-Minute-War.git
cd 15-Minute-War

python -m venv venv          # or, with uv: uv venv --python 3.12 venv
# Windows (PowerShell):  venv\Scripts\Activate.ps1
# macOS/Linux:           source venv/bin/activate

pip install -r requirements.txt

python manage.py migrate
python manage.py createsuperuser
```

`migrate` also creates the colour themes (migrations `0010` and `0011`). Signup needs them. The default is `SKlone`, a dark indigo-and-brass theme. Layout and typography live in `static/css/game.css`; themes only set colours. The original light `OpenDominion` theme and six others are also restored. Players pick a theme on the Options page. Edit the colours in Django admin at `/admin/`.

### Create the game world

```bash
python manage.py init_round
```

> **Warning:** `init_round` **deletes all game data**: dominions, battles, events, units, buildings, spells and the round. It then rebuilds factions, units, buildings and discoveries, and creates a new 7-day round. User accounts are kept. Never run it on a live server mid-round.

### Run the server

```bash
python manage.py runserver
```

Open http://127.0.0.1:8000, sign up at `/accounts/signup/`, then register a dominion.

## Starting a round and running ticks

The round does nothing until it starts and ticks run.

1. **Set a start time.** In `/admin/` open the **Round** and set `start_time`. Times are in `America/New_York`.
2. **Run ticks.** Each call to `do_tick` advances the game one tick. The first tick after `start_time` marks the round as started. Each later tick advances it.

```bash
python manage.py do_tick      # 1 tick
python manage.py 12tick       # 12 ticks (3 hours of game time)
python manage.py 48tick       # 48 ticks
python manage.py 96tick       # 96 ticks
```

For a real game, schedule `do_tick` every 15 minutes. Linux cron example:

```cron
*/15 * * * * cd /path/to/15-Minute-War && venv/bin/python manage.py do_tick >> tick.log 2>&1
```

On Windows, use Task Scheduler. On PythonAnywhere, use a scheduled task.

New dominions start in **protection**. Players skip their protection ticks from the UI. Those ticks run per player, not on the global clock.

## Other management commands

| Command | What it does |
|---|---|
| `init_round` | Wipes all game data and builds a fresh round. Destructive. |
| `do_tick`, `12tick`, `48tick`, `96tick` | Run 1, 12, 48 or 96 global ticks. |
| `duplicate_theme <id> <name>` | Copies a theme under a new name. |
| `audit_bugs`, `check_bugs`, `check_upgrade_use`, `costcalc`, `casualty_mod_cost_comparison` | Developer diagnostics. |
| `debug`, `debug_rpgs`, `debugsetup`, `*me` (e.g. `dwarfme`, `sludgeme`) | Developer test scripts. They expect specific users and dominions (`test`, `admin`, "The Tet"), and most fail on a fresh database. `debugsetup` also resets the world. |
| `delete_user` | Deletes the hard-coded test accounts `asdf`, `test2`–`test5`, `new`, `newb`, `noob`. |

## Project layout

```
odalike/        Django project: settings, root urls, wsgi/asgi
accounts/       Signup view
maingame/       The game: models, views, tick logic, templates, management commands
  game_pieces/  Faction, unit, building and discovery definitions
  utils/        Invasion, trade, faction helpers
templates/      Base layout, header, sidebar, login and signup pages
static/         Source static files
staticfiles/    collectstatic output (committed)
```

## Production deployment

There is no CI/CD. To deploy: `git pull`, `python manage.py migrate`, `python manage.py collectstatic`, then restart gunicorn (`gunicorn odalike.wsgi`).

Before you expose the server to the internet, edit `odalike/settings.py`:

- **Set `DJANGO_SECRET_KEY`** as an environment variable. The fallback key in the file is public.
- **Set `DEBUG = False`.** It is hard-coded to `True`. With debug on, error pages leak code and settings.
- **Update `ALLOWED_HOSTS` and `CSRF_TRUSTED_ORIGINS`** for your domain.
- **Add `AUTH_PASSWORD_VALIDATORS`.** The list is empty, so any password is accepted.
- **Run `python manage.py collectstatic`** after any static change.

### Known security issues

- **`/run_tick_view/<n>` runs global ticks for user `test`.** Any visitor can sign up as `test` and run the game clock. Reserve that username, or gate the view with `is_superuser`.
- **Theme colour fields go straight into a `<style>` block.** A user can inject arbitrary CSS into pages that use that theme. Validate the values as hex colours.
