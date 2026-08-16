local ADDON = "AshamaneGMPanel"

AshamaneGMPanelDB = AshamaneGMPanelDB or {}
AshamaneGMPanelDB.favorites = AshamaneGMPanelDB.favorites or {}

local categories = {
    {
        name = "Player",
        entries = {
            { id = "kill", label = "Kill selected target", command = ".die", target = true },
            { id = "revive", label = "Revive selected target", command = ".revive", target = true },
            { id = "summon", label = "Summon by name", template = ".summon %s", prompt = "Player name" },
            { id = "appear", label = "Appear at player", template = ".appear %s", prompt = "Player name" },
            { id = "sethp", label = "Set HP", template = ".modify hp %s", prompt = "HP value", target = true },
        },
    },
    {
        name = "Moderation",
        entries = {
            { id = "freeze", label = "Freeze selected target", command = ".freeze", target = true },
            { id = "unfreeze", label = "Unfreeze selected target", command = ".unfreeze", target = true },
            { id = "kick", label = "Kick selected target", command = ".kick", target = true },
        },
    },
    {
        name = "Movement",
        entries = {
            { id = "flyon", label = "GM fly on", command = ".gm fly on" },
            { id = "flyoff", label = "GM fly off", command = ".gm fly off" },
            { id = "tele", label = "Teleport to location", template = ".tele %s", prompt = "Location name" },
        },
    },
    {
        name = "Spells",
        entries = {
            { id = "cast", label = "Cast spell on target", template = ".cast %s triggered", prompt = "Spell ID", target = true },
            { id = "aura", label = "Apply aura to target", template = ".aura %s", prompt = "Spell ID", target = true },
            { id = "unaura", label = "Remove aura from target", template = ".unaura %s", prompt = "Spell ID", target = true },
            { id = "listauras", label = "List target auras", command = ".list auras", target = true },
        },
    },
    {
        name = "NPC",
        entries = {
            { id = "spawnnpc", label = "Spawn NPC", template = ".npc add %s", prompt = "Creature entry ID" },
            { id = "deletenpc", label = "Delete selected NPC", command = ".npc delete", target = true },
            { id = "npcinfo", label = "NPC information", command = ".npc info", target = true },
        },
    },
    {
        name = "Server",
        entries = {
            { id = "saveall", label = "Save all", command = ".saveall" },
            { id = "announce", label = "Announce", template = ".announce %s", prompt = "Announcement" },
            { id = "serverinfo", label = "Server info", command = ".server info" },
        },
    },
}

local function GetAllEntries()
    local allEntries = {}

    for _, category in ipairs(categories) do
        for _, entry in ipairs(category.entries) do
            table.insert(allEntries, entry)
        end
    end

    return allEntries
end

local function GetFavoriteEntries()
    local result = {}

    for _, entry in ipairs(GetAllEntries()) do
        if favorites[entry.id] then
            table.insert(result, entry)
        end
    end

    return result
end

local function PlaceCommand(command)
    if command and command ~= "" then
        ChatFrame_OpenChat(command)
    end
end

local panel = CreateFrame("Frame", ADDON .. "Frame", UIParent)
panel:SetSize(580, 510)
panel:SetPoint("CENTER")
panel:SetMovable(true)
panel:EnableMouse(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:SetClampedToScreen(true)
panel:SetFrameStrata("DIALOG")
panel:Hide()

local background = panel:CreateTexture(nil, "BACKGROUND")
background:SetAllPoints()
background:SetColorTexture(0.05, 0.05, 0.05, 0.94)

local topBorder = panel:CreateTexture(nil, "BORDER")
topBorder:SetHeight(2)
topBorder:SetPoint("TOPLEFT")
topBorder:SetPoint("TOPRIGHT")
topBorder:SetColorTexture(0.7, 0.55, 0.15, 1)

local bottomBorder = panel:CreateTexture(nil, "BORDER")
bottomBorder:SetHeight(2)
bottomBorder:SetPoint("BOTTOMLEFT")
bottomBorder:SetPoint("BOTTOMRIGHT")
bottomBorder:SetColorTexture(0.7, 0.55, 0.15, 1)

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -18)
title:SetText("Ashamane GM Panel")

local helpText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
helpText:SetPoint("TOP", title, "BOTTOM", 0, -5)
helpText:SetText("Commands are placed in chat. Review them, then press Enter.")

local authorText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
authorText:SetPoint("TOP", helpText, "BOTTOM", 0, -3)
authorText:SetText("Created by Arthriticgamer and Perplexity")

local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -5, -5)

local targetText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
targetText:SetPoint("TOPLEFT", 22, -76)
targetText:SetWidth(270)
targetText:SetJustifyH("LEFT")
targetText:SetWordWrap(false)

local filterBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
filterBox:SetSize(245, 24)
filterBox:SetPoint("TOPRIGHT", -28, -70)
filterBox:SetAutoFocus(false)

local filterLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
filterLabel:SetPoint("RIGHT", filterBox, "LEFT", -8, 0)
filterLabel:SetText("Filter:")

local content = CreateFrame("Frame", nil, panel)
content:SetPoint("TOPLEFT", 145, -148)
content:SetPoint("BOTTOMRIGHT", -22, 22)

local categoryButtons = {}
local commandButtons = {}
local favoriteButtons = {}
local selectedCategory = 1

local function UpdateTargetText()
    if UnitExists("target") then
        targetText:SetText("Target: |cff00ff00" .. UnitName("target") .. "|r")
    else
        targetText:SetText("Target: |cffff6666None|r")
    end
end

local function HideButtons(buttons)
    for _, button in ipairs(buttons) do
        button:Hide()
    end
end

local function GetEntriesForCategory(categoryIndex)
    if categoryIndex == 1 then
        return GetFavoriteEntries()
    end

    return categories[categoryIndex - 1].entries
end

local function ShowCategory(categoryIndex)
    selectedCategory = categoryIndex
    HideButtons(commandButtons)
    HideButtons(favoriteButtons)

    local filter = string.lower(filterBox:GetText() or "")
    local row = 0
    local shown = 0
    local entries = GetEntriesForCategory(categoryIndex)

    for _, entry in ipairs(entries) do
        local searchable = string.lower(
            entry.label .. " " .. (entry.command or "") .. " " .. (entry.template or "")
        )

        if filter == "" or string.find(searchable, filter, 1, true) then
            shown = shown + 1

            local commandButton = commandButtons[shown]

            if not commandButton then
                commandButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
                commandButton:SetSize(340, 28)
                commandButtons[shown] = commandButton
            end

            commandButton:ClearAllPoints()
            commandButton:SetPoint("TOPLEFT", 0, -row)
            commandButton:SetText(entry.label .. (entry.target and " [Target]" or ""))

            commandButton:SetScript("OnClick", function()
                if entry.template then
                    StaticPopup_Show("ASHAMANE_GM_INPUT", entry.label, nil, entry)
                else
                    PlaceCommand(entry.command)
                end
            end)

            commandButton:Show()

            local favoriteButton = favoriteButtons[shown]

            if not favoriteButton then
                favoriteButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
                favoriteButton:SetSize(38, 28)
                favoriteButtons[shown] = favoriteButton
            end

            favoriteButton:ClearAllPoints()
            favoriteButton:SetPoint("LEFT", commandButton, "RIGHT", 7, 0)
            favoriteButton:SetText(favorites[entry.id] and "★" or "☆")

            favoriteButton:SetScript("OnClick", function()
                favorites[entry.id] = not favorites[entry.id]

                if favorites[entry.id] then
                    favoriteButton:SetText("★")
                else
                    favoriteButton:SetText("☆")
                end

                if selectedCategory == 1 then
                    ShowCategory(1)
                end
            end)

            favoriteButton:Show()
            row = row + 32
        end
    end

    if shown == 0 then
        local message = commandButtons[1]

        if not message then
            message = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
            message:SetSize(385, 28)
            commandButtons[1] = message
        end

        message:ClearAllPoints()
        message:SetPoint("TOPLEFT", 0, 0)

        if categoryIndex == 1 then
            message:SetText("No favorites yet — use ☆ beside a command to add one.")
        else
            message:SetText("No matching commands")
        end

        message:SetScript("OnClick", nil)
        message:Show()
    end

    for index, button in ipairs(categoryButtons) do
        if index == selectedCategory then
            button:LockHighlight()
        else
            button:UnlockHighlight()
        end
    end
end

local sidebarCategories = {
    { name = "Favorites" },
    { name = "Player" },
    { name = "Moderation" },
    { name = "Movement" },
    { name = "Spells" },
    { name = "NPC" },
    { name = "Server" },
}

for index, category in ipairs(sidebarCategories) do
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetSize(112, 30)
    button:SetPoint("TOPLEFT", 22, -148 - ((index - 1) * 34))
    button:SetText(category.name)

    button:SetScript("OnClick", function()
        ShowCategory(index)
    end)

    categoryButtons[index] = button
end

StaticPopupDialogs["ASHAMANE_GM_INPUT"] = {
    text = "%s",
    button1 = "Place in Chat",
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = 255,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,

    OnShow = function(popup, entry)
        popup.text:SetText(entry.label)
        popup.editBox:SetText("")
        popup.editBox:SetFocus()
    end,

    OnAccept = function(popup, entry)
        local value = popup.editBox:GetText()

        if value and value ~= "" then
            PlaceCommand(string.format(entry.template, value))
        end
    end,

    EditBoxOnEnterPressed = function(editBox)
        local popup = editBox:GetParent()
        local entry = popup.data
        local value = editBox:GetText()

        if entry and value and value ~= "" then
            PlaceCommand(string.format(entry.template, value))
        end

        popup:Hide()
    end,
}

filterBox:SetScript("OnTextChanged", function()
    ShowCategory(selectedCategory)
end)

panel:SetScript("OnShow", function()
    UpdateTargetText()
    ShowCategory(selectedCategory)
end)

panel:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed

    if self.elapsed >= 0.5 then
        UpdateTargetText()
        self.elapsed = 0
    end
end)

SLASH_ASHAMANEGMPANEL1 = "/gmpanel"
SLASH_ASHAMANEGMPANEL2 = "/agm"

SlashCmdList["ASHAMANEGMPANEL"] = function()
    if panel:IsShown() then
        panel:Hide()
    else
        panel:Show()
    end
end

print("|cff33ff99Ashamane GM Panel|r loaded. Type /gmpanel to open it.")
