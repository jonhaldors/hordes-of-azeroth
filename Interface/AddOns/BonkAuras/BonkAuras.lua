BonkAuras = {}
local DB

local DEFAULT_CONFIG = "BKA15cS87:PhCG:PhJnVJpp?We{BoWe{sd"
local ICON_PREFIX = "Interface\\Icons\\"
local BUFF_BUTTONS = 24

local STRINGS = {
    zhCN = {
        title = "BonkAuras  ·  /wa",
        unlock = "解锁拖动",
        lock = "锁定位置",
        clear = "清除全部",
        hint = "点击下方条目添加监控图标，也可输入法术 ID 手动添加。解锁后可拖动图标调整位置，右键图标取消跟踪；右侧已跟踪列表也可右键取消。",
        buffs = "当前玩家 Buff",
        tracked = "已跟踪（右键取消）：",
        states = "Hordes 天赋状态",
        buff = "Buff ",
        language = "语言：",
        follow = "跟随 HOA",
        grey = "未生效：灰色",
        hide = "未生效：隐藏",
        unknown = "未知状态",
        manual = "手动添加 Buff ID",
        add = "添加",
        id_bad = "未找到该 ID 的法术：",
        id_added = "已添加：",
        show_ids = "显示 Buff ID：",
        tooltips = "追踪图标 Tooltip：",
        on = "开",
        off = "关",
        remove_hint = "右键取消跟踪",
        export = "导出配置",
        import = "导入配置",
        io_label = "配置字符串：",
        io_export_hint = "下面的字符串已全选，按 Ctrl+C 复制。",
        io_import_hint = "粘贴配置字符串后点“导入”。导入会替换当前全部监控。",
        copy_all = "全选",
        import_ok = "导入成功：",
        import_bad = "配置字符串无效",
        profiles = "配置页",
        profile_title = "配置页管理",
        profile_hint = "点击配置页切换。修改名称后点“保存”；切换页面时会自动保存当前页。账号通用对所有角色可见；角色专用仅当前角色可见。",
        profile_new = "新建",
        profile_save = "保存",
        profile_saved = "已保存",
        profile_rename = "重命名",
        profile_delete = "删除",
        profile_scope = "作用域：",
        profile_account = "账号通用",
        profile_character = "角色专用",
        profile_toggle_scope = "切换作用域",
        profile_name = "名称：",
        profile_keep = "至少保留一个配置页",
        profile_default = "默认",
        profile_new_name = "配置 ",
        profile_name_empty = "名称不能为空",
    },
    enUS = {
        title = "BonkAuras  ·  /wa",
        unlock = "Unlock",
        lock = "Lock",
        clear = "Clear all",
        hint = "Click an entry below to track it, or enter a spell ID. Unlocked, drag icons to move them; right-click an icon or a tracked entry to stop tracking it.",
        buffs = "Your buffs",
        tracked = "Tracked (right-click to remove): ",
        states = "Hordes states",
        buff = "Buff ",
        language = "Language: ",
        follow = "Follow HOA",
        grey = "Inactive: grey",
        hide = "Inactive: hidden",
        unknown = "Unknown state",
        manual = "Add buff by ID",
        add = "Add",
        id_bad = "No spell with that ID: ",
        id_added = "Added: ",
        show_ids = "Show buff IDs: ",
        tooltips = "Tracker tooltips: ",
        on = "on",
        off = "off",
        remove_hint = "Right-click to stop tracking",
        export = "Export",
        import = "Import",
        io_label = "Configuration string:",
        io_export_hint = "The string below is selected; press Ctrl+C to copy it.",
        io_import_hint = "Paste a configuration string, then press Import. Importing replaces all current trackers.",
        copy_all = "Select all",
        import_ok = "Imported: ",
        import_bad = "Invalid configuration string",
        profiles = "Profiles",
        profile_title = "Profile management",
        profile_hint = "Click a profile to switch. Press Save after editing the name; switching profiles also saves the current one. Account profiles are shared by every character; character profiles are visible only to the current character.",
        profile_new = "New",
        profile_save = "Save",
        profile_saved = "Saved",
        profile_rename = "Rename",
        profile_delete = "Delete",
        profile_scope = "Scope: ",
        profile_account = "Account",
        profile_character = "Character",
        profile_toggle_scope = "Toggle scope",
        profile_name = "Name: ",
        profile_keep = "Keep at least one profile",
        profile_default = "Default",
        profile_new_name = "Profile ",
        profile_name_empty = "The name cannot be empty",
    },
}

local STATE_DEFS = {
    { key = "shield",        name = "Shield",        desc = "Shield is restored after 4 sec without taking damage.", icon = "Interface\\Icons\\Spell_Holy_PowerWordShield" },
    { key = "dash",          name = "Dash",          desc = "Dash a short distance in the direction you're moving. In midair, you dash the way you're facing.", icon = "Interface\\Icons\\Ability_Rogue_Sprint" },
    { key = "determination", name = "Determination", desc = nil, icon = "Interface\\Icons\\Spell_Holy_DevotionAura" },
    { key = "necrotic",      name = "Necrotic x",    desc = nil, icon = "Interface\\Icons\\Spell_Shadow_CurseOfSargeras" },
    { key = "wounds",        name = "Wounded x",     desc = nil, icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain" },
}

local stateValues = {
    shield = { value = 0, max = 0 },
    dash = { charges = 0, max = 0, left = 0, cooldown = 0 },
    determination = { stacks = 0, percent = "0" },
    necrotic = { stacks = 0, percent = "0" },
    wounds = { stacks = 0, percent = "0" },
}

local trackers = {}
local buffTooltipHooked = {}
local config
local ioFrame
local profileFrame
local SaveActivePage
local ticker

local function Split(text, separator)
    local fields = {}
    local start = 1
    while true do
        local found = string.find(text, separator, start, true)
        if not found then
            table.insert(fields, string.sub(text, start))
            return fields
        end
        table.insert(fields, string.sub(text, start, found - 1))
        start = found + 1
    end
end

local function Language()
    if DB and DB.language and DB.language ~= "auto" then
        return DB.language
    end
    if VanillaBonkLocale and VanillaBonkLocale.language then
        return VanillaBonkLocale.language
    end
    if GetLocale then
        return GetLocale()
    end
    return "enUS"
end

local function T(key)
    local strings = STRINGS[Language()] or STRINGS.enUS
    return strings[key] or STRINGS.enUS[key] or key
end

local function HOA(text)
    if VanillaBonkL then
        return VanillaBonkL[text]
    end
    return text
end

local function StateDef(key)
    for _, def in ipairs(STATE_DEFS) do
        if def.key == key then
            return def
        end
    end
end

local function StateName(key)
    local def = StateDef(key)
    if not def then
        return T("unknown")
    end
    local name = HOA(def.name)
    if string.sub(name, -1) == "x" or string.sub(name, -1) == "X" then
        name = string.sub(name, 1, -2)
        while string.sub(name, -1) == " " do
            name = string.sub(name, 1, -2)
        end
    end
    return name
end

local function StateDescription(key)
    local def = StateDef(key)
    if def and def.desc then
        return HOA(def.desc)
    end
    return ""
end

local function IconName(icon)
    if icon and string.sub(icon, 1, string.len(ICON_PREFIX)) == ICON_PREFIX then
        return string.sub(icon, string.len(ICON_PREFIX) + 1)
    end
end

local function IconId(icon)
    local name = IconName(icon)
    if name and BonkAurasSpellIndex and BonkAurasSpellIndex.icons then
        return BonkAurasSpellIndex.icons[name]
    end
end

local function IdIcon(id)
    local name = BonkAurasSpellIndex and BonkAurasSpellIndex.ids and BonkAurasSpellIndex.ids[id]
    if name then
        return ICON_PREFIX .. name
    end
end

local B85 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-:+=^!/*?&<>()[]{}@%$#"
local B85_INDEX = {}
for index = 1, string.len(B85) do
    B85_INDEX[string.sub(B85, index, index)] = index - 1
end

local function Round(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

local function ZigZag(value)
    if value < 0 then
        return -value * 2 - 1
    end
    return value * 2
end

local function UnZigZag(value)
    if math.mod(value, 2) == 1 then
        return -math.floor((value + 1) / 2)
    end
    return math.floor(value / 2)
end

local function EncodeVarint(value)
    local out = ""
    while value >= 128 do
        out = out .. string.char(math.mod(value, 128) + 128)
        value = math.floor(value / 128)
    end
    return out .. string.char(value)
end

local function ReadVarint(data, position)
    local value = 0
    local factor = 1
    local bytes = 0
    while true do
        local byte = string.byte(data, position)
        if not byte then
            return nil
        end
        position = position + 1
        bytes = bytes + 1
        value = value + math.mod(byte, 128) * factor
        if byte < 128 then
            return value, position
        end
        factor = factor * 128
        if bytes >= 5 or factor > 4294967296 then
            return nil
        end
    end
end

local function Encode85(data)
    local out = ""
    local index = 1
    local length = string.len(data)
    while index <= length do
        local b1 = string.byte(data, index) or 0
        local b2 = string.byte(data, index + 1) or 0
        local b3 = string.byte(data, index + 2) or 0
        local b4 = string.byte(data, index + 3) or 0
        local value = ((b1 * 256 + b2) * 256 + b3) * 256 + b4
        for power = 4, 0, -1 do
            local unit = 85 ^ power
            local digit = math.floor(value / unit)
            value = value - digit * unit
            out = out .. string.sub(B85, digit + 1, digit + 1)
        end
        index = index + 4
    end
    return out
end

local function Decode85(text)
    if math.mod(string.len(text), 5) ~= 0 then
        return nil
    end
    local out = ""
    local index = 1
    local length = string.len(text)
    while index <= length do
        local value = 0
        for offset = 0, 4 do
            local digit = B85_INDEX[string.sub(text, index + offset, index + offset)]
            if not digit then
                return nil
            end
            value = value * 85 + digit
        end
        if value > 4294967295 then
            return nil
        end
        local b1 = math.floor(value / 16777216)
        value = value - b1 * 16777216
        local b2 = math.floor(value / 65536)
        value = value - b2 * 65536
        local b3 = math.floor(value / 256)
        local b4 = value - b3 * 256
        out = out .. string.char(b1, b2, b3, b4)
        index = index + 5
    end
    return out
end

local function StateIndex(key)
    for index, def in ipairs(STATE_DEFS) do
        if def.key == key then
            return index
        end
    end
end

local function EncodeConfig()
    local language = 0
    if DB.language == "zhCN" then
        language = 1
    elseif DB.language == "enUS" then
        language = 2
    end
    local flags = language
    if DB.inactive == "hide" then
        flags = flags + 4
    end
    if DB.showIds then
        flags = flags + 8
    end
    if not DB.showTooltips then
        flags = flags + 16
    end
    local payload = string.char(flags) .. EncodeVarint(getn(DB.trackers))
    for index = 1, getn(DB.trackers) do
        local entry = DB.trackers[index]
        local stateIndex
        if entry.kind == "state" then
            stateIndex = StateIndex(entry.state)
        end
        local x = Round(entry.x)
        local y = Round(entry.y)
        if stateIndex then
            payload = payload .. string.char(stateIndex) .. EncodeVarint(ZigZag(x)) .. EncodeVarint(ZigZag(y))
        else
            local id = entry.spellId
            if not (id and IdIcon(id)) then
                local name = IconName(entry.icon)
                id = name and BonkAurasSpellIndex and BonkAurasSpellIndex.icons and BonkAurasSpellIndex.icons[name]
            end
            if id then
                payload = payload .. string.char(6) .. EncodeVarint(ZigZag(x)) .. EncodeVarint(ZigZag(y)) .. EncodeVarint(id)
            else
                local icon = entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
                local name = IconName(icon)
                if name then
                    icon = name
                end
                payload = payload .. string.char(7) .. EncodeVarint(ZigZag(x)) .. EncodeVarint(ZigZag(y)) .. EncodeVarint(string.len(icon)) .. icon
            end
        end
    end
    return "BKA1" .. Encode85(payload)
end

local function DecodeConfig(text)
    if not text then
        return nil
    end
    text = string.gsub(text, "%s", "")
    if string.len(text) > 20000 or string.sub(text, 1, 4) ~= "BKA1" then
        return nil
    end
    local data = Decode85(string.sub(text, 5))
    if not data then
        return nil
    end
    local position = 1
    local flags = string.byte(data, position)
    if not flags then
        return nil
    end
    position = position + 1
    local count
    count, position = ReadVarint(data, position)
    if not count or count > 200 then
        return nil
    end
    local entries = {}
    for index = 1, count do
        local kind = string.byte(data, position)
        if not kind then
            return nil
        end
        position = position + 1
        local x, y
        x, position = ReadVarint(data, position)
        if not x then
            return nil
        end
        y, position = ReadVarint(data, position)
        if not y then
            return nil
        end
        x = UnZigZag(x)
        y = UnZigZag(y)
        if x < -10000 or x > 10000 or y < -10000 or y > 10000 then
            return nil
        end
        local entry
        if kind >= 1 and kind <= 5 then
            local def = STATE_DEFS[kind]
            entry = { kind = "state", state = def.key, icon = def.icon }
        elseif kind == 6 then
            local id
            id, position = ReadVarint(data, position)
            if not id then
                return nil
            end
            local icon = IdIcon(id)
            if not icon then
                return nil
            end
            entry = { kind = "aura", icon = icon, spellId = id }
        elseif kind == 7 then
            local length
            length, position = ReadVarint(data, position)
            if not length or length < 1 or length > 200 or position + length - 1 > string.len(data) then
                return nil
            end
            local icon = string.sub(data, position, position + length - 1)
            position = position + length
            if string.find(icon, "\\", 1, true) == nil then
                icon = ICON_PREFIX .. icon
            end
            entry = { kind = "aura", icon = icon }
        else
            return nil
        end
        entry.x = x
        entry.y = y
        table.insert(entries, entry)
    end
    local language = "auto"
    local languageCode = math.mod(flags, 4)
    if languageCode == 1 then
        language = "zhCN"
    elseif languageCode == 2 then
        language = "enUS"
    end
    return {
        language = language,
        inactive = math.mod(flags, 8) >= 4 and "hide" or "grey",
        showIds = math.mod(flags, 16) >= 8,
        showTooltips = math.mod(flags, 32) < 16,
        entries = entries,
    }
end

local function Short(value)
    value = tonumber(value) or 0
    if value >= 1000000 then
        return string.format("%.1fM", value / 1000000)
    elseif value >= 1000 then
        return string.format("%.1fK", value / 1000)
    end
    return math.floor(value)
end

local function FormatTime(seconds)
    seconds = tonumber(seconds) or 0
    if seconds <= 0 then
        return ""
    end
    if seconds >= 60 then
        return string.format("%d:%02d", math.floor(seconds / 60), math.floor(math.mod(seconds, 60)))
    end
    return tostring(math.ceil(seconds))
end

local function PlayerBuffs()
    local list = {}
    local seen = {}
    for index = 0, 63 do
        local position = GetPlayerBuff(index)
        if position < 0 then
            break
        end
        local icon = GetPlayerBuffTexture(position)
        if icon and not seen[icon] then
            seen[icon] = true
            table.insert(list, {
                position = position,
                icon = icon,
                id = IconId(icon),
                stacks = GetPlayerBuffApplications(position) or 1,
                left = GetPlayerBuffTimeLeft(position) or 0,
            })
        end
    end
    return list
end

local function FrameIcon(button)
    local function usable(texture)
        return texture and not string.find(texture, "Overlays", 1, true)
    end
    local name = button.GetName and button:GetName()
    if name then
        local icon = getglobal(name .. "Icon")
        if icon and icon.GetTexture and usable(icon:GetTexture()) then
            return icon:GetTexture()
        end
    end
    local regions = {button:GetRegions()}
    for index = 1, getn(regions) do
        local region = regions[index]
        if region.GetTexture then
            local texture = region:GetTexture()
            if usable(texture) then
                return texture
            end
        end
    end
end

local function SavePosition(tracker)
    local cx, cy = tracker:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if cx and ux then
        tracker.entry.x = cx - ux
        tracker.entry.y = cy - uy
        if SaveActivePage then
            SaveActivePage()
        end
    end
end

local function StateStacks(entry)
    if entry.state == "determination" then
        return stateValues.determination.stacks > 0 and tostring(stateValues.determination.stacks) or ""
    elseif entry.state == "necrotic" then
        return stateValues.necrotic.stacks > 0 and tostring(stateValues.necrotic.stacks) or ""
    elseif entry.state == "wounds" then
        return stateValues.wounds.stacks > 0 and tostring(stateValues.wounds.stacks) or ""
    end
    return ""
end

local function StateValue(entry)
    if entry.state == "shield" then
        return Short(stateValues.shield.value)
    elseif entry.state == "dash" then
        return stateValues.dash.charges .. "/" .. stateValues.dash.max
    end
    return ""
end

local function StateTime(entry)
    if entry.state == "dash" then
        return FormatTime(stateValues.dash.left)
    end
    return ""
end

local function StateActive(entry)
    if entry.state == "shield" then
        return stateValues.shield.value > 0
    elseif entry.state == "dash" then
        return stateValues.dash.max > 0
    elseif entry.state == "determination" then
        return stateValues.determination.stacks > 0
    elseif entry.state == "necrotic" then
        return stateValues.necrotic.stacks > 0
    elseif entry.state == "wounds" then
        return stateValues.wounds.stacks > 0
    end
    return false
end

local function SetInactive(tracker, inactive)
    if inactive and DB.inactive == "hide" then
        tracker:SetAlpha(0)
    elseif inactive then
        tracker:SetAlpha(0.42)
        tracker.icon:SetDesaturated(true)
        tracker.glow:SetAlpha(0)
    else
        tracker:SetAlpha(1)
        tracker.icon:SetDesaturated(false)
        tracker.glow:SetAlpha(1)
    end
end

local function RefreshTracker(tracker, buffs)
    local entry = tracker.entry
    if entry.kind == "aura" then
        buffs = buffs or PlayerBuffs()
        local found
        for _, buff in ipairs(buffs) do
            if buff.icon == entry.icon then
                found = buff
                break
            end
        end
        tracker.icon:SetTexture(entry.icon)
        if found then
            tracker.stacks:SetText(found.stacks > 1 and tostring(found.stacks) or "")
            tracker.value:SetText("")
            tracker.time:SetText(FormatTime(found.left))
            SetInactive(tracker, false)
        else
            tracker.stacks:SetText("")
            tracker.value:SetText("")
            tracker.time:SetText("")
            SetInactive(tracker, true)
        end
        tracker:Show()
    else
        tracker.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        if StateActive(entry) then
            tracker.stacks:SetText(StateStacks(entry))
            tracker.value:SetText(StateValue(entry))
            tracker.time:SetText(StateTime(entry))
            SetInactive(tracker, false)
        else
            tracker.stacks:SetText("")
            tracker.value:SetText("")
            tracker.time:SetText("")
            SetInactive(tracker, true)
        end
        tracker:Show()
    end
end

local function UpdateLock()
    for _, tracker in ipairs(trackers) do
        if DB.unlocked then
            tracker:EnableMouse(true)
            tracker:RegisterForDrag("LeftButton")
        else
            tracker:EnableMouse(false)
            tracker:RegisterForDrag()
        end
    end
end

local function RemoveTracker(tracker)
    if not tracker then
        return
    end
    tracker:Hide()
    for index, existing in ipairs(DB.trackers) do
        if existing == tracker.entry then
            table.remove(DB.trackers, index)
            break
        end
    end
    for index, existing in ipairs(trackers) do
        if existing == tracker then
            table.remove(trackers, index)
            break
        end
    end
    if config and config:IsShown() then
        BonkAuras:UpdateConfig()
    end
    if SaveActivePage then
        SaveActivePage()
    end
end

local function CreateTracker(entry)
    local tracker = CreateFrame("Frame", nil, UIParent)
    tracker:SetWidth(36)
    tracker:SetHeight(36)
    tracker:SetPoint("CENTER", UIParent, "CENTER", entry.x or 0, entry.y or 0)
    tracker:SetMovable(true)
    tracker:SetClampedToScreen(true)
    tracker:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = 1, tileSize = 8, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    tracker:SetBackdropColor(0, 0, 0, 0.55)
    tracker:SetBackdropBorderColor(0, 0, 0, 0.7)
    tracker.entry = entry

    tracker.icon = tracker:CreateTexture(nil, "ARTWORK")
    tracker.icon:SetPoint("TOPLEFT", tracker, "TOPLEFT", 3, -3)
    tracker.icon:SetPoint("BOTTOMRIGHT", tracker, "BOTTOMRIGHT", -3, 3)
    tracker.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

    tracker.glow = tracker:CreateTexture(nil, "BORDER")
    tracker.glow:SetPoint("TOPLEFT", tracker, "TOPLEFT", 2, -2)
    tracker.glow:SetPoint("BOTTOMRIGHT", tracker, "BOTTOMRIGHT", -2, 2)
    tracker.glow:SetTexture(1, 1, 1, 0.06)

    tracker.stacks = tracker:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    tracker.stacks:SetPoint("CENTER", tracker, "CENTER", 0, 0)
    tracker.stacks:SetTextColor(1, 1, 1)
    tracker.stacks:SetShadowOffset(1, -1)
    tracker.value = tracker:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tracker.value:SetPoint("BOTTOM", tracker, "TOP", 0, 2)
    tracker.value:SetTextColor(1, 1, 1)
    tracker.value:SetShadowOffset(1, -1)
    tracker.time = tracker:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tracker.time:SetPoint("TOP", tracker, "BOTTOM", 0, -2)
    tracker.time:SetTextColor(1, 1, 1)
    tracker.time:SetShadowOffset(1, -1)

    tracker:SetScript("OnDragStart", function()
        if DB.unlocked then
            this:StartMoving()
        end
    end)
    tracker:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        SavePosition(this)
    end)
    tracker:SetScript("OnEnter", function()
        if not DB.showTooltips then
            return
        end
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        if this.entry.kind == "aura" then
            GameTooltip:SetText(T("buff"))
            if DB.showIds and this.entry.spellId then
                GameTooltip:AddLine("ID " .. this.entry.spellId, 1, 1, 0.4)
            end
            local timeLeft = this.time:GetText()
            if timeLeft ~= "" then
                GameTooltip:AddLine(timeLeft, 1, 1, 1, 1)
            end
        else
            GameTooltip:SetText(StateName(this.entry.state))
            local description = StateDescription(this.entry.state)
            if description ~= "" then
                GameTooltip:AddLine(description, 1, 1, 1, 1)
            end
        end
        GameTooltip:Show()
    end)
    tracker:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    tracker:SetScript("OnMouseUp", function()
        if arg1 == "RightButton" and DB.unlocked then
            RemoveTracker(this)
        end
    end)

    table.insert(trackers, tracker)
    RefreshTracker(tracker)
    UpdateLock()
    return tracker
end

local function DefaultPosition()
    local width = UIParent:GetWidth() or 1024
    local height = UIParent:GetHeight() or 768
    local bottom = -height / 2 + 40
    local x = math.floor(width / 4)
    for column = 1, 4 do
        local y = 0
        while y >= bottom do
            local free = true
            for index = 1, getn(DB.trackers) do
                local entry = DB.trackers[index]
                if math.abs((entry.x or 0) - x) < 40 and math.abs((entry.y or 0) - y) < 40 then
                    free = false
                    break
                end
            end
            if free then
                return x, y
            end
            y = y - 60
        end
        x = x - 80
    end
    return math.floor(width / 4), 0
end

local function AddTracker(entry)
    for _, existing in ipairs(DB.trackers) do
        if existing.kind == entry.kind and existing.icon == entry.icon and existing.state == entry.state then
            return
        end
    end
    local x, y = DefaultPosition()
    local saved = {
        kind = entry.kind,
        icon = entry.icon,
        state = entry.state,
        spellId = entry.spellId,
        x = x,
        y = y,
    }
    table.insert(DB.trackers, saved)
    CreateTracker(saved)
    if SaveActivePage then
        SaveActivePage()
    end
end

local function AddById(id)
    local icon = IdIcon(id)
    if not icon then
        return false
    end
    AddTracker({ kind = "aura", icon = icon, spellId = id })
    return true
end

local function CycleInactive()
    if DB.inactive == "grey" then
        DB.inactive = "hide"
    else
        DB.inactive = "grey"
    end
    if SaveActivePage then
        SaveActivePage()
    end
    if config then
        BonkAuras:UpdateConfig()
    end
    for _, tracker in ipairs(trackers) do
        RefreshTracker(tracker)
    end
end

local function LanguageText()
    local label = T("follow")
    if DB.language == "zhCN" then
        label = "简体中文"
    elseif DB.language == "enUS" then
        label = "English"
    end
    return T("language") .. label
end

local function LanguageMenu()
    local options = {
        { value = "auto", text = T("follow") },
        { value = "zhCN", text = "简体中文" },
        { value = "enUS", text = "English" },
    }
    for _, option in ipairs(options) do
        local info = {}
        info.text = option.text
        info.value = option.value
        info.checked = DB.language == option.value
        info.func = function()
            BonkAuras:SetLanguage(this.value)
        end
        UIDropDownMenu_AddButton(info)
    end
end

function BonkAuras:SetLanguage(value)
    DB.language = value
    if SaveActivePage then
        SaveActivePage()
    end
    if config and config.languageDrop then
        UIDropDownMenu_Initialize(config.languageDrop, LanguageMenu)
        UIDropDownMenu_SetSelectedValue(config.languageDrop, value)
    end
    BonkAuras:UpdateConfig()
end

local function HookBuffTooltips()
    for index = 0, BUFF_BUTTONS - 1 do
        local buttonIndex = index
        local button = getglobal("BuffButton" .. buttonIndex)
        if button and not buffTooltipHooked[buttonIndex] then
            buffTooltipHooked[buttonIndex] = true
            local enter = button:GetScript("OnEnter")
            local leave = button:GetScript("OnLeave")
            button:SetScript("OnEnter", function()
                if enter then
                    enter()
                else
                    local position
                    if buttonIndex < 16 then
                        position = GetPlayerBuff(buttonIndex, "HELPFUL")
                    else
                        position = GetPlayerBuff(buttonIndex - 16, "HARMFUL")
                    end
                    if position and position >= 0 then
                        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                        GameTooltip:SetPlayerBuff(position)
                        GameTooltip:Show()
                    end
                end
                if DB.showIds then
                    local id = IconId(FrameIcon(this))
                    if id then
                        GameTooltip:AddLine("ID " .. id, 1, 1, 0.4)
                    end
                end
            end)
            if not leave then
                button:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)
            end
        end
    end
end

local function CharacterKey()
    local name = UnitName and UnitName("player") or nil
    if not name or name == "" then
        name = "player"
    end
    local realm = GetRealmName and GetRealmName() or ""
    return realm .. "\\" .. name
end

local function FindPage(id)
    if not id then
        return nil
    end
    for _, page in ipairs(DB.pages or {}) do
        if page.id == id then
            return page
        end
    end
end

local function PageAvailable(page, key)
    if not page then
        return false
    end
    return page.scope == "account" or (page.scope == "character" and page.owner == key)
end

local function AvailablePages(key)
    local list = {}
    for _, page in ipairs(DB.pages or {}) do
        if PageAvailable(page, key) then
            table.insert(list, page)
        end
    end
    return list
end

local function NextPageId()
    local id = DB.nextPageId or (getn(DB.pages or {}) + 1)
    DB.nextPageId = id + 1
    return "p" .. id
end

local function NewPage(name, scope)
    DB.activeCharacter = DB.activeCharacter or {}
    local key = CharacterKey()
    local page = {
        id = NextPageId(),
        name = name,
        scope = scope,
        owner = scope == "character" and key or nil,
        trackers = {},
        language = DB.language or "auto",
        inactive = DB.inactive or "grey",
        showIds = DB.showIds or false,
        showTooltips = DB.showTooltips ~= false,
        layoutVersion = 2,
    }
    table.insert(DB.pages, page)
    return page
end

local function LoadPage(page, key)
    DB.activePageId = page.id
    if page.scope == "account" then
        DB.activeAccount = page.id
        DB.activeCharacter[key] = nil
    else
        DB.activeCharacter[key] = page.id
    end
    DB.trackers = page.trackers or {}
    DB.language = page.language or "auto"
    DB.inactive = page.inactive or "grey"
    DB.showIds = page.showIds or false
    if page.showTooltips == nil then
        page.showTooltips = true
    end
    DB.showTooltips = page.showTooltips
    DB.layoutVersion = page.layoutVersion or DB.layoutVersion or 2
end

SaveActivePage = function()
    if not DB or not DB.pages then
        return
    end
    local page = FindPage(DB.activePageId)
    if not page then
        return
    end
    page.trackers = DB.trackers
    page.language = DB.language
    page.inactive = DB.inactive
    page.showIds = DB.showIds
    page.showTooltips = DB.showTooltips
    page.layoutVersion = DB.layoutVersion
end

local function MigratePages()
    if DB.pages then
        return
    end
    DB.pages = {}
    DB.activeCharacter = DB.activeCharacter or {}
    local page = {
        id = "p1",
        name = T("profile_default"),
        scope = "account",
        trackers = DB.trackers,
        language = DB.language,
        inactive = DB.inactive,
        showIds = DB.showIds,
        showTooltips = DB.showTooltips,
        layoutVersion = DB.layoutVersion or 2,
    }
    DB.pages[1] = page
    DB.nextPageId = 2
    DB.activeAccount = page.id
    DB.activePageId = page.id
end

local function ChoosePage()
    local key = CharacterKey()
    DB.activeCharacter = DB.activeCharacter or {}
    local page = FindPage(DB.activeCharacter[key])
    if PageAvailable(page, key) then
        return page
    end
    page = FindPage(DB.activeAccount)
    if page and page.scope == "account" then
        return page
    end
    for _, candidate in ipairs(DB.pages) do
        if candidate.scope == "account" then
            return candidate
        end
    end
    for _, candidate in ipairs(DB.pages) do
        if PageAvailable(candidate, key) then
            return candidate
        end
    end
    return NewPage(T("profile_default"), "account")
end

local function RebuildTrackers()
    for _, tracker in ipairs(trackers) do
        tracker:Hide()
    end
    trackers = {}
    for _, entry in ipairs(DB.trackers) do
        CreateTracker(entry)
    end
    UpdateLock()
    if DB.showIds then
        HookBuffTooltips()
    end
end

local function ActivatePage(page)
    if not page then
        return
    end
    SaveActivePage()
    LoadPage(page, CharacterKey())
    RebuildTrackers()
    if config then
        UIDropDownMenu_Initialize(config.languageDrop, LanguageMenu)
        BonkAuras:UpdateConfig()
    end
end

local function ActivePage()
    return FindPage(DB.activePageId)
end

function BonkAuras:ToggleShowIds()
    DB.showIds = not DB.showIds
    if SaveActivePage then
        SaveActivePage()
    end
    if DB.showIds then
        HookBuffTooltips()
    end
    BonkAuras:UpdateConfig()
end

function BonkAuras:ExportConfig()
    return EncodeConfig()
end

function BonkAuras:ImportConfig(text)
    local data = DecodeConfig(text)
    if not data then
        return false
    end
    for _, tracker in ipairs(trackers) do
        tracker:Hide()
    end
    trackers = {}
    DB.trackers = {}
    DB.inactive = data.inactive
    DB.showIds = data.showIds
    DB.showTooltips = data.showTooltips
    DB.unlocked = false
    DB.layoutVersion = 2
    for _, entry in ipairs(data.entries) do
        local saved = {
            kind = entry.kind,
            icon = entry.icon,
            state = entry.state,
            spellId = entry.spellId,
            x = entry.x,
            y = entry.y,
        }
        table.insert(DB.trackers, saved)
        CreateTracker(saved)
    end
    BonkAuras:SetLanguage(data.language)
    if DB.showIds then
        HookBuffTooltips()
    end
    UpdateLock()
    BonkAuras:UpdateConfig()
    if SaveActivePage then
        SaveActivePage()
    end
    return true, getn(data.entries)
end

function BonkAuras:AddIdFromBox()
    local text = config.idBox:GetText() or ""
    local id = tonumber(text)
    if id and AddById(id) then
        config.status:SetText(T("id_added") .. id)
        config.status:SetTextColor(0.4, 1, 0.4)
        config.idBox:SetText("")
    else
        config.status:SetText(T("id_bad") .. text)
        config.status:SetTextColor(1, 0.4, 0.4)
    end
    config.idBox:ClearFocus()
    BonkAuras:UpdateConfig()
end

local function SetupConfig()
    config = CreateFrame("Frame", "BonkAurasFrame", UIParent)
    config:SetWidth(760)
    config:SetHeight(560)
    config:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    config:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = 1, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    config:SetMovable(true)
    config:EnableMouse(true)
    config:RegisterForDrag("LeftButton")
    config:SetScript("OnDragStart", function() this:StartMoving() end)
    config:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    config:SetScript("OnHide", function()
        if SaveActivePage then
            SaveActivePage()
        end
    end)
    config:Hide()

    config.title = config:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    config.title:SetPoint("TOP", config, "TOP", 0, -16)

    config.close = CreateFrame("Button", nil, config, "UIPanelCloseButton")
    config.close:SetPoint("TOPRIGHT", config, "TOPRIGHT", -6, -6)

    config.unlock = CreateFrame("Button", nil, config, "UIPanelButtonTemplate")
    config.unlock:SetWidth(110)
    config.unlock:SetHeight(22)
    config.unlock:SetPoint("TOPLEFT", config, "TOPLEFT", 18, -42)
    config.unlock:SetScript("OnClick", function()
        DB.unlocked = not DB.unlocked
        UpdateLock()
        BonkAuras:UpdateConfig()
    end)

    config.clear = CreateFrame("Button", nil, config, "UIPanelButtonTemplate")
    config.clear:SetWidth(110)
    config.clear:SetHeight(22)
    config.clear:SetPoint("TOPLEFT", config, "TOPLEFT", 140, -42)
    config.clear:SetScript("OnClick", function()
        for _, tracker in ipairs(trackers) do
            tracker:Hide()
        end
        trackers = {}
        DB.trackers = {}
        if SaveActivePage then
            SaveActivePage()
        end
        BonkAuras:UpdateConfig()
    end)

    config.languageDrop = CreateFrame("Frame", "BonkAurasLanguageDropdown", config, "UIDropDownMenuTemplate")
    config.languageDrop:SetPoint("TOPRIGHT", config, "TOPRIGHT", -14, -38)
    UIDropDownMenu_SetWidth(150, config.languageDrop)
    UIDropDownMenu_Initialize(config.languageDrop, LanguageMenu)

    config.export = CreateFrame("Button", nil, config, "UIPanelButtonTemplate")
    config.export:SetWidth(90)
    config.export:SetHeight(22)
    config.export:SetPoint("TOPLEFT", config, "TOPLEFT", 262, -42)
    config.export:SetScript("OnClick", function()
        BonkAuras:OpenIO("export")
    end)

    config.import = CreateFrame("Button", nil, config, "UIPanelButtonTemplate")
    config.import:SetWidth(90)
    config.import:SetHeight(22)
    config.import:SetPoint("TOPLEFT", config, "TOPLEFT", 364, -42)
    config.import:SetScript("OnClick", function()
        BonkAuras:OpenIO("import")
    end)

    config.profiles = CreateFrame("Button", nil, config, "UIPanelButtonTemplate")
    config.profiles:SetWidth(80)
    config.profiles:SetHeight(22)
    config.profiles:SetPoint("TOPLEFT", config, "TOPLEFT", 466, -42)
    config.profiles:SetScript("OnClick", function()
        BonkAuras:OpenProfiles()
    end)

    config.showIds = CreateFrame("Button", nil, config, "UIPanelButtonTemplate")
    config.showIds:SetWidth(170)
    config.showIds:SetHeight(22)
    config.showIds:SetPoint("TOPLEFT", config, "TOPLEFT", 18, -70)
    config.showIds:SetScript("OnClick", function()
        BonkAuras:ToggleShowIds()
    end)

    config.tooltips = CreateFrame("Button", nil, config, "UIPanelButtonTemplate")
    config.tooltips:SetWidth(180)
    config.tooltips:SetHeight(22)
    config.tooltips:SetPoint("TOPLEFT", config, "TOPLEFT", 200, -70)
    config.tooltips:SetScript("OnClick", function()
        DB.showTooltips = not DB.showTooltips
        if not DB.showTooltips then
            GameTooltip:Hide()
        end
        if SaveActivePage then
            SaveActivePage()
        end
        BonkAuras:UpdateConfig()
    end)

    config.inactive = CreateFrame("Button", nil, config, "UIPanelButtonTemplate")
    config.inactive:SetWidth(150)
    config.inactive:SetHeight(22)
    config.inactive:SetPoint("TOPRIGHT", config, "TOPRIGHT", -18, -70)
    config.inactive:SetScript("OnClick", CycleInactive)

    config.manualLabel = config:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    config.manualLabel:SetPoint("TOPLEFT", config, "TOPLEFT", 18, -100)
    config.manualLabel:SetWidth(125)

    config.idBox = CreateFrame("EditBox", nil, config, "InputBoxTemplate")
    config.idBox:SetWidth(90)
    config.idBox:SetHeight(20)
    config.idBox:SetPoint("TOPLEFT", config, "TOPLEFT", 160, -96)
    config.idBox:SetAutoFocus(false)
    config.idBox:SetMaxLetters(9)
    config.idBox:SetScript("OnEnterPressed", function()
        BonkAuras:AddIdFromBox()
    end)
    config.idBox:SetScript("OnEscapePressed", function()
        this:ClearFocus()
    end)

    config.add = CreateFrame("Button", nil, config, "UIPanelButtonTemplate")
    config.add:SetWidth(60)
    config.add:SetHeight(22)
    config.add:SetPoint("TOPLEFT", config, "TOPLEFT", 260, -96)
    config.add:SetScript("OnClick", function()
        BonkAuras:AddIdFromBox()
    end)

    config.status = config:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    config.status:SetPoint("TOPLEFT", config, "TOPLEFT", 18, -128)
    config.status:SetWidth(724)
    config.status:SetJustifyH("LEFT")

    config.hint = config:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    config.hint:SetPoint("TOPLEFT", config, "TOPLEFT", 18, -150)
    config.hint:SetWidth(724)
    config.hint:SetJustifyH("LEFT")

    config.buffHeader = config:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    config.buffHeader:SetPoint("TOPLEFT", config, "TOPLEFT", 18, -198)

    config.trackedHeader = config:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    config.trackedHeader:SetPoint("TOPLEFT", config, "TOPLEFT", 398, -198)

    config.buffRows = {}
    for index = 1, 10 do
        local row = CreateFrame("Button", nil, config)
        row:SetWidth(360)
        row:SetHeight(26)
        row:SetPoint("TOPLEFT", config, "TOPLEFT", 18, -220 - (index - 1) * 27)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetWidth(22)
        row.icon:SetHeight(22)
        row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.label:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
        row.label:SetWidth(316)
        row.label:SetJustifyH("LEFT")
        row:SetScript("OnClick", function()
            if this.entry then
                AddTracker(this.entry)
            end
        end)
        row:Hide()
        table.insert(config.buffRows, row)
    end

    config.trackedRows = {}
    for index = 1, 10 do
        local row = CreateFrame("Button", nil, config)
        row:SetWidth(344)
        row:SetHeight(26)
        row:SetPoint("TOPLEFT", config, "TOPLEFT", 398, -220 - (index - 1) * 27)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetWidth(22)
        row.icon:SetHeight(22)
        row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.label:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
        row.label:SetWidth(300)
        row.label:SetJustifyH("LEFT")
        row:SetScript("OnMouseUp", function()
            if arg1 == "RightButton" and this.tracker then
                RemoveTracker(this.tracker)
            end
        end)
        row:SetScript("OnEnter", function()
            if this.tracker then
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                if this.tracker.entry.kind == "state" then
                    GameTooltip:SetText(StateName(this.tracker.entry.state))
                    local description = StateDescription(this.tracker.entry.state)
                    if description ~= "" then
                        GameTooltip:AddLine(description, 1, 1, 1, 1)
                    end
                else
                    GameTooltip:SetText(T("buff"))
                    if this.tracker.entry.spellId then
                        GameTooltip:AddLine("ID " .. this.tracker.entry.spellId, 1, 1, 0.4)
                    end
                end
                GameTooltip:AddLine(T("remove_hint"), 0.7, 0.7, 0.7)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        row:Hide()
        table.insert(config.trackedRows, row)
    end

    config.stateHeader = config:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    config.stateHeader:SetPoint("TOPLEFT", config, "TOPLEFT", 18, -496)

    config.stateRows = {}
    for index, def in ipairs(STATE_DEFS) do
        local key = def.key
        local icon = def.icon
        local row = CreateFrame("Button", nil, config)
        row:SetWidth(140)
        row:SetHeight(24)
        row:SetPoint("TOPLEFT", config, "TOPLEFT", 18 + (index - 1) * 146, -518)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetWidth(20)
        row.icon:SetHeight(20)
        row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.icon:SetTexture(icon)
        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.label:SetWidth(110)
        row:SetScript("OnClick", function()
            AddTracker({ kind = "state", state = key, icon = icon })
        end)
        table.insert(config.stateRows, row)
    end

    config:SetScript("OnUpdate", function()
        this.tick = (this.tick or 0) + arg1
        if this.tick >= 0.5 then
            this.tick = 0
            BonkAuras:UpdateConfig()
        end
    end)
end

local function CreateIOFrame()
    ioFrame = CreateFrame("Frame", "BonkAurasIOFrame", UIParent)
    ioFrame:SetWidth(560)
    ioFrame:SetHeight(360)
    ioFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    ioFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = 1, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    ioFrame:SetMovable(true)
    ioFrame:EnableMouse(true)
    ioFrame:SetClampedToScreen(true)
    ioFrame:SetFrameLevel(20)
    ioFrame:RegisterForDrag("LeftButton")
    ioFrame:SetScript("OnDragStart", function() this:StartMoving() end)
    ioFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    ioFrame:SetScript("OnHide", function()
        if this.box then
            this.box:ClearFocus()
        end
    end)
    ioFrame:Hide()

    ioFrame.title = ioFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ioFrame.title:SetPoint("TOP", ioFrame, "TOP", 0, -16)
    ioFrame.hint = ioFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ioFrame.hint:SetPoint("TOPLEFT", ioFrame, "TOPLEFT", 20, -44)
    ioFrame.hint:SetWidth(520)
    ioFrame.hint:SetJustifyH("LEFT")
    ioFrame.label = ioFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ioFrame.label:SetPoint("TOPLEFT", ioFrame, "TOPLEFT", 30, -82)

    ioFrame.boxBg = CreateFrame("Frame", nil, ioFrame)
    ioFrame.boxBg:SetPoint("TOPLEFT", ioFrame, "TOPLEFT", 24, -102)
    ioFrame.boxBg:SetWidth(512)
    ioFrame.boxBg:SetHeight(208)
    ioFrame.boxBg:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = 1, tileSize = 8, edgeSize = 10,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    ioFrame.boxBg:SetBackdropColor(0, 0, 0, 0.6)
    ioFrame.boxBg:SetBackdropBorderColor(0, 0, 0, 0.8)

    ioFrame.box = CreateFrame("EditBox", nil, ioFrame)
    ioFrame.box:SetMultiLine(true)
    ioFrame.box:SetAutoFocus(false)
    ioFrame.box:SetFontObject(ChatFontNormal)
    ioFrame.box:SetTextColor(1, 1, 1)
    ioFrame.box:SetWidth(500)
    ioFrame.box:SetHeight(198)
    ioFrame.box:SetPoint("TOPLEFT", ioFrame, "TOPLEFT", 30, -106)
    ioFrame.box:SetTextInsets(8, 8, 8, 8)
    ioFrame.box:SetMaxLetters(5000)
    ioFrame.box:SetScript("OnEscapePressed", function()
        this:ClearFocus()
    end)

    ioFrame.status = ioFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ioFrame.status:SetPoint("BOTTOMLEFT", ioFrame, "BOTTOMLEFT", 30, 24)
    ioFrame.status:SetWidth(400)
    ioFrame.status:SetJustifyH("LEFT")

    ioFrame.action = CreateFrame("Button", nil, ioFrame, "UIPanelButtonTemplate")
    ioFrame.action:SetWidth(120)
    ioFrame.action:SetHeight(22)
    ioFrame.action:SetPoint("BOTTOMRIGHT", ioFrame, "BOTTOMRIGHT", -24, 20)
    ioFrame.action:SetScript("OnClick", function()
        if ioFrame.mode == "export" then
            ioFrame.box:SetFocus()
            ioFrame.box:HighlightText()
        else
            local ok, count = BonkAuras:ImportConfig(ioFrame.box:GetText())
            if ok then
                config.status:SetText(T("import_ok") .. count)
                config.status:SetTextColor(0.4, 1, 0.4)
                BonkAuras:UpdateConfig()
                ioFrame:Hide()
            else
                ioFrame.status:SetText(T("import_bad"))
                ioFrame.status:SetTextColor(1, 0.4, 0.4)
            end
        end
    end)

    local close = CreateFrame("Button", nil, ioFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", ioFrame, "TOPRIGHT", -6, -6)
end

function BonkAuras:OpenIO(mode)
    if not ioFrame then
        CreateIOFrame()
    end
    ioFrame:SetScript("OnUpdate", nil)
    ioFrame.mode = mode
    ioFrame.status:SetText("")
    ioFrame.label:SetText(T("io_label"))
    if mode == "export" then
        ioFrame.title:SetText(T("export"))
        ioFrame.hint:SetText(T("io_export_hint"))
        ioFrame.box:SetText(BonkAuras:ExportConfig())
        ioFrame.action:SetText(T("copy_all"))
    else
        ioFrame.title:SetText(T("import"))
        ioFrame.hint:SetText(T("io_import_hint"))
        ioFrame.box:SetText("")
        ioFrame.action:SetText(T("import"))
    end
    ioFrame:Show()
    if ioFrame.Raise then
        ioFrame:Raise()
    end
    ioFrame.box:SetFocus()
    if mode == "export" then
        ioFrame.box:HighlightText()
        ioFrame.selectAll = true
        ioFrame:SetScript("OnUpdate", function()
            if this.selectAll then
                this.selectAll = false
                this.box:SetFocus()
                this.box:HighlightText()
                this:SetScript("OnUpdate", nil)
            end
        end)
    end
end

local function RefreshProfiles()
    if not profileFrame then
        return
    end
    profileFrame.title:SetText(T("profile_title"))
    profileFrame.hint:SetText(T("profile_hint"))
    profileFrame.nameLabel:SetText(T("profile_name"))
    profileFrame.new:SetText(T("profile_new"))
    profileFrame.save:SetText(T("profile_save"))
    profileFrame.rename:SetText(T("profile_rename"))
    profileFrame.delete:SetText(T("profile_delete"))
    profileFrame.scope:SetText(T("profile_toggle_scope"))
    local pages = AvailablePages(CharacterKey())
    for index, row in ipairs(profileFrame.rows) do
        local page = pages[index]
        if page then
            row.page = page
            row.name:SetText(page.name)
            row.scopeLabel:SetText(page.scope == "account" and T("profile_account") or T("profile_character"))
            if page.id == DB.activePageId then
                row.name:SetTextColor(0.4, 1, 0.4)
            else
                row.name:SetTextColor(1, 0.82, 0)
            end
            row:Show()
        else
            row.page = nil
            row:Hide()
        end
    end
    local active = ActivePage()
    if active then
        profileFrame.nameBox:SetText(active.name)
        profileFrame.scopeLabel:SetText(T("profile_scope") .. (active.scope == "account" and T("profile_account") or T("profile_character")))
    else
        profileFrame.scopeLabel:SetText("")
    end
end

local function NewProfileFromBox()
    local active = ActivePage()
    local name = profileFrame.nameBox:GetText() or ""
    if name == "" or (active and name == active.name) then
        name = T("profile_new_name") .. (getn(DB.pages) + 1)
    end
    local page = NewPage(name, active and active.scope or "account")
    ActivatePage(page)
    profileFrame.status:SetText("")
    RefreshProfiles()
end

local function RenameProfileFromBox()
    local active = ActivePage()
    local name = profileFrame.nameBox:GetText() or ""
    if not active then
        return
    end
    if name == "" then
        profileFrame.status:SetText(T("profile_name_empty"))
        profileFrame.status:SetTextColor(1, 0.4, 0.4)
        return
    end
    active.name = name
    SaveActivePage()
    BonkAuras:UpdateConfig()
    profileFrame.status:SetText("")
    RefreshProfiles()
end

local function SaveProfileFromBox()
    local active = ActivePage()
    if not active then
        return
    end
    local name = profileFrame.nameBox:GetText() or ""
    if name == "" then
        profileFrame.status:SetText(T("profile_name_empty"))
        profileFrame.status:SetTextColor(1, 0.4, 0.4)
        return
    end
    active.name = name
    SaveActivePage()
    BonkAuras:UpdateConfig()
    RefreshProfiles()
    profileFrame.status:SetText(T("profile_saved"))
    profileFrame.status:SetTextColor(0.4, 1, 0.4)
end

local function DeleteActiveProfile()
    local active = ActivePage()
    local key = CharacterKey()
    if not active then
        return
    end
    if getn(AvailablePages(key)) <= 1 then
        profileFrame.status:SetText(T("profile_keep"))
        profileFrame.status:SetTextColor(1, 0.4, 0.4)
        return
    end
    for index, page in ipairs(DB.pages) do
        if page == active then
            table.remove(DB.pages, index)
            break
        end
    end
    if DB.activeAccount == active.id then
        DB.activeAccount = nil
    end
    DB.activeCharacter = DB.activeCharacter or {}
    for owner, id in pairs(DB.activeCharacter) do
        if id == active.id then
            DB.activeCharacter[owner] = nil
        end
    end
    DB.activePageId = nil
    local page = ChoosePage()
    LoadPage(page, key)
    RebuildTrackers()
    if config then
        UIDropDownMenu_Initialize(config.languageDrop, LanguageMenu)
        BonkAuras:UpdateConfig()
    end
    profileFrame.status:SetText("")
    RefreshProfiles()
end

local function ToggleActiveProfileScope()
    local active = ActivePage()
    local key = CharacterKey()
    if not active then
        return
    end
    if active.scope == "account" then
        active.scope = "character"
        active.owner = key
        if DB.activeAccount == active.id then
            DB.activeAccount = nil
        end
        DB.activeCharacter[key] = active.id
    else
        active.scope = "account"
        active.owner = nil
        if DB.activeCharacter[key] == active.id then
            DB.activeCharacter[key] = nil
        end
        DB.activeAccount = active.id
    end
    DB.activePageId = active.id
    SaveActivePage()
    BonkAuras:UpdateConfig()
    profileFrame.status:SetText("")
    RefreshProfiles()
end

local function CreateProfileFrame()
    profileFrame = CreateFrame("Frame", "BonkAurasProfilesFrame", UIParent)
    profileFrame:SetWidth(560)
    profileFrame:SetHeight(470)
    profileFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    profileFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = 1, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    profileFrame:SetMovable(true)
    profileFrame:EnableMouse(true)
    profileFrame:SetClampedToScreen(true)
    profileFrame:SetFrameLevel(22)
    profileFrame:RegisterForDrag("LeftButton")
    profileFrame:SetScript("OnDragStart", function() this:StartMoving() end)
    profileFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    profileFrame:SetScript("OnHide", function()
        if this.nameBox then
            this.nameBox:ClearFocus()
        end
    end)
    profileFrame:Hide()

    profileFrame.title = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    profileFrame.title:SetPoint("TOP", profileFrame, "TOP", 0, -16)
    profileFrame.hint = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    profileFrame.hint:SetPoint("TOPLEFT", profileFrame, "TOPLEFT", 20, -44)
    profileFrame.hint:SetWidth(520)
    profileFrame.hint:SetJustifyH("LEFT")

    profileFrame.rows = {}
    for index = 1, 10 do
        local row = CreateFrame("Button", nil, profileFrame)
        row:SetWidth(520)
        row:SetHeight(26)
        row:SetPoint("TOPLEFT", profileFrame, "TOPLEFT", 20, -92 - (index - 1) * 27)
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.name:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.name:SetWidth(340)
        row.name:SetJustifyH("LEFT")
        row.scopeLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.scopeLabel:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row.scopeLabel:SetWidth(160)
        row.scopeLabel:SetJustifyH("RIGHT")
        row.scopeLabel:SetTextColor(0.7, 0.7, 0.7)
        row:SetScript("OnClick", function()
            if this.page then
                ActivatePage(this.page)
                profileFrame.status:SetText("")
                RefreshProfiles()
            end
        end)
        row:Hide()
        table.insert(profileFrame.rows, row)
    end

    profileFrame.nameLabel = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    profileFrame.nameLabel:SetPoint("TOPLEFT", profileFrame, "TOPLEFT", 20, -382)
    profileFrame.nameBox = CreateFrame("EditBox", nil, profileFrame, "InputBoxTemplate")
    profileFrame.nameBox:SetWidth(130)
    profileFrame.nameBox:SetHeight(20)
    profileFrame.nameBox:SetPoint("TOPLEFT", profileFrame, "TOPLEFT", 80, -378)
    profileFrame.nameBox:SetAutoFocus(false)
    profileFrame.nameBox:SetMaxLetters(24)
    profileFrame.nameBox:SetScript("OnEnterPressed", function()
        SaveProfileFromBox()
    end)
    profileFrame.nameBox:SetScript("OnEscapePressed", function()
        this:ClearFocus()
    end)

    profileFrame.new = CreateFrame("Button", nil, profileFrame, "UIPanelButtonTemplate")
    profileFrame.new:SetWidth(70)
    profileFrame.new:SetHeight(22)
    profileFrame.new:SetPoint("TOPLEFT", profileFrame, "TOPLEFT", 220, -378)
    profileFrame.new:SetScript("OnClick", NewProfileFromBox)

    profileFrame.save = CreateFrame("Button", nil, profileFrame, "UIPanelButtonTemplate")
    profileFrame.save:SetWidth(70)
    profileFrame.save:SetHeight(22)
    profileFrame.save:SetPoint("TOPLEFT", profileFrame, "TOPLEFT", 300, -378)
    profileFrame.save:SetScript("OnClick", SaveProfileFromBox)

    profileFrame.rename = CreateFrame("Button", nil, profileFrame, "UIPanelButtonTemplate")
    profileFrame.rename:SetWidth(70)
    profileFrame.rename:SetHeight(22)
    profileFrame.rename:SetPoint("TOPLEFT", profileFrame, "TOPLEFT", 380, -378)
    profileFrame.rename:SetScript("OnClick", RenameProfileFromBox)

    profileFrame.delete = CreateFrame("Button", nil, profileFrame, "UIPanelButtonTemplate")
    profileFrame.delete:SetWidth(70)
    profileFrame.delete:SetHeight(22)
    profileFrame.delete:SetPoint("TOPLEFT", profileFrame, "TOPLEFT", 460, -378)
    profileFrame.delete:SetScript("OnClick", DeleteActiveProfile)

    profileFrame.scope = CreateFrame("Button", nil, profileFrame, "UIPanelButtonTemplate")
    profileFrame.scope:SetWidth(150)
    profileFrame.scope:SetHeight(22)
    profileFrame.scope:SetPoint("TOPLEFT", profileFrame, "TOPLEFT", 20, -408)
    profileFrame.scope:SetScript("OnClick", ToggleActiveProfileScope)

    profileFrame.scopeLabel = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    profileFrame.scopeLabel:SetPoint("TOPLEFT", profileFrame, "TOPLEFT", 180, -404)
    profileFrame.scopeLabel:SetWidth(340)
    profileFrame.scopeLabel:SetJustifyH("LEFT")

    profileFrame.status = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    profileFrame.status:SetPoint("TOPLEFT", profileFrame, "TOPLEFT", 20, -438)
    profileFrame.status:SetWidth(520)
    profileFrame.status:SetJustifyH("LEFT")

    local close = CreateFrame("Button", nil, profileFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", profileFrame, "TOPRIGHT", -6, -6)
end

function BonkAuras:OpenProfiles()
    if not profileFrame then
        CreateProfileFrame()
    end
    RefreshProfiles()
    profileFrame.status:SetText("")
    profileFrame:Show()
    if profileFrame.Raise then
        profileFrame:Raise()
    end
end

function BonkAuras:UpdateConfig()
    if not config then
        return
    end
    local page = ActivePage()
    local pageName = page and page.name or T("profile_default")
    if not pageName or pageName == "" then
        pageName = T("profile_default")
    end
    config.title:SetText("BonkAuras  ·  " .. string.sub(pageName, 1, 24) .. "  ·  /wa")
    config.unlock:SetText(DB.unlocked and T("lock") or T("unlock"))
    config.clear:SetText(T("clear"))
    config.export:SetText(T("export"))
    config.import:SetText(T("import"))
    config.profiles:SetText(T("profiles"))
    config.hint:SetText(T("hint"))
    config.buffHeader:SetText(T("buffs"))
    config.trackedHeader:SetText(T("tracked") .. getn(trackers))
    config.stateHeader:SetText(T("states"))
    config.showIds:SetText(T("show_ids") .. (DB.showIds and T("on") or T("off")))
    config.tooltips:SetText(T("tooltips") .. (DB.showTooltips and T("on") or T("off")))
    config.inactive:SetText(DB.inactive == "hide" and T("hide") or T("grey"))
    config.manualLabel:SetText(T("manual"))
    config.add:SetText(T("add"))
    UIDropDownMenu_SetSelectedValue(config.languageDrop, DB.language)
    UIDropDownMenu_SetText(LanguageText(), config.languageDrop)

    local buffs = PlayerBuffs()
    for index, row in ipairs(config.buffRows) do
        local buff = buffs[index]
        if buff then
            row.entry = { kind = "aura", icon = buff.icon, spellId = buff.id }
            row.icon:SetTexture(buff.icon)
            local text = T("buff") .. index
            if buff.stacks > 1 then
                text = text .. "  x" .. buff.stacks
            end
            if buff.left > 0 then
                text = text .. "  " .. FormatTime(buff.left)
            end
            if DB.showIds then
                text = text .. "  [" .. (buff.id or "?") .. "]"
            end
            row.label:SetText(text)
            row:Show()
        else
            row.entry = nil
            row:Hide()
        end
    end

    for index, row in ipairs(config.trackedRows) do
        local tracker = trackers[index]
        if tracker then
            row.tracker = tracker
            row.icon:SetTexture(tracker.entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            local label
            if tracker.entry.kind == "state" then
                label = StateName(tracker.entry.state)
            elseif tracker.entry.spellId then
                label = "ID " .. tracker.entry.spellId
            else
                label = T("buff")
            end
            row.label:SetText(label)
            row:Show()
        else
            row.tracker = nil
            row:Hide()
        end
    end

    for index, row in ipairs(config.stateRows) do
        row.label:SetText(StateName(STATE_DEFS[index].key))
    end
end

function BonkAuras:Open()
    if not config then
        SetupConfig()
    end
    if config:IsShown() then
        config:Hide()
    else
        config:Show()
        BonkAuras:UpdateConfig()
        if DB.showIds then
            HookBuffTooltips()
        end
        UpdateLock()
    end
end

function BonkAuras:ToggleUnlock(unlocked)
    if unlocked ~= nil then
        DB.unlocked = unlocked
    else
        DB.unlocked = not DB.unlocked
    end
    UpdateLock()
    BonkAuras:UpdateConfig()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("CHAT_MSG_SYSTEM")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" then
        if arg1 ~= "BonkAuras" then
            return
        end
        local fresh = BonkAurasDB == nil or (BonkAurasDB.pages == nil and BonkAurasDB.language == nil and BonkAurasDB.trackers == nil)
        BonkAurasDB = BonkAurasDB or {}
        DB = BonkAurasDB
        DB.trackers = DB.trackers or {}
        DB.unlocked = DB.unlocked or false
        DB.language = DB.language or "auto"
        DB.inactive = DB.inactive or "grey"
        DB.showIds = DB.showIds or false
        if DB.showTooltips == nil then
            DB.showTooltips = true
        end
        if (DB.layoutVersion or 1) < 2 then
            for index, entry in ipairs(DB.trackers) do
                entry.x = 0
                entry.y = -120 - (index - 1) * 60
            end
            DB.layoutVersion = 2
        end
        if fresh then
            local data = DecodeConfig(DEFAULT_CONFIG)
            if data then
                DB.trackers = data.entries
                DB.language = data.language
                DB.inactive = data.inactive
                DB.showIds = data.showIds
                DB.showTooltips = data.showTooltips
                DB.layoutVersion = 2
            end
        end
        MigratePages()
        DB.activeCharacter = DB.activeCharacter or {}
        local page = ChoosePage()
        LoadPage(page, CharacterKey())
        trackers = {}
        for _, entry in ipairs(DB.trackers) do
            CreateTracker(entry)
        end
        SetupConfig()
        if DB.showIds then
            HookBuffTooltips()
        end
        UpdateLock()
        BonkAuras:StartTicker()
        return
    end
    if event == "PLAYER_LOGOUT" then
        if SaveActivePage then
            SaveActivePage()
        end
        return
    end
    if event == "CHAT_MSG_SYSTEM" and arg1 and string.sub(arg1, 1, 5) == "BONK~" then
        local fields = Split(arg1, "~")
        local kind = fields[2]
        if kind == "shield" then
            stateValues.shield.value = tonumber(fields[3]) or 0
            stateValues.shield.max = tonumber(fields[4]) or 0
        elseif kind == "dash" then
            stateValues.dash.charges = tonumber(fields[3]) or 0
            stateValues.dash.max = tonumber(fields[4]) or 0
            stateValues.dash.cooldown = (tonumber(fields[6]) or 0) / 1000
            local untilNext = tonumber(fields[5]) or 0
            if stateValues.dash.charges < stateValues.dash.max and untilNext > 0 then
                stateValues.dash.left = untilNext / 1000
            else
                stateValues.dash.left = 0
            end
        elseif kind == "determination" then
            stateValues.determination.stacks = tonumber(fields[3]) or 0
            stateValues.determination.percent = fields[4] or "0"
        elseif kind == "necrotic" then
            stateValues.necrotic.stacks = tonumber(fields[3]) or 0
            stateValues.necrotic.percent = fields[4] or "0"
        elseif kind == "wounds" then
            stateValues.wounds.stacks = tonumber(fields[3]) or 0
            stateValues.wounds.percent = fields[4] or "0"
        end
    end
end)

function BonkAuras:StartTicker()
    if ticker then
        return
    end
    ticker = CreateFrame("Frame")
    ticker:SetScript("OnUpdate", function()
        this.tick = (this.tick or 0) + arg1
        if this.tick >= 0.1 then
            local elapsed = this.tick
            this.tick = 0
            if stateValues.dash.left > 0 then
                stateValues.dash.left = stateValues.dash.left - elapsed
                if stateValues.dash.left <= 0 then
                    if stateValues.dash.charges < stateValues.dash.max and stateValues.dash.cooldown > 0 then
                        stateValues.dash.left = stateValues.dash.cooldown
                    else
                        stateValues.dash.left = 0
                    end
                end
            end
            local buffs = PlayerBuffs()
            for _, tracker in ipairs(trackers) do
                RefreshTracker(tracker, buffs)
            end
        end
    end)
end

SLASH_BONKAURAS1 = "/wa"
SlashCmdList["BONKAURAS"] = function(message)
    message = string.lower(message or "")
    if message == "unlock" then
        BonkAuras:ToggleUnlock(true)
        if not config:IsShown() then
            config:Show()
            BonkAuras:UpdateConfig()
        end
    elseif message == "lock" then
        BonkAuras:ToggleUnlock(false)
    elseif message == "reset" then
        for _, tracker in ipairs(trackers) do
            tracker:Hide()
        end
        trackers = {}
        DB.trackers = {}
    elseif message == "lang" then
        BonkAuras:SetLanguage(DB.language == "auto" and "zhCN" or (DB.language == "zhCN" and "enUS" or "auto"))
    elseif string.sub(message, 1, 4) == "add " then
        local id = tonumber(string.sub(message, 5))
        if id then
            AddById(id)
        end
    else
        BonkAuras:Open()
    end
end

function BonkAuras:AddSpellId(id)
    return AddById(tonumber(id) or 0)
end

function BonkAuras:SetStateValue(key, value, extra)
    if key == "shield" then
        stateValues.shield.value = tonumber(value) or 0
        stateValues.shield.max = tonumber(extra) or 0
    elseif key == "dash" then
        stateValues.dash.charges = tonumber(value) or 0
        stateValues.dash.max = tonumber(extra) or 0
        stateValues.dash.left = 5
        stateValues.dash.cooldown = 5
    elseif key == "determination" then
        stateValues.determination.stacks = tonumber(value) or 0
    elseif key == "necrotic" then
        stateValues.necrotic.stacks = tonumber(value) or 0
    elseif key == "wounds" then
        stateValues.wounds.stacks = tonumber(value) or 0
    end
    return true
end

function BonkAuras:AddState(key)
    for _, def in ipairs(STATE_DEFS) do
        if def.key == key then
            AddTracker({ kind = "state", state = def.key, icon = def.icon })
            return true
        end
    end
    return false
end

function BonkAuras:AddAuraByIndex(index)
    local buffs = PlayerBuffs()
    local buff = buffs[index]
    if buff then
        AddTracker({ kind = "aura", icon = buff.icon, spellId = buff.id })
        return true
    end
    return false
end
