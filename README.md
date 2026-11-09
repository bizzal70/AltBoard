# AltGlance

All your characters at a glance: level, gold, where they are, rested experience, professions and bag space. An addon for World of Warcraft: Forever (client 1.60.x).

Formerly called AltBoard. It was renamed in 0.2.0 because another Forever addon, Allemano AltBoard, already uses that name and folder on CurseForge. `/alts` still opens it.

## What it does

AltGlance keeps a line on every character on your account and shows them all in one window, from whichever character you are playing:

| Column | |
|---|---|
| Character | Name, in their class colour |
| Level | |
| Gold | With a total across all characters at the bottom |
| Last seen in | The zone they were in |
| Rested | Rested experience, as a share of a level |
| Professions | With skill levels |
| Bags free | Free slots out of total |
| Played | How long since you last played them |

Click a column heading to sort by it; click again to reverse. Hover a row for more detail.

## Using it

Click the AltGlance button on the minimap, or type `/alts`.

A character appears in the list once you have logged in to them with AltGlance enabled, and their line is brought up to date each time you play them. Characters you have not played since installing it are not listed yet.

| Command | What it does |
|---|---|
| `/alts` | Open the list |
| `/alts forget <name>` | Remove a character you no longer have |
| `/alts button` | Show or hide the minimap button |

You can also remove a character with the small **x** at the end of their row; it takes two presses.

## Good to know

- **Rested experience is estimated** for characters you are not playing. AltGlance knows how much they had when you logged out and whether they were in an inn or city, and works out how much has built up since. Estimates are marked with `~`.
- **Nothing is sent anywhere.** The list is saved on your own computer with the game's other saved settings.
- It records the bags a character carries, not their bank.

## More from this author

Other small addons for World of Warcraft: Forever, all free:

- **[GatherLog](https://www.curseforge.com/wow/addons/gatherlog)** remembers ore, herbs, fishing pools, skinning spots, chests and rares across all your characters, and guides you back to the best spots.
- **[MouseTip](https://www.curseforge.com/wow/addons/mousetip)** shows tooltips at your mouse cursor.
- **[RangeShade](https://www.curseforge.com/wow/addons/rangeshade)** shades action buttons red when your target is out of range.
- **[JunkMate](https://www.curseforge.com/wow/addons/junkmate)** sells junk and repairs at vendors, and warns when your gear is wearing out.
- **[SwiftQuest](https://www.curseforge.com/wow/addons/swiftquest)** accepts quests and hands them in as soon as you talk to the quest giver, without ever choosing a reward for you.
- **[SessionRecap](https://www.curseforge.com/wow/addons/sessionrecap)** keeps a running tally of your play session: gold, experience per hour, quests, gathering and loot.
- **[MacroKit](https://www.curseforge.com/wow/addons/macrokit)** adds ready-made macros for your class and spec, for all nine classes, and never overwrites your own.
- **[ZoomPad](https://www.curseforge.com/wow/addons/zoompad)** puts big + and - buttons on screen that zoom the camera, made for the Steam Deck touchscreen.
- **[GamepadMacros](https://www.curseforge.com/wow/addons/gamepadmacros)** adds ready-made macros for controller and Steam Deck players: heal yourself, use a quest item, save and wear gear, leave a group, emotes.

## Installing

Install it from [CurseForge](https://www.curseforge.com/wow/addons/altglance) with the CurseForge app, or by hand: copy this folder into `World of Warcraft\_forever_\Interface\AddOns\` as `AltGlance`, restart the game, and enable AltGlance on the character select screen.

## Developing

- `tools\Link-Addon.ps1` links this folder into the game's AddOns folder, so edits are live after `/reload`.
- `python tests/run.py` runs the tests (`pip install lupa` once). They run the addon in real Lua 5.1 against a fake of the game's API.
- `tools\Publish.ps1 -Message "..."` runs the tests and pushes to GitHub. GitHub runs the tests again on every push.

## Releasing

`tools\Publish.ps1 -Message "Release x.y.z" -Tag vx.y.z` publishes and tags. The tag makes GitHub package the addon and attach the zip to a GitHub release.

To also upload to CurseForge and Wago, two things are needed once:

1. Create the project on each site, then add its ID to `AltGlance.toc`:
   `## X-Curse-Project-ID: 123456` and `## X-Wago-ID: abc123`.
2. Create an upload token on each site and add it to this repository's secrets (Settings, Secrets and variables, Actions) as `CF_API_KEY` and `WAGO_API_TOKEN`.

Before each release: raise `## Version:` in `AltGlance.toc` and add the version to `CHANGELOG.md`.

## Licence

MIT. See `LICENSE`.
