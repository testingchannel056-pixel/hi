# Content pack import guide (for Claude Code)

This folder is a content pack for the existing Murim Life project: 247 events
(`events.json`) and 29 endings (`endings.json`). It was written for a small
standalone prototype, so its stat names and scales differ from the real project.

Rules for using it:

- Treat `events.json` and `endings.json` as the source of truth. Their schema is in `README.md`.
- Do NOT import `main.gd` or `main.tscn`. They are a reference for how the data is meant to behave, nothing more.
- Do the import in Phase 6 and 7 of the master prompt (conditional events, flags, adventures), and the endings in Phase 11. Do not start before the audit and save/load are done.
- The mapping below was written without seeing the project. After your audit, correct anything that does not match the real code, and tell the user what you changed.
- Convert the data into the project's own scenario format with a one-off script, and keep the result in a data file, not in `game.gd`.

## Stat mapping

| Pack stat | Project stat | Notes |
|---|---|---|
| `body` | Strength | |
| `movement` | Agility | |
| `comprehension` | Martial Insight | |
| `health`, `max_health`, `qi`, `max_qi`, `gold`, `age` | same | |
| `realm` 0..6 | cultivation stage | Mortal = Commoner ... Profound = Immortal, one to one |
| `fame` | Reputation | |
| `infamy` | Karma (negative) | `infamy+3` becomes Karma -3; `infamy>=40` becomes Karma <= -40 |
| `shame` | NEW: one counter named Shame | Nothing existing covers "despised cheat" as opposed to "feared villain". The scoundrel endings need it. Add it as a single hidden-or-visible number; do not add anything else for it. |
| `dao_heart` | Willpower if it gets added, otherwise Happiness | In the pack, reaching 0 is death by qi deviation. In the project make that a serious injury or cultivation setback unless the user wants it lethal (master prompt rule 9). |
| `luck` | existing luck if any | If there is none, treat luck checks as plain rolls and let the Fortune's Favourite talent add a bonus. |

Good deeds in the pack usually give `fame` only. When converting, also give a
small Karma gain to outcomes that raise `dao_heart` through kindness, so Karma
moves in both directions.

## Scale

Pack stats run from 5 to about 14, and reputation from 0 to about 150. Rescale
to the project's ranges rather than copying numbers.

| Pack check | Project difficulty label |
|---|---|
| `rel` 0 or lower, fixed difficulty 4-5 | Easy |
| `rel` +1, fixed 6 | Moderate |
| `rel` +2, fixed 7 | Difficult |
| `rel` +3 or +4, fixed 8 | Very Difficult |
| `rel` +5 and above | Nearly Impossible |

Combat choices (`combat` with `power` or `rel`) should start the project's
existing turn-based combat with an enemy of matching difficulty, or resolve as
a single check where a full fight would be too much. Stat rewards of +1 or +2
mean "one or two normal training gains". Reputation gates and ending
thresholds: keep the proportions in the README's "Reputation scale" table.

## Structure mapping

| Pack feature | Project system |
|---|---|
| Event with no `goto` | Life Event (scenario) |
| Events linked by `goto` | Adventure stages (section 27). Chains: `purse_child`; `rain_temple` -> `black_box` / `black_box_stolen`; `sect_library` / `sell_secrets` -> `sect_trial_theft` -> `expelled`; `cult_initiation` / `cult_defector` -> `cult_escape`; `escort_cargo` -> `escort_girl`; `tournament` -> `tournament_semi` -> `tournament_final`; `ruins` -> `ruins_chamber` |
| Events linked by flags over years | Long adventures spanning years: rival, master's murder, fallen clan, sworn brother, family, impostor, debt, wanted, frost sword, blood art, demon sword, tomb curse, great war |
| `flags` / `not_flags` / `flag` / `unflag` | Persistent event flags (section 26). Use the names as they are. |
| `min` / `max` / `requires` on choices | Conditional choices (section 6) |
| `once`, `repeat`, `hidden`, `weight` | Scenario selection rules. The pack assumes one event per year; with monthly turns, lower the chance per month so a life does not burn through the pool. |
| `learn` techniques (15, listed in README) | Entries in TECHNIQUES. Give each a type, level and effect. |
| `die` | Death with an epilogue |
| `origin` event | Skip it. Use its five options as flavour for the Backgrounds system. |
| Built-in breakthrough, `healer`, `quiet_year` | Skip or adapt; the project has its own cultivation and actions. |
| Youth events (`age<=16` to `20`) | The pack starts at age 12. Spread these across the Child and Teen stages. |

## Named characters become persistent NPCs

Create these as real NPCs when their first event fires, and drive the later
events from the NPC's state instead of bare flags where practical.

| NPC | Role | First event | Related flags |
|---|---|---|---|
| Wei Lang | rival | `meet_rival` | `rival`, `rival_friend`, `rival_enemy` |
| Master Yun | master | `old_fisher` | `has_master`, `master_dead`, `knows_killer` |
| Elder Mok | master's killer | `killer_clue` | `knows_killer` |
| Zhao Hu | sworn brother | `brother_meet` | `sworn_brother`, `brother_betrayed` |
| Lin Yue | spouse | `meet_lin_yue` | `lover`, `married`, `has_child`, `abandoned_family` |
| Guo Tian | clan enemy | `clan_clue` | `clan_enemy` |

Lin Yue is written as a woman and the player is never gendered. If the project
supports romance for any player gender, keep her as is; otherwise generate the
partner's name and gender and substitute it in the text.

## Factions

Wudang, Shaolin, Mount Hua and the Demonic Cult match the project's factions
(the pack calls the last one the Heavenly Demon Cult). The pack also uses the
Beggars' Union, the Green Forest bandits, the Nightless Pavilion (assassins) and
the White Tiger Escort Agency. Add these as minor factions or as Life Paths
(Jianghu Outlaw, Guard), whichever the audit shows is simpler. Pack flags
`inner`, `elder`, `sect_leader`, `cult_elder`, `cult_lord`, `bandit_chief` are
faction ranks.

## Endings become epilogue titles

`endings.json` is an ordered list; the first entry whose conditions match is
the title. Keep that order. Translate the conditions with the stat mapping
above, then add the project's own factors (career, family, wealth, sect) as
extra titles around them. The three reputation ladders must survive the
translation:

- Hero: Local Hero -> Great Hero -> A Legend of the Murim
- Villain: Local Terror -> Feared Villain -> Calamity of the Age
- Scoundrel: Petty Rogue -> Shameless Scoundrel -> The Greatest Scumbag Under Heaven

## Checks after import

- Every event has at least one choice with no conditions.
- Every `goto` target exists, and every flag that is required somewhere is set somewhere.
- Adapt `tools/simulate.py` or write an equivalent, and confirm that random play rarely reaches a top title while a committed hero, villain or scoundrel can.
