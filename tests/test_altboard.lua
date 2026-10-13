-- The game's side: whichever character is logged in.
ME = {
    guid = "Player-1", name = "Mirabel", class = "Mage", classFile = "MAGE", level = 12, money = 23456,
    zone = "Elwynn Forest", xp = 500, xpMax = 2000, rested = 400, resting = true,
    professions = { [1] = { "Mining", 45, 75 }, [2] = { "Herbalism", 60, 75 } },
    bags = { [0] = { 16, 5 }, { 8, 2 }, { 0, 0 }, { 0, 0 }, { 0, 0 } },   -- bag -> { slots, free }
}
PLAYER_GUID = ME.guid
UnitGUID = function() return ME.guid end
UnitName = function() return ME.name end
GetRealmName = function() return "Stonehold" end
UnitClass = function() return ME.class, ME.classFile end
UnitLevel = function() return ME.level end
GetMoney = function() return ME.money end
GetRealZoneText = function() return ME.zone end
UnitXP = function() return ME.xp end
UnitXPMax = function() return ME.xpMax end
GetXPExhaustion = function() return ME.rested end
IsResting = function() return ME.resting end
GetProfessions = function() return ME.professions[1] and 1 or nil, ME.professions[2] and 2 or nil end
GetProfessionInfo = function(index) local p = ME.professions[index]; return p[1], "icon", p[2], p[3] end
C_Container = {
    GetContainerNumSlots = function(bag) return ME.bags[bag][1] end,
    GetContainerNumFreeSlots = function(bag) return ME.bags[bag][2] end,
}
C_ClassColor = { GetClassColor = function(classFile) if classFile == "MAGE" then return { r = 0.25, g = 0.78, b = 0.92 } end end }
-- The fake clock the addon reads; tests move it forward.
local clock = 1800000000
time = function() return clock end

local ns = LoadAddon(ADDON_DIR, "AltBoard")
local function check(cond, what) if not cond then error("CHECK FAILED: " .. what, 2) end; io.write("pass  ", what, "\n") end
local function near(a, b) return math.abs(a - b) < 0.0001 end

Fire("PLAYER_LOGIN")
check(AltBoardDB == nil, "before its settings load, nothing is recorded")
Fire("ADDON_LOADED", "AltBoard"); Fire("PLAYER_LOGIN")
local me = ns.db.chars["Player-1"]
check(me and me.name == "Mirabel" and me.level == 12 and me.money == 23456 and me.zone == "Elwynn Forest" and me.classFile == "MAGE" and me.faction == "Alliance" and me.realm == "Stonehold", "logging in records the character")
check(#me.professions == 2 and me.professions[1].name == "Mining" and me.professions[1].level == 45 and me.professions[1].max == 75, "with their professions")
check(me.bagFree == 7 and me.bagTotal == 24, "and their free bag space")
check(me.rested == 400 and me.resting == true and me.seen == clock, "and their rested experience and when they were seen")

ME.money = 30000; Fire("PLAYER_MONEY")
ME.level = 13; Fire("PLAYER_LEVEL_UP")
ME.zone = "Westfall"; Fire("ZONE_CHANGED_NEW_AREA")
check(me.money == 30000 and me.level == 13 and me.zone == "Westfall", "money, level and zone are kept up to date as they change")

-- a value the game withholds must not wipe out what is known
local SECRET = {}
issecretvalue = function(v) return v == SECRET end
ME.money = SECRET; Fire("PLAYER_MONEY")
check(me.money == 30000, "a value the game withholds for a moment does not replace the known one")
ME.money = 30000
ME.rested = nil; Fire("UPDATE_EXHAUSTION")
check(me.rested == 0, "no rested experience is recorded as none")
ME.rested = 400; Fire("UPDATE_EXHAUSTION")

-- a second and third character
ME = {
    guid = "Player-2", name = "Tolan", class = "Hunter", classFile = "HUNTER", level = 10, money = 500,
    zone = "Dun Morogh", xp = 0, xpMax = 1000, rested = 0, resting = false, professions = {},
    bags = { [0] = { 16, 16 }, { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } },
}
clock = clock + 3600
Fire("PLAYER_LOGIN")
ME = {
    guid = "Player-3", name = "Aaron", class = "Warrior", classFile = "WARRIOR", level = 30, money = 1000000,
    zone = "Stormwind", xp = 100, xpMax = 10000, rested = 0, resting = true, professions = { [1] = { "Skinning", 150, 225 } },
    bags = { [0] = { 16, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } },
}
clock = clock + 3600
Fire("PLAYER_LOGIN")

local list, total = ns.Characters()
check(#list == 3 and total == 30000 + 500 + 1000000, "every character is listed, with the total of their money")
check(list[1].name == "Aaron" and list[2].name == "Mirabel" and list[3].name == "Tolan", "sorted by level, highest first, to begin with")
check(list[1].isCurrent and not list[2].isCurrent, "and the one being played is marked")

-- rested experience grows while a character is away
local fraction, estimated = ns.Rested(ns.db.chars["Player-1"], false)
check(estimated and near(fraction, 0.2 + 7200 * 0.05 / (8 * 3600)), "a resting character's rested bonus is estimated to have grown while away")
clock = clock + 400 * 3600
fraction = ns.Rested(ns.db.chars["Player-1"], false)
check(near(fraction, 1.5), "but never past one and a half levels")
local outdoors = ns.Rested(ns.db.chars["Player-2"], false)
local inInn = ns.Rested({ xpMax = 1000, rested = 0, resting = true, seen = ns.db.chars["Player-2"].seen }, false)
check(outdoors > 0 and near(math.min(1.5, outdoors * 4), inInn), "and a quarter as fast out in the world")
fraction, estimated = ns.Rested(ns.db.chars["Player-3"], true)
check(not estimated and fraction == 0, "the character being played shows the exact figure")
clock = clock - 400 * 3600

check(ns.Money(1234567) == "123g 45s 67c" and ns.Ago(clock - 7200) == "2 h ago" and ns.Ago(clock - 3 * 86400) == "3 days ago", "money and elapsed time are written plainly")

-- the window
SlashCmdList.ALTBOARD("")
check(AltBoardWindow:IsShown(), "/alts opens the list")
local shown = {}
for _, f in ipairs(Frames()) do
    if rawget(f, "cells") and f.__shown then shown[#shown + 1] = f end
end
check(#shown == 3 and shown[1].cells.name.__text == "Aaron" and shown[2].cells.level.__text == "13", "one row per character, in order")
check(shown[2].cells.professions.__text == "Mining 45, Herbalism 60" and shown[2].cells.bags.__text == "7 / 24", "showing professions and bag space")
check(shown[1].cells.seen.__text == "now" and shown[2].cells.seen.__text == "2 h ago", "and when each was last played")
check(shown[1].cells.money.__text == "100g" and shown[3].cells.money.__text == "5s", "and their money")
check(shown[2].cells.rested.__text:sub(1, 1) == "~", "an estimated rested figure is marked as approximate")
for _, row in ipairs(shown) do row.__scripts.OnEnter(row) end

-- sorting by clicking a heading
local headings = {}
for _, f in ipairs(Frames()) do
    if rawget(f, "column") and f.__scripts.OnClick then headings[f.column.key] = f end
end
headings.name.__scripts.OnClick(headings.name)
list = ns.Characters()
check(ns.db.sortBy == "name" and list[1].name == "Aaron" and list[3].name == "Tolan", "clicking Character sorts A to Z")
headings.name.__scripts.OnClick(headings.name)
list = ns.Characters()
check(list[1].name == "Tolan", "clicking it again reverses the order")
headings.money.__scripts.OnClick(headings.money)
list = ns.Characters()
check(list[1].name == "Aaron" and list[3].name == "Tolan", "clicking Gold sorts richest first")
for key, heading in pairs(headings) do heading.__scripts.OnClick(heading) end
check(true, "every sortable heading sorts without error")

-- removing a character takes two presses
headings.level.__scripts.OnClick(headings.level)
if not ns.db.sortDescending then headings.level.__scripts.OnClick(headings.level) end
local row = nil
for _, f in ipairs(Frames()) do
    if rawget(f, "cells") and f.__shown and f.record.name == "Tolan" then row = f end
end
check(row.remove.__shown and not shown[1].remove.__shown, "every character but the one being played can be removed")
row.remove.__scripts.OnClick(row.remove)
check(ns.db.chars["Player-2"] ~= nil, "one press on the x does not remove anyone")
row.remove.__scripts.OnClick(row.remove)
check(ns.db.chars["Player-2"] == nil and #ns.Characters() == 2, "a second press does")
row.remove.__scripts.OnEnter(row.remove)

SlashCmdList.ALTBOARD("forget aar")
check(ns.db.chars["Player-3"] ~= nil, "/alts forget will not remove the character being played")
SlashCmdList.ALTBOARD("forget nobody")
SlashCmdList.ALTBOARD("forget mira")
check(ns.db.chars["Player-1"] == nil and #ns.Characters() == 1, "/alts forget removes a character by the start of their name")

-- the minimap button
check(AltBoardMinimapButton.__shown, "the minimap button shows by default")
AltBoardMinimapButton.__scripts.OnClick(AltBoardMinimapButton)
check(not AltBoardWindow:IsShown(), "and toggles the list")
AltBoardMinimapButton.__scripts.OnEnter(AltBoardMinimapButton)
AltBoardMinimapButton.__scripts.OnDragStart(AltBoardMinimapButton)
AltBoardMinimapButton.__scripts.OnUpdate(AltBoardMinimapButton, 0.1)
AltBoardMinimapButton.__scripts.OnDragStop(AltBoardMinimapButton)
SlashCmdList.ALTBOARD("button")
check(not AltBoardMinimapButton.__shown and not ns.db.minimapButton, "/alts button hides it")
SlashCmdList.ALTBOARD("button")
AltBoard_OnAddonCompartmentClick()
check(AltBoardWindow:IsShown(), "the minimap addon list entry opens the list")
SlashCmdList.ALTBOARD("help")

-- the game misbehaving must not leave an error on screen
UnitXPMax = function() error("something this client does differently") end
local ok = pcall(Fire, "PLAYER_XP_UPDATE")
check(ok, "a surprise from the game while recording does not raise an error")
