local addonName, ns = ...

-- Keeps a short record of every character on the account (level, gold,
-- where they are, rested experience, professions, bag space) so they can
-- all be seen at once, from whichever character is logged in.
--
-- A character's record is refreshed while that character is played; the
-- others are shown as they were when last seen.

-- The backpack and the four bag slots.
local FIRST_BAG, LAST_BAG = 0, 4
-- Rested experience is capped at one and a half levels.
local RESTED_CAP_LEVELS = 1.5
-- In an inn or city a character rests a twentieth of a level every eight
-- hours; elsewhere, a quarter as fast. From the original game; treated
-- here as an estimate.
local RESTED_PER_SECOND = 0.05 / (8 * 3600)
local RESTED_OUTDOORS = 0.25

local defaults = {
    minimapButton = true,
    minimapAngle = 2.6,
    -- Which column the list is sorted by, and which way.
    sortBy = "level",
    sortDescending = true,
}

function ns.Print(msg)
    print("|cffd9a066AltBoard|r: " .. tostring(msg))
end

-- A value the client may withhold cannot be compared or stored.
local function Usable(value)
    return value ~= nil and not (issecretvalue and issecretvalue(value))
end
ns.Usable = Usable

-- 12345 copper -> "1g 23s 45c"
function ns.Money(copper)
    copper = math.floor(copper + 0.5)
    local gold = math.floor(copper / 10000)
    local silver = math.floor(copper / 100) % 100
    local rest = copper % 100
    local parts = {}
    if gold > 0 then parts[#parts + 1] = gold .. "g" end
    if silver > 0 then parts[#parts + 1] = silver .. "s" end
    if rest > 0 or #parts == 0 then parts[#parts + 1] = rest .. "c" end
    return table.concat(parts, " ")
end

-- "3 min ago", "2 h ago", "5 days ago"
function ns.Ago(timestamp)
    local seconds = math.max(0, time() - timestamp)
    if seconds < 90 then
        return "just now"
    elseif seconds < 5400 then
        return ("%d min ago"):format(seconds / 60)
    elseif seconds < 172800 then
        return ("%d h ago"):format(seconds / 3600)
    end
    return ("%d days ago"):format(seconds / 86400)
end

---------------------------------------------------------------------------
-- Recording the character being played
---------------------------------------------------------------------------

function ns.CurrentKey()
    local guid = UnitGUID("player")
    return Usable(guid) and guid or nil
end

-- Sets a field only when the game gave a usable answer, so a value it
-- withholds for a moment does not wipe out what was known.
local function Keep(record, field, value)
    if Usable(value) then
        record[field] = value
    end
end

local function ReadProfessions()
    if not GetProfessions or not GetProfessionInfo then return end
    local professions = {}
    for slot = 1, 5 do
        local index = (select(slot, GetProfessions()))
        if Usable(index) then
            local name, _, level, maxLevel = GetProfessionInfo(index)
            if Usable(name) and Usable(level) then
                professions[#professions + 1] = { name = name, level = level, max = Usable(maxLevel) and maxLevel or nil }
            end
        end
    end
    return professions
end

local function ReadBags()
    local free, total = 0, 0
    for bag = FIRST_BAG, LAST_BAG do
        local slots = C_Container.GetContainerNumSlots(bag)
        local open = C_Container.GetContainerNumFreeSlots(bag)
        if not Usable(slots) or not Usable(open) then return end
        free, total = free + open, total + slots
    end
    return free, total
end

-- Writes down how the current character stands right now.
function ns.Snapshot()
    local key = ns.CurrentKey()
    if not key then return end
    local record = ns.db.chars[key]
    if not record then
        record = {}
        ns.db.chars[key] = record
    end

    Keep(record, "name", UnitName("player"))
    Keep(record, "realm", GetRealmName())
    local className, classFile = UnitClass("player")
    Keep(record, "class", className)
    Keep(record, "classFile", classFile)
    Keep(record, "faction", UnitFactionGroup("player"))
    Keep(record, "level", UnitLevel("player"))
    Keep(record, "money", GetMoney())
    Keep(record, "zone", GetRealZoneText())

    Keep(record, "xp", UnitXP("player"))
    Keep(record, "xpMax", UnitXPMax("player"))
    -- nil from the game means "not rested", which is an answer too.
    local rested = GetXPExhaustion()
    if rested == nil or Usable(rested) then
        record.rested = rested or 0
    end
    local resting = IsResting()
    if Usable(resting) then
        record.resting = resting and true or false
    end

    local professions = ReadProfessions()
    if professions then record.professions = professions end
    local free, total = ReadBags()
    if free then
        record.bagFree, record.bagTotal = free, total
    end

    record.seen = time()
    return record
end

---------------------------------------------------------------------------
-- Reading the records back
---------------------------------------------------------------------------

-- Rested experience as a fraction of a level: what was recorded, and for a
-- character who is not being played, what it has probably grown to since.
-- The second value says whether the figure is such an estimate.
function ns.Rested(record, isCurrent)
    if not record.xpMax or record.xpMax <= 0 then return 0, false end
    local fraction = (record.rested or 0) / record.xpMax
    if isCurrent or not record.seen then return fraction, false end
    local rate = RESTED_PER_SECOND * (record.resting and 1 or RESTED_OUTDOORS)
    local grown = fraction + math.max(0, time() - record.seen) * rate
    return math.min(RESTED_CAP_LEVELS, grown), true
end

local SORTS = {
    name = function(record) return (record.name or ""):lower() end,
    level = function(record) return record.level or 0 end,
    money = function(record) return record.money or 0 end,
    zone = function(record) return (record.zone or ""):lower() end,
    rested = function(record) return (ns.Rested(record, record.isCurrent)) end,
    bags = function(record) return record.bagFree or -1 end,
    seen = function(record) return record.seen or 0 end,
}
ns.SORTS = SORTS

-- Every character on record, sorted as the settings say, with the total
-- money across them. Each entry is the saved record plus its key and
-- whether it is the character being played.
function ns.Characters()
    local current = ns.CurrentKey()
    local list, total = {}, 0
    for key, record in pairs(ns.db.chars) do
        local entry = setmetatable({ key = key, isCurrent = key == current }, { __index = record })
        list[#list + 1] = entry
        total = total + (record.money or 0)
    end
    local value = SORTS[ns.db.sortBy] or SORTS.level
    local descending = ns.db.sortDescending
    table.sort(list, function(a, b)
        local va, vb = value(a), value(b)
        if va ~= vb then
            if descending then return va > vb end
            return va < vb
        end
        -- Same in the sorted column: by name, so the order is steady.
        return (a.name or "") < (b.name or "")
    end)
    return list, total
end

-- Removes a character's record. Returns their name if there was one.
function ns.Forget(key)
    local record = ns.db.chars[key]
    if not record then return end
    ns.db.chars[key] = nil
    return record.name or "that character"
end

-- Finds a record by the start of its name, ignoring case.
local function FindByName(text)
    text = text:lower()
    local found
    for key, record in pairs(ns.db.chars) do
        if record.name and record.name:lower():sub(1, #text) == text then
            if found then return nil, "more than one character's name starts with that" end
            found = key
        end
    end
    return found, "no character on record has a name starting with that"
end

SLASH_ALTBOARD1 = "/altboard"
SLASH_ALTBOARD2 = "/alts"
SlashCmdList.ALTBOARD = function(msg)
    local command, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    command = command:lower()
    if command == "" then
        ns.ToggleWindow()
    elseif command == "button" then
        ns.db.minimapButton = not ns.db.minimapButton
        ns.UpdateMinimapButton()
        ns.Print("Minimap button " .. (ns.db.minimapButton and "shown." or "hidden."))
    elseif command == "forget" and rest ~= "" then
        local key, problem = FindByName(rest)
        if not key then
            ns.Print("Nothing removed: " .. problem .. ".")
        elseif key == ns.CurrentKey() then
            ns.Print("That is the character you are playing; their record would only come straight back.")
        else
            ns.Print(("Removed %s from the list."):format(ns.Forget(key)))
            ns.RefreshWindow()
        end
    else
        ns.Print("/alts - open the list of your characters")
        ns.Print("/alts forget <name> - remove a character you no longer have")
        ns.Print("/alts button - show or hide the minimap button")
    end
end

-- Entry in the minimap's addon list.
function AltBoard_OnAddonCompartmentClick()
    ns.ToggleWindow()
end

-- What changes a character's record while they are played.
local REFRESH_EVENTS = {
    "PLAYER_MONEY", "PLAYER_LEVEL_UP", "PLAYER_XP_UPDATE", "UPDATE_EXHAUSTION",
    "PLAYER_UPDATE_RESTING", "ZONE_CHANGED_NEW_AREA", "SKILL_LINES_CHANGED",
    "BAG_UPDATE_DELAYED", "PLAYER_LOGOUT",
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, loaded)
    if event == "ADDON_LOADED" then
        if loaded ~= addonName then return end
        AltBoardDB = AltBoardDB or {}
        for key, value in pairs(defaults) do
            if AltBoardDB[key] == nil then
                AltBoardDB[key] = value
            end
        end
        AltBoardDB.chars = AltBoardDB.chars or {}
        ns.db = AltBoardDB
        self:UnregisterEvent("ADDON_LOADED")
        return
    end
    if not ns.db then return end
    if event == "PLAYER_LOGIN" then
        -- Registering an event this client does not have throws.
        for _, name in ipairs(REFRESH_EVENTS) do
            pcall(self.RegisterEvent, self, name)
        end
        ns.UpdateMinimapButton()
    end
    -- Reading the character must never put an error on screen.
    if pcall(ns.Snapshot) then
        ns.RefreshWindow()
    end
end)
