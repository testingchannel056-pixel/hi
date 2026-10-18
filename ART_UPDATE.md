# Murim Life — anime wuxia visual update

Open **this folder's `project.godot`** in Godot 4.6 or newer. Let the editor finish importing, then press **F5**. This update was tested on Godot 4.6.3 with the Compatibility renderer; the original project lists 4.7. Android device performance and exports have not been tested.

For a visual tour, open **`art_gallery.tscn` and press F6**. Select all ten environments and seven opponents, replay Strike / Heavy / Qi, toggle Guard, preview a dodge or defeat, and Reset.

## What changed

- Ten new anime environment illustrations: forest, village, mountain, waterfall, tavern, shrine, fire, cave, sect, home. One shared 1024×1536 atlas; individually named `.tres` resources isolate each scene without extra image copies.
- Eight redrawn cel-shaded fighter identities, each with seven distinct drawn poses: idle, windup, attack, Qi, guard, hurt, defeat. Movement adds anticipation, lunge, recoil and a return to stance. Wolves and beasts have separate animal drawings.
- Layered portraits now power the actual New Life screen, game header, profiles and NPC portraits. New Life has skin, build, hairstyle, hair colour, eye shape, eye colour, mark, beard, outfit and aura choices. The aging preview keeps the same features across a lifetime. Looks remains a gameplay statistic rather than selecting a different face.
- Appearance, outfit and aura persist in player saves. Existing saves without those fields still load with seeded appearances. Combat carries skin, hair colour, outfit colours and a simplified hairstyle into the hero drawing; it does not reproduce every facial detail at combat scale.
- Combat adds bright slash trails, impact stars, sparks, expanding Qi rings, brief heavy-hit shake and hit pause, ground shadows and sparse floating motes. Effects expire, image caches are bounded, and instant-combat mode still skips animation.
- Navy / jade / gold interface palette, enamel stat icons, visible keyboard focus outlines, and a new sword-and-dragon game icon.
- The entry scene uses an explicit resource path so fresh imports do not rely on the uploaded editor's UID cache.

## Files to edit

| Purpose | File |
|---|---|
| Portrait drawing | `scripts/character_art.gd` |
| Appearance options / colours | `scripts/character_data.gd` |
| New Life controls | `scripts/new_life.gd` |
| Player appearance saving | `scripts/player.gd` |
| Fighter drawings and pose cache | `scripts/fighter_art.gd` |
| Attack animation | `scripts/battle_stage.gd` |
| Sparks, rings, motes and shadows | `scripts/combat_effects.gd` |
| Environment artwork | `assets/scenes/anime_environments.png` |
| Environment regions | `assets/scenes/*.tres` |
| Shared interface theme | `ui_pack/murim_theme.gd` |
| Interactive visual preview | `art_gallery.tscn` |

The static SVGs in `assets/fighters/` are the matching default idle drawings. Animated combat uses the pose drawings embedded in `fighter_art.gd`. Its `ART` dictionary contains editable SVG source. No animation plugin is required.

The uploaded `dev/` and `verify/` directories, older character prototypes, original landscape SVGs, music and portrait-layer packs are preserved. They are not the current game entry point; this pass replaces the **active visual workflow**, not those archived prototypes. The old portrait setup warning is removed because portraits no longer require the missing pre-sliced `avatar_*.png` pack.

## Validation

From this folder:

```sh
godot --headless --editor --import
XDG_DATA_HOME="$(mktemp -d)" godot --headless --audio-driver Dummy --script res://tests/art_smoke.gd
```

The smoke test renders all appearance options and 56 poses, enters the real game, checks JSON save compatibility, opens a battle, loads all environments, exercises hit/miss callbacks for every opponent and attack kind, tests effect cleanup, defeat/reset, and instant combat. The JSON round trip uses in-memory data. The full game can autosave during the test, so the command above uses a disposable Linux user-data directory. Use an isolated user-data profile when testing on other platforms. To capture screenshots with a display available, set `MURIM_ART_OUTPUT` to an existing output directory and omit `--headless`.

New scenery was generated for this update with OpenAI image generation. Character, fighter, icon and effects source is editable vector / GDScript artwork; these are stylized 2D drawings rather than a skeletal animation or 3D asset pack. Existing audio and font files retain their original attribution and licensing requirements.
