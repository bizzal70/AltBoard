# AltBoard

All your characters at a glance: level, gold, where they are, rested experience, professions and bag space. An addon for World of Warcraft: Forever (client 1.60.x).

## What it does

AltBoard keeps a line on every character on your account and shows them all in one window, from whichever character you are playing:

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

Click the AltBoard button on the minimap, or type `/alts`.

A character appears in the list once you have logged in to them with AltBoard enabled, and their line is brought up to date each time you play them. Characters you have not played since installing it are not listed yet.

| Command | What it does |
|---|---|
| `/alts` | Open the list |
| `/alts forget <name>` | Remove a character you no longer have |
| `/alts button` | Show or hide the minimap button |

You can also remove a character with the small **x** at the end of their row; it takes two presses.

## Good to know

- **Rested experience is estimated** for characters you are not playing. AltBoard knows how much they had when you logged out and whether they were in an inn or city, and works out how much has built up since. Estimates are marked with `~`.
- **Nothing is sent anywhere.** The list is saved on your own computer with the game's other saved settings.
- It records the bags a character carries, not their bank.

## Installing

Copy this folder into `World of Warcraft\_classic_beta_\Interface\AddOns\` as `AltBoard`, restart the game, and enable AltBoard on the character select screen.

## Developing

- `tools\Link-Addon.ps1` links this folder into the game's AddOns folder, so edits are live after `/reload`.
- `python tests/run.py` runs the tests (`pip install lupa` once). They run the addon in real Lua 5.1 against a fake of the game's API.
- `tools\Publish.ps1 -Message "..."` runs the tests and pushes to GitHub. GitHub runs the tests again on every push.

## Releasing

`tools\Publish.ps1 -Message "Release x.y.z" -Tag vx.y.z` publishes and tags. The tag makes GitHub package the addon and attach the zip to a GitHub release.

To also upload to CurseForge and Wago, two things are needed once:

1. Create the project on each site, then add its ID to `AltBoard.toc`:
   `## X-Curse-Project-ID: 123456` and `## X-Wago-ID: abc123`.
2. Create an upload token on each site and add it to this repository's secrets (Settings, Secrets and variables, Actions) as `CF_API_KEY` and `WAGO_API_TOKEN`.

Before each release: raise `## Version:` in `AltBoard.toc` and add the version to `CHANGELOG.md`.

## Licence

MIT. See `LICENSE`.
