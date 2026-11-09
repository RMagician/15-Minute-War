from django.db import migrations

# Colours restored from the hard-coded themes in templates/base.html before commit c434baa,
# plus "SKlone", a dark indigo-and-brass palette (default). Inputs default to white/black.
THEMES = {
    "SKlone": dict(base_background="#101828", base_text="#ece4d0", card_background="#1a2540", card_text="#ece4d0",
                   header_background="#0b111f", header_text="#ece4d0", input_background="#0b111f", input_text="#ece4d0"),
    "OpenDominion": dict(base_background="#ffffff", base_text="#000000", card_background="#ecf0f5", card_text="#000000",
                         header_background="#3c8dbc", header_text="#ffffff"),
    "ODA": dict(base_background="#ffffff", base_text="#000000", card_background="#ecf0f5", card_text="#000000",
                header_background="#dd4b39", header_text="#ffffff"),
    "Mustard and blue": dict(base_background="#003049", base_text="#ffffff", card_background="#181818", card_text="#edede9",
                             header_background="#fca311", header_text="#000000"),
    "Blood and beige": dict(base_background="#fdf0d5", base_text="#000000", card_background="#003049", card_text="#ffffff",
                            header_background="#780000", header_text="#ffffff"),
    "It's a boy": dict(base_background="#caf0f8", base_text="#000000", card_background="#003049", card_text="#ffffff",
                       header_background="#0077b6", header_text="#ffffff"),
    "Elesh Norn": dict(base_background="#800020", base_text="#ffffff", card_background="#334149", card_text="#ffffff",
                       header_background="#fffff0", header_text="#000000"),
    "Swampy": dict(base_background="#59a96a", base_text="#ffffff", card_background="#636940", card_text="#ffffff",
                   header_background="#474a2c", header_text="#ffffff"),
}


def seed_themes(apps, schema_editor):
    Theme = apps.get_model("maingame", "Theme")
    for name, colours in THEMES.items():
        Theme.objects.update_or_create(name=name, defaults=colours)


class Migration(migrations.Migration):
    dependencies = [("maingame", "0010_seed_opendominion_theme")]
    operations = [migrations.RunPython(seed_themes, migrations.RunPython.noop)]
