from django.db import migrations


# Signup and UserSettings.used_theme look up this theme by name and crash if it is missing.
def seed_theme(apps, schema_editor):
    apps.get_model("maingame", "Theme").objects.get_or_create(name="OpenDominion")


class Migration(migrations.Migration):
    dependencies = [("maingame", "0009_remove_dominion_score_dominion_score_list")]
    operations = [migrations.RunPython(seed_theme, migrations.RunPython.noop)]
