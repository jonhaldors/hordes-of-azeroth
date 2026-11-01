local L = VanillaBonkL
local UI = VanillaBonkUI

local STAT_NAMES = {
    [0] = L["Power"],
    [1] = L["Haste"],
    [4] = L["Maximum health"],
    [11] = L["Duration"],
    [15] = L["Critical strike chance"],
    [16] = L["Critical strike damage"],
}
local NO_TITLE = L["No title"]

local titles = { active = 0, list = {} }

local function Shown(title)
    return string.gsub(title.pattern, "%%s", UnitName("player") or "")
end

local function Label(title)
    local shown = Shown(title)
    if title.value > 0 and STAT_NAMES[title.stat] then
        return shown .. " |cff20ff20(+" .. title.value .. "% " .. STAT_NAMES[title.stat] .. ")|r"
    end
    return shown
end

local function FindTitle(id)
    for _, title in ipairs(titles.list) do
        if title.id == id then
            return title
        end
    end
end

local dropdown = CreateFrame("Frame", "VanillaBonkTitleDropdown", PaperDollFrame, "UIDropDownMenuTemplate")
dropdown:SetPoint("TOP", CharacterLevelText, "BOTTOM", 0, 2)
UIDropDownMenu_SetWidth(150, dropdown)
dropdown:Hide()

local function ShowName()
    local active = FindTitle(titles.active)
    CharacterNameText:SetText(active and Shown(active) or (UnitName("player") or ""))
    UIDropDownMenu_SetSelectedValue(dropdown, titles.active)
    UIDropDownMenu_SetText(active and Shown(active) or NO_TITLE, dropdown)
end

UIDropDownMenu_Initialize(dropdown, function()
    local none = {}
    none.text = NO_TITLE
    none.value = 0
    none.checked = titles.active == 0
    none.func = function()
        SendChatMessage(".bonk title 0", "SAY")
    end
    UIDropDownMenu_AddButton(none)
    for _, title in ipairs(titles.list) do
        local info = {}
        info.text = Label(title)
        info.value = title.id
        info.checked = titles.active == title.id
        info.func = function()
            SendChatMessage(".bonk title " .. this.value, "SAY")
        end
        UIDropDownMenu_AddButton(info)
    end
end)

local handlers = {}

handlers["titles"] = function(f)
    titles.active = tonumber(f[2] or "") or 0
    titles.list = {}
    local index = 3
    while f[index] and f[index + 1] do
        tinsert(titles.list, {
            id = tonumber(f[index]) or 0,
            pattern = f[index + 1],
            stat = tonumber(f[index + 2] or "") or 0,
            value = floor((tonumber(f[index + 3] or "") or 0) * 10 + 0.5) / 10,
        })
        index = index + 4
    end
    if getn(titles.list) > 0 then
        dropdown:Show()
    else
        dropdown:Hide()
    end
    ShowName()
end
UI.Listen(handlers)

local paperDollOnShow = PaperDollFrame:GetScript("OnShow")
PaperDollFrame:SetScript("OnShow", function()
    if paperDollOnShow then
        paperDollOnShow()
    end
    ShowName()
    SendChatMessage(".bonk title", "SAY")
end)
