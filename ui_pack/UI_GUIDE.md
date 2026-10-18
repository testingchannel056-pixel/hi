# UI pack guide (for Claude Code)

This folder is a UI pack for the existing Murim Life project: soft click sounds,
portraits that follow the player's profile, one shared theme, a header bar and a
new character creation screen. It was written without seeing the project, so fit
it to the real code and tell the user what you changed.

Tested: Godot 4.7.2 (Linux build, GL Compatibility, 720x1280). The demo scene ran
with scripted button presses and no script errors. Not tested: an Android device,
and nobody has listened to the sounds yet.

## Files

| File | What it is |
|---|---|
| `ui_sounds.gd` | Autoload. Every Button plays a soft tap and gives a small press bounce, with no other code. |
| `murim_theme.gd` | Colours and `make()`, which returns a Theme for buttons, panels, bars, text fields and scrollbars. |
| `portrait.gd` | A TextureRect that draws a character from a profile Dictionary. |
| `player_header.gd` | Top bar: portrait, name, Health and Qi bars, stat chips. |
| `character_creator.gd` / `.tscn` | Character creation screen. Emits `life_chosen(profile)`. |
| `ui_demo.gd` / `.tscn` | Demo only. Shows everything working together. Do not ship it. |
| `sounds/` | Six WAV files: tap, choice, confirm, back, page, reward. |
| `portraits/` | 166 layer images, 512x512. The game loads these. |
| `portraits_1024/` | The same layers at 1024x1024. Godot ignores this folder (`.gdignore`). |
| `tools/` | Python scripts that made the sounds and portraits. Godot ignores this folder. |

## Rules

- Do NOT rewrite the game's UI. Add the pack to what exists, one step at a time, testing after each.
- Do NOT copy code out of `ui_demo.gd` into the game. It is a demo.
- Keep the look consistent: use the colours in `murim_theme.gd` instead of new hex values.
- The player never picks a face. The portrait is always worked out from the profile.

## Step 1: sounds

1. Project Settings > Globals > Autoload: add `res://ui_pack/ui_sounds.gd` with the name `UiSounds`.
2. If the project already plays a click sound on buttons, remove the old one so buttons do not play two sounds.
3. Give special buttons their own sound with `button.set_meta("ui_sound", "<name>")`:

| Sound | Use it for |
|---|---|
| `tap` | Default. Every ordinary button. |
| `choice` | Picking a choice in an event. |
| `confirm` | Begin a life, confirm a purchase, accept. |
| `back` | Back, close, cancel. |
| `page` | Advancing the month or year, opening a new page. |
| `reward` | Call from code: `UiSounds.play("reward")` on a breakthrough, a technique learned, a big reward. |

4. In the Settings screen, connect the existing sound option to `UiSounds.enabled` and `UiSounds.volume_db`, and save them with the other settings.

## Step 2: theme

On the root Control of each screen:

```gdscript
const UiTheme = preload("res://ui_pack/murim_theme.gd")
theme = UiTheme.make(my_font)   # pass the project's font, or nothing for the default
```

Then remove per-node colour and stylebox overrides that the theme now covers, a screen at a time.
Use `UiTheme.make_bar(color)` and `UiTheme.set_bar(...)` for Health, Qi and stat bars.

## Step 3: portrait

```gdscript
const Portrait = preload("res://ui_pack/portrait.gd")
portrait.set_profile({"name": ..., "gender": ..., "age": ..., "background": ..., "faction": ..., "seed": ...})
```

| Profile key | Effect |
|---|---|
| `age` | Under 13 child, 13-17 teen, 18-50 adult, 51+ elder. There is no baby art; ages 0-5 use the child. |
| `gender` | Anything starting with "f" or "w" is female; everything else male. |
| `faction` | Text containing wudang, shaolin, hua, demon or cult gives that sect's robe and backdrop. Male Shaolin monks are bald. |
| `background` | Used when there is no faction. Matches the words orphan, merchant, scholar, noble, martial, sect, wander, poor, village. |
| `seed` | Fixes skin tone, hair style, hair colour and beard. Save it with the player. Without it the name is used. |
| `outfit` | Optional. Forces one of: peasant, beggar, merchant, scholar, noble, martial, wanderer, disciple, wudang, shaolin, huashan, cult. |

- Add `seed` to the player data and to save/load. Give old saves a seed made from the name.
- Call `set_profile` after anything that can change the look: a birthday, joining or leaving a faction, loading a save.
- Use the `outfit` key for Life Paths and careers when it helps, for example Physician or Scholar to `scholar`, Jianghu Outlaw to `wanderer`, a beggar or thief to `beggar`, a Guard to `martial`.
- NPCs can use the same control: give each NPC its own seed.

## Step 4: header and character creation

- Put `player_header.gd` at the top of the main game screen, or copy its layout into the existing header. Feed it from the real player data; the `chips` list decides which stats show.
- Compare `character_creator.gd` with the project's own creation screen. Keep the project's data and rules (its backgrounds, talents and stat rolls) and take the layout: portrait preview, the four "years to come" portraits, birth cards, talent chips, Reroll fate. The `BACKGROUNDS` and `TALENTS` lists in the script are placeholders.
- Connect `life_chosen(profile)` to the code that starts a new life.

## Changing the art or sounds

- `python3 tools/make_portraits.py` redraws every layer (needs Python with Pillow and NumPy). `python3 tools/make_portraits.py 256` draws on a 256 grid for a chunkier pixel-art look.
- To add an outfit: add a line to `OUTFITS` in `tools/make_portraits.py`, run it, then add the name to `OUTFITS` (and a keyword to `OUTFIT_WORDS`) in `portrait.gd`.
- `python3 tools/make_sounds.py` rebuilds the sounds. The notes and lengths are at the bottom of the file.

## Checks after each step

- New Life: the portrait changes when gender or birth changes, and buttons make the soft tap.
- Age a character past 13, 18 and 51: the portrait changes each time and keeps the same hair colour and skin until old age turns the hair grey.
- Join and leave a faction: the robe and backdrop follow.
- Save, quit, load: the face is the same.
- Turn sound off in Settings: buttons are silent.
- No errors or warnings from `ui_pack` scripts in the Godot output.
