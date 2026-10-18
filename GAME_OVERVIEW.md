> **Visual update:** See `ART_UPDATE.md` for the current appearance system, anime environments and combat animation. The portrait/customization descriptions below document the uploaded version and are now historical.

# Murim Life: what is in the game so far

This describes the current state of the project, so that an assistant who has not seen the code can help with it. Exact numbers are constants at the top of each script, each with a comment.

## 1. What the game is

Murim Life is a text life-simulator set in a murim (martial-arts) world. You are born, grow up month by month, make choices in short scenarios, train, cultivate Qi, choose a life path, marry and raise children, join or found a sect, fight, and die with a title that sums up the life. A grown child can carry on after you. All text, rules and art are original.

- Engine: Godot 4.7.2, GDScript, "GL Compatibility" renderer.
- Screen: portrait, 720 x 1280, stretch mode `canvas_items`, aspect `expand`.
- Target: Android phones, to be published on the Google Play Store and monetized later.
- The developer is a beginner with Godot. The code is kept simple on purpose: plain GDScript without type hints, short commented functions, and game content stored as plain dictionaries in data files.

## 2. Files

| File | What it does |
|---|---|
| `main.tscn`, `game.gd` | The one game screen and its script (about 2,450 lines): time, events, choices, menus, sects, fights, pop-ups, settings. Nodes are reached with unique names such as `%Story`. |
| `new_life.tscn`, `scripts/new_life.gd` | The New Life (character creation) screen. |
| `scripts/player.gd` | The character: stats, age, cultivation, dice formulas, inventory, save data. |
| `scripts/world_data.gd` | Built-in content: scenarios, happenings, enemies, sects, talents, items, activities, relationship roles. |
| `scripts/life_data.gd`, `life_manager.gd` | Backgrounds, talent growth, life paths, career ranks, work, property, cost of living, portrait outfits (data), and the rules for them. |
| `scripts/npc_data.gd`, `npc_manager.gd` | The people in your life: how they are made, age, change, die, and the Relationships menu. |
| `scripts/family_data.gd`, `family_manager.gd` | Siblings, courtship, marriage, children. |
| `scripts/career_data.gd` | Scenarios that belong to one life path. |
| `scripts/story_manager.gd` | Story flags, scenarios that chain into each other, the Journal. |
| `scripts/pack_import.gd` | Turns `content_pack/events.json` into scenarios when the game starts. |
| `scripts/martial_data.gd`, `martial_manager.gd` | Martial techniques. |
| `scripts/faction_manager.gd` | Your name in the jianghu and what each great sect thinks of you. |
| `scripts/sect.gd`, `sect_data.gd` | The sect you can found, and events for its leader. |
| `scripts/legacy_manager.gd` | The title and story at the end of a life, and heirs. |
| `scripts/chronicle_manager.gd` | The Jianghu Chronicle: records and achievements across all lives. |
| `scripts/requirements.gd` | Checks a "needs" list such as `{"age": 13, "Smarts": 55}`. |
| `scripts/my_scenarios.gd` | The developer's own scenarios, with templates and the list of allowed words. |
| `scripts/battle_stage.gd` | Draws and animates a fight. |
| `scripts/save_manager.gd` | Writes a life to `user://life.json` and reads it back. |
| `scripts/game_theme.gd` | The look of the whole game, built on `ui_pack/murim_theme.gd`. |
| `scripts/music.gd` | Plays `assets/music/background.ogg/.mp3/.wav` on a loop. |
| `content_pack/` | `events.json` (247 events) and `endings.json` (29 endings) from a prototype. Read as they are; never edited. |
| `ui_pack/` | UI pack: button sounds, theme colours, 100 painted avatars chosen by the Looks stat. See section 19. |
| `assets/scenes/*.svg` | 10 page pictures: forest, village, mountain, waterfall, tavern, shrine, fire, cave, sect, home. |
| `assets/fighters/*.svg` | 8 fighter pictures. A PNG with the same name replaces the SVG. |
| `assets/ui/*.svg` | Small icons. |

Not used by the game and safe to delete: `scripts/click_sound.gd`, the old appearance prototypes (`character_customization.tscn`, `character_parts.tscn`, `make_avatars.gd`, `scripts/character_customization.gd`, `scripts/character_parts.gd`, `scripts/character_visual.gd`, `tools/make_character.gd`), `install_ui_pack.gd` once it has been run, the first UI pack's layer pictures (everything in `ui_pack/portraits/` that does not start with `avatar_`, the folder `ui_pack/portraits_1024/`, `ui_pack/tools/make_portraits.py`), and the folders `dev` and `verify`.

## 3. Screen layout

From top to bottom:

1. Top bar: menu button, game title, settings button.
2. Header panel: portrait (chosen by your Looks, age and gender, see section 19), name, cultivation stage badge, date (age, month, year, sect), Health bar, Qi bar.
3. Eight stat chips: Strength, Agility, Insight, Gold, Karma, Reputation, Merit, Actions.
4. The page: a framed picture, story text typed out letter by letter, then numbered choices. Number keys 1 to 9 also press the choices.
5. Bottom dock: Profile, a large "+ Age" button, Inventory, More.

Pop-ups (they scroll when long): Profile (with your portrait and a word for your Looks), Inventory, Settings, Menu (Save life, Load life, New life, Journal, Jianghu Chronicle, Credits), How to fight.

## 4. Character creation ("New Life" screen)

The player chooses a name (or a random one), gender, three starting attributes with sliders from 0 to 100 (Health, Smarts, Happiness), one of eight backgrounds and one of seven talents. Looks is dealt by fate: its slider cannot be moved (`FATED` in `scripts/new_life.gd`), only rerolled. The player never chooses a face: a large portrait with a word for the Looks under it ("Plain", "Striking") and four small ones (young, adult, mature, elder) follow gender and Looks. "Reroll fate" deals new numbers, Looks included.

Backgrounds (each gives starting stats, decides your parents' work, and opens one life path early): Poor Village, Merchant Family, Martial Clan, Sect Family, Scholar Family, Noble Family, Orphan (no parents; a temple caretaker raises you, with its own birth and childhood scenarios), Wandering Family.

Talents: None, Iron Body, Wind Step, Scholar's Mind, Heavenly Meridians, Silver Tongue, Fortune's Favourite. Each talent can grow twice in a life, through an awakening scenario, when its requirements are met (`TALENT_STEPS` in `life_data.gd`).

## 5. Stats

| Stat | Range | Notes |
|---|---|---|
| Health | 0 to max | Max starts at 100 and grows with each breakthrough. At 0 you die. |
| Qi | 0 to capacity | Needed for breakthroughs, Qi strikes and technique moves. |
| Strength, Agility, Martial Insight | 1 to cap | Start at 5. Cap is 15, plus 8 per stage. |
| Happiness, Smarts, Looks, Willpower | 0 to 100 | Willpower helps breakthroughs. At 0 your Qi runs wild: you lose half your Qi and 30 Health. |
| Karma | -100 to 100 | Good or evil. Orthodox sects expel you below -20. |
| Reputation | 0 and up | Fame for your deeds. Ranks you in Orthodox sects. Fades a little each year. |
| Shame | 0 and up | How despised you are as a cheat and coward. Fades a little each year. |
| Merit, Gold | 0 and up | Merit ranks you in the Demonic Cult. |

There is no separate Fame stat. Cultivation stages, weakest first: Commoner, Third-Class, Second-Class, First-Class, Peak, Transcendent, Immortal.

## 6. Time and events

- "Continue" passes one month. "+ Age" skips to the next birthday.
- From age 6 the player has 1 action per month for the More menu.
- Each month rolls one event: 4% a once-in-a-lifetime scenario, 25% an ordinary scenario with choices (more on a wandering life path), otherwise a small "happening" with no choice. A birthday reached with "+ Age" brings a scenario with choices 80% of the time.
- People and sects can bring their own events: a rival's challenge, an enemy's ambush, a sect that hunts you.
- A scenario cannot come back until 5 others have passed.
- The very first page (birth) is already a choice. Birthdays 1 to 5 each have a fixed milestone choice.
- On each birthday: people age, bonds fade, your path pays you, living costs are taken, techniques and stories move on, your sect pays a stipend.
- Lifespan is 65 to 85 years, plus 15 per breakthrough.

About 320 scenarios are in the pool: the game's own in `world_data.gd`, `life_data.gd`, `family_data.gd`, `career_data.gd` and `sect_data.gd`, the developer's in `my_scenarios.gd`, and 242 imported from the content pack.

## 7. Scenario format

Scenarios are dictionaries. Example:

```gdscript
{
	"id": "fox_in_bamboo", "title": "The Fox",
	"text": "A fox watches you from the bamboo.",
	"image": "forest",
	"min_age": 8,
	"needs": {"Agility": 6},
	"choices": [
		{"label": "Follow it", "stat": "Agility", "difficulty": 14,
			"win": {"Gold": 10, "flag": ["followed_fox"]}, "win_text": "It leads you to a dropped purse.",
			"lose": {"Health": -10}, "lose_text": "You fall into a ditch."},
		{"label": "Leave it alone", "win": {"Karma": 1}},
	],
},
```

Words a scenario can use: `text`, `choices`, `image`, `min_age` (6 if left out), `max_age`, `faction`, `unique` (rare, once per life), `needs`, `id`, `title`, `once`, `repeat`, `hidden` (only reached through `goto`), `weight`.

Words a choice can use: `label`, `win`, `lose`, `win_text`, `lose_text`, `needs` (a choice you do not qualify for is greyed out with the reason, or hidden if the reason is a story flag), and at most one test:

- `stat` + `difficulty`: a dice roll. Strength, Agility and Martial Insight use 10 easy, 14 normal, 18 hard. Smarts, Looks, Happiness, Willpower and Reputation use 30 easy, 50 normal, 70 hard.
- `percent`: pure luck.
- `fight`: a battle against `wolf`, `bandit`, `initiate`, `duelist`, `cultist` or `beast`. `friendly: true` makes it a duel that cannot kill. `mercy: true` stops it before death.

Extras on a choice: `item`, `meet` (a person joins your life), `talent_up`, `regard` (changes what a sect thinks of you).

`win` and `lose` can change any stat, `Qi Capacity`, `Max Health`, the bond with a person by role (`Mother`, `Father`, `Sibling`, `Spouse`, `Child`, `Master`, `Friend`, `Rival` and so on), your sect's `Disciples`, `Elders` and `Sect Fame`, and can hold `flag` and `unflag` (lists of flag names), `learn` (a technique's id), `goto` (the next scenario's id) and `die` (true). In text, `{Master}` or `{Spouse}` is replaced by that person's name.

`needs` uses one format everywhere (see the top of `scripts/requirements.gd`): stat minimums, `age`, `stage`, `max`, `background`, `talent`, `talent_level`, `path`, `path_rank`, `sect`, `faction`, `relation`, `no_relation`, `leads_sect`, `item`, `technique`, `flag`, `not_flag`, `count`.

The game checks the developer's scenarios at start-up, leaves out any with a mistake, and shows the mistake on the first page (only when run from the editor). `TEST_MY_SCENARIOS = true` plays only the developer's scenarios.

## 8. The More menu (1 action per month, from age 6)

More is split into five groups:

- Life: Rest, Work (pays by life path and rank), Study the classics, Steady your mind (Willpower), Tend your appearance, Life path (from 13).
- Martial: Cultivate, Train strength, Train agility, Study martial arts, Martial arts (your techniques and practising them).
- Jianghu: Seek adventure (brings a scenario this month), Visit a tea house, Hunt (a fight).
- People: Relationships, Visit the matchmaker, Sect.
- Money: Market, Property (from 18).

"Attempt a breakthrough" appears at the top when you have enough Qi.

## 9. Cultivation and breakthroughs

- One session gives `(2 + Martial Insight / 4 + bonuses)` Qi, multiplied by a streak bonus (10% per year in a row that you cultivated, up to 6 years), your talent, and mood.
- A breakthrough needs `100 * (stage + 1)^3` Qi: 100, 800, 2,700 and so on.
- The chance rises with Martial Insight and Willpower. A jade pill or the blood arts (both from stories) make it certain.
- Success: next stage, Strength, Agility and Martial Insight +6 each, more max Health, lifespan +15, larger Qi capacity.
- Failure: half your Qi is lost, Health -25, Happiness -10.

## 10. Life paths, work and money

- From age 13 you choose one of 12 life paths: Farmer, Martial Disciple, Scholar, Craftsman, Merchant, Physician, Wanderer, Sect Heir, Jianghu Outlaw, Teacher, Hunter, Guard. Each has requirements, yearly rewards, stats it trains more easily, and its own scenarios. You can change path when you meet another one's requirements.
- Each path has three ranks. Promotion needs years on the path plus requirements. Pay rises 60% per rank.
- From 18 a year of living costs 8 Gold, plus 4 for each small child, plus 3% of your Gold above 100. A year you cannot pay for costs Health and Happiness.
- Property: Cottage, Market Stall, Shop, Courtyard House, Estate. Each gives something every year.

## 11. People, family and heirs

- People are full characters: name, gender, age, lifespan, personality, occupation, sect, cultivation stage, a bond from 0 to 100, a short history, and their own `looks` and `seed`, which choose the portrait shown on their page. They age, grow stronger, marry and die.
- Roles: Father, Mother, Caretaker, Sibling, Spouse, Partner, Child, Master, Friend, Rival, Disciple, Acquaintance, Enemy.
- Actions with a person: Spend time together, Ask for guidance, Spar, learn a technique from a Master, court and propose, raise a child, offer peace to an enemy.
- You can be born with siblings, court someone you know or visit the matchmaker (15 Gold), marry from 18, and have children, who choose a calling of their own when they grow up.
- When you die, a child of 16 or older can carry on. The heir inherits half your Gold, a quarter of your Reputation, your property and your best technique, and keeps the looks and face they had as your child.

## 12. Stories, flags and the content pack

- A choice can set a flag ("helped_swordsman"). Later scenarios and choices can ask for it with `needs`.
- A choice can lead straight into another scenario with `goto`, so stories run over several pages or years.
- The Journal (in the Menu) lists the stories that are hanging over you.
- `scripts/pack_import.gd` reads `content_pack/events.json` at start-up and converts 242 of its 247 events (five repeat things the game already has). The pack's `fame` becomes Reputation, rewards are halved, and its fights stop before they kill.

## 13. Martial techniques

19 techniques in `martial_data.gd`, each with up to 3 levels. They are learned from a Master (needs a strong bond and a gift), from your sect (by rank), or from stories, and deepened by practising. They add damage, accuracy, armour, guard, Qi from cultivation and more. Four of them add a move of their own in a fight.

## 14. Factions and sects

- Orthodox: Shaolin (trains Strength), Mount Hua (Agility), Wudang (Martial Insight), Beggars' Union (Agility). Unorthodox: the Demonic Cult (Strength).
- Ranks: Outer Disciple, Inner Disciple, Core Disciple, Elder (at 0, 25, 60, 120 points of Reputation, or Merit in the Cult). Yearly stipend: 5, 10, 20, 40 Gold.
- Your name in the jianghu comes from Reputation ("Unknown" to "Legendary"), from deeply negative Karma ("feared across the province") or from Shame ("known as a shameless scoundrel").
- Each great sect has a regard for you, changed by what you do. A sect that hates you enough sends people after you.
- Founding your own sect needs 100 Gold and the Second-Class stage. You build facilities, recruit disciples, gain elders and fame, wage war on rivals, and get eight events that only a sect leader sees.

## 15. Inventory and Market

| Item | Effect | Price |
|---|---|---|
| Healing Pill | Health +30 | 15 |
| Qi Pill | Qi +25 | 25 |
| Spirit Herb | Health +15, Qi +10 | 20 |
| Wine Gourd | Happiness +15 | 6 |
| Fine Robe | Looks +5 | 30 |
| Martial Manual | Martial Insight +1 | 60 |

## 16. Fights (turn-based, with a fight scene)

The page picture becomes the arena, with a health bar for each side. Each turn the opponent's next move is shown (strike 60%, heavy blow 20%, guard 20%), then the player picks a move:

| Move | Effect |
|---|---|
| Strike | Damage from Strength, techniques and a die. |
| Heavy blow | 60% more damage, 25 points less chance to hit. |
| Guard | Take half damage this turn; your next blow cannot miss. |
| Qi strike | Costs Qi. Cannot miss, adds Martial Insight, ignores a guard. |
| Techniques | The moves your techniques add, each usable once per fight. |
| Fortune stick | Once per fight, free: blows 10% or 20% stronger or weaker. |
| Auto-fight | Strikes every turn until the fight ends. |
| Flee / Yield | Flee may fail and cost the turn. Yield ends a friendly duel. |
| Use an item | From the Inventory. Takes the turn. |

Enemies: Mountain Wolf, Mountain Bandit, Cult Initiate, Wandering Swordsman, Demonic Cultist, Spirit Beast, plus people you know (duels, ambushes). They grow stronger with the player's stage. Animation is done with Godot tweens on still pictures.

## 17. Death, titles and the Chronicle

- You die when Health reaches 0, when you reach your lifespan, or when a story ends you.
- The last page gives the life a title and tells its story from the turning points it remembered. There are 41 titles: the pack's 29 and 12 of the game's own. Three ladders must stay intact: Hero (Reputation), Villain (negative Karma), Scoundrel (Shame).
- Then: "Live on as" a grown child, or "Be reborn" on the New Life screen.
- The Jianghu Chronicle (`user://chronicle.json`) is kept across all lives: totals, endings found, 22 achievements, techniques and paths seen, and a list of past lives.

## 18. Saving, settings and sound

- One life is saved at a time, as JSON in `user://life.json`, with a backup of the save before it. The game saves by itself at the end of every month and when a scenario begins. Death deletes the save.
- The game opens straight into the saved life. A scenario that was waiting for an answer is shown again. A fight in progress is not saved.
- `life_data()` and `load_life_data()` in `game.gd` decide what is saved. Missing keys fall back to defaults, so older saves keep loading.
- Settings (saved in `user://settings.cfg`): text speed, fight speed, button sound (Off, Quiet, Normal), music on or off, music volume.
- Background music loops if a music file is present.

## 19. The UI pack (`ui_pack/`)

| Pack file | How the game uses it |
|---|---|
| `ui_sounds.gd` | The `UiSounds` autoload (Project Settings > Globals). Every button makes a soft tap and a small press bounce. A button gets another sound with `button.set_meta("ui_sound", "choice")`. The sounds are tap, choice, confirm, back, page, and reward (played from code with `game.chime()`). |
| `murim_theme.gd` | The colours (INK, PANEL, PAPER, DIM, GOLD, RED, JADE) and the base theme. `scripts/game_theme.gd` adds the game's own pieces to it (AgeButton, Chip, Dock, DockButton, HintLabel, TitleLabel, Badge, PopupCard). `apply_look()` in `game.gd` puts the theme on at start-up, so scenes look plain in the editor. |
| `portrait.gd` | Shows one ready-made avatar for a profile `{"gender", "age", "looks", "seed"}`. Looks picks one of 10 tiers (0-9 Hideous up to 90-100 Peerless), age picks young (under 18), adult (18-35), mature (36-50) or elder (51+), and adults and mature characters with Looks under 20 get the separate "ugly" faces. Nobody picks a face; background, sect and life path do not change it. Used in the header, the Profile, the New Life screen and on each person's page. `portrait_profile()` in `game.gd` builds the player's profile and `profile(person)` in `npc_manager.gd` a person's. The player's seed is `player.face_seed`, saved as `seed`. |
| `portraits/` | 100 painted avatars, 128 x 128, named `avatar_<gender>_<stage>_<tier>_<set>.png`. They were cut from one image-generated sheet (`tools/sheets/sheet_0.png`), so everyone of the same gender, age group and Looks tier has the same face. They look soft when shown much larger than 128 pixels. A second sheet would give `seed` something to choose between. |
| `player_header.gd`, `character_creator.gd/.tscn` | Not loaded by the game. Their layouts were followed in `main.tscn` and `new_life.tscn`, with the game's own data and text sizes. |
| `ui_demo.gd/.tscn` | The pack's demo. Not part of the game; leave it out of an export. |

## 20. Not in the game yet

- Ads, in-app purchases, or any other monetization.
- Android export setup and Play Store assets. Nothing has been tested on a phone. An export needs `*.json` added to its file filter so the content pack is included.
- More than one face per gender, age group and Looks tier (needs a second avatar sheet), and child or baby faces (children use the young faces).
- Sound effects in fights. The player's fighter picture is the same for every character.
- Translations.
- Careful balancing. The numbers are a first pass.
