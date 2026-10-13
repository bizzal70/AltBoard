# AltBoard

All your characters at a glance: level, gold, where they are, rested experience, professions and bag space. One addon, one repository: `bizzal70/AltBoard`.

## Workflow

- **No local `.git`.** GitHub holds all history. Publish with `tools\Publish.ps1 -Message "..."`, which uses a throwaway temp clone and runs the tests first.
- **Layout:** the addon's own files (`AltBoard.toc` and the Lua files) sit at the top of the project, because that is what the release packager expects. `tests/`, `tools/` and `.github/` are development-only and are left out of the released zip by `.pkgmeta`.
- **Testing in game:** `tools\Link-Addon.ps1` junctions this folder into the client's `Interface\AddOns` as `AltBoard`. Edits are live after `/reload`; a new file or a TOC change needs a full client restart.
- **Client install:** `C:\Program Files (x86)\World of Warcraft\_classic_beta_\` (`WowB.exe`). Expect a different flavor folder after launch (reported for 2026-11-04); pass `-Flavor` to the link script then.
- **Tests:** `python tests/run.py` runs the addon in real Lua 5.1 (the `lupa` pip package) against a fake WoW API in `tests/wow_stub.lua`, loading the files the TOC lists. The tests run before every publish and again on GitHub. They prove the addon's own logic only; whether the real client behaves like the stub can only be checked in game. Three earlier bugs in sibling addons were wrong assumptions about the game that the fake shared, so anything that calls a game function for the first time is wrapped so a surprise cannot put an error on screen.
- **Releases:** a tag starting with `v` runs `.github/workflows/release.yml`, which uses the BigWigs packager (it recognises this client and builds `-forever.zip` as game version 1.60.1). CurseForge and Wago uploads are skipped until their project IDs are in the TOC and their tokens are in the repository secrets.
- **This repository may be made public.** Keep character names, account details and machine-specific paths out of it.

## How it works

- One record per character in `AltBoardDB.chars[guid]`, account-wide (`SavedVariables`, not per-character): name, realm, class, faction, level, money, zone, xp, xpMax, rested, resting, professions, bagFree, bagTotal, seen.
- `ns.Snapshot` rewrites the current character's record on login and on the events in `REFRESH_EVENTS` (money, level, experience, resting, zone, skills, bags, logout). Each field is only overwritten when the game gives a usable value, so something withheld for a moment does not erase what was known. It runs under `pcall`.
- Rested experience for characters not being played is estimated: 5% of a level per 8 hours when they logged out resting, a quarter of that otherwise, capped at 1.5 levels. Those are the original game's rates and are unverified for Forever; the window marks estimates with `~`.
- `ns.Characters` returns proxies over the saved records (so `key` and `isCurrent` are never written to the saved data), sorted by `sortBy` / `sortDescending`.
- Professions are read with `GetProfessions` / `GetProfessionInfo`, which GatherTrail confirmed works on Forever. Free bag slots come from `C_Container.GetContainerNumFreeSlots` over bags 0 to 4.
- Money shows the game's coin icons through `C_CurrencyInfo.GetCoinTextureString` where available, otherwise as text.
- Not run in the real game when written (2026-10-13). Characters on Forever have a first and last name; what `UnitName` returns for them is unverified.

## Client facts

Everything below, unless marked verified, comes from community sources during the beta (Warcraft Wiki, GitHub ports, fan guides), not from Blizzard docs. Builds change. Verify in game before relying on any of it.

- Local client was 1.60.1.70338 on 2026-10-11 (read from `WowB.exe`).
- TOC: `## Interface: 16001` (verified in game on build 70338).
- TOC flavor suffix is `_Forever.toc` or `_Camelot.toc`. The TOC `[Game]` variable expands to `Camelot`. Game type for `AllowLoadGameType` is `forever` / `camelot`.
- The client is Retail-based: Midnight 12.x API and UI architecture, not the Classic API. Port from Retail code.
- `WOW_PROJECT_ID` is `18` on build 70338 (verified in game 2026-10-11, along with interface 16001, by a starter addon since removed). Community guides written against earlier builds say it is 1 (`WOW_PROJECT_MAINLINE`); that is out of date, so Retail code gated on `WOW_PROJECT_ID == WOW_PROJECT_MAINLINE` will not run here. The name of the constant for 18 is not yet known. Prefer testing for the specific API you need over branching on either number.
- Lua 5.1: no `goto`, no `//`, no bitwise operators (use `bit.band` etc.), no `require`. The TOC is the module loader. Start files with `local addonName, ns = ...`.
- Removed globals: `GetItemInfo`, `GetSpellInfo`, `UnitAura`/`UnitBuff`/`UnitDebuff`, `GetTalentInfo`, `GetNumTalentTabs`, `CombatLogGetCurrentEventInfo`, `InterfaceOptionsFrame_OpenToCategory`. Use `C_Item`, `C_Spell`, `C_UnitAuras`, `C_Traits`, and the `Settings` API.
- `C_Spell.GetSpellInfo` returns a table. Item and spell data can be nil until cached.
- Registering an event that does not exist throws and aborts the file. Wrap speculative `RegisterEvent` calls in `pcall`.
- Secret values (Midnight combat restrictions) are active. In combat, `UnitHealth`, aura data, and some names and booleans can be secret: arithmetic, comparison, and printing fail. Guard with `issecretvalue`, and pass values straight to widgets (`StatusBar:SetValue`, `Cooldown:SetCooldownFromDurationObject`) instead of doing Lua math. Combat-log parsing is not available.
- Check `InCombatLockdown()` before touching protected frames and defer to `PLAYER_REGEN_ENABLED`.
- SavedVariables: initialise in `ADDON_LOADED`. Early beta builds reportedly wrote them but did not read them back; on build 70338 they are read back (confirmed in game 2026-10-11).
