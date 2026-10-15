-- EscReload
-- Adds a "Reload UI" button to the ESC game menu, right above "Log Out".

---------------------------------------------------------------------------
-- Localization (enUS is the default)
---------------------------------------------------------------------------
local LOCALES = {
    enUS = {
        RELOAD_UI = "Reload UI",
        DEBUG_HEADER = "debug (open the ESC menu first):",
        NO_INFO = "no information yet",
        LOGOUT_FOUND = "Log Out button found: ",
        USAGE = "use /escreload debug",
    },
    ptBR = {
        RELOAD_UI = "Recarregar UI",
        DEBUG_HEADER = "debug (abra o menu ESC antes):",
        NO_INFO = "nenhuma informação ainda",
        LOGOUT_FOUND = "Desconectar encontrado: ",
        USAGE = "use /escreload debug",
    },
}

local L = LOCALES[GetLocale()] or LOCALES.enUS
setmetatable(L, { __index = LOCALES.enUS })

local BUTTON_TEXT = L.RELOAD_UI
local debugLines = {}

local function OnReloadClick()
    ReloadUI()
end

---------------------------------------------------------------------------
-- Modern menu (Retail / Forever): GameMenuFrame with buttonPool
---------------------------------------------------------------------------
local function GetSortedButtons(menu)
    local list = {}
    for button in menu.buttonPool:EnumerateActive() do
        list[#list + 1] = button
    end
    table.sort(list, function(a, b)
        return (tonumber(a.layoutIndex) or 0) < (tonumber(b.layoutIndex) or 0)
    end)
    return list
end

local function IsLogoutText(text)
    if not text then return false end
    return text == GAMEMENU_LOGOUT
        or text == LOGOUT
        or text == "Desconectar"
        or text == "Log Out"
end

local function FindLogoutButton(buttons, reloadButton)
    -- 1) by text
    for _, button in ipairs(buttons) do
        if button ~= reloadButton and IsLogoutText(button:GetText()) then
            return button
        end
    end

    -- 2) fallback by position (ignoring our button):
    --    ... Log Out, Quit, Return to Game
    local others = {}
    for _, button in ipairs(buttons) do
        if button ~= reloadButton then
            others[#others + 1] = button
        end
    end
    return others[#others - 2]
end

local function AddReloadButtonModern(menu)
    if not (menu.AddButton and menu.buttonPool and menu.Layout) then
        return
    end

    local reloadButton = menu:AddButton(BUTTON_TEXT, OnReloadClick)
    local buttons = GetSortedButtons(menu)

    if type(reloadButton) ~= "table" then
        for _, button in ipairs(buttons) do
            if button:GetText() == BUTTON_TEXT then
                reloadButton = button
            end
        end
    end

    local logoutButton = FindLogoutButton(buttons, reloadButton)

    wipe(debugLines)
    for _, button in ipairs(buttons) do
        debugLines[#debugLines + 1] = string.format("[%s] %s",
            tostring(button.layoutIndex), tostring(button:GetText()))
    end
    debugLines[#debugLines + 1] = L.LOGOUT_FOUND ..
        tostring(logoutButton and logoutButton:GetText())

    local logoutIndex = logoutButton and tonumber(logoutButton.layoutIndex)
    if reloadButton and logoutIndex then
        reloadButton.layoutIndex = logoutIndex - 0.5
    end

    menu:Layout()
end

---------------------------------------------------------------------------
-- Legacy menu (Classic clients): fixed buttons such as GameMenuButtonLogout
-- NOTE: untested, needs validation on each Classic client.
---------------------------------------------------------------------------
local legacyButton

local function AddReloadButtonLegacy()
    local logout = GameMenuButtonLogout
    if not logout then return end

    if not legacyButton then
        legacyButton = CreateFrame("Button", "EscReloadButton", GameMenuFrame, "GameMenuButtonTemplate")
        legacyButton:SetText(BUTTON_TEXT)
        legacyButton:SetScript("OnClick", function()
            HideUIPanel(GameMenuFrame)
            ReloadUI()
        end)
    end

    -- Take the spot Log Out currently occupies and push Log Out below us
    local point, relativeTo, relativePoint, x, y = logout:GetPoint(1)
    if relativeTo == legacyButton then return end -- already arranged

    legacyButton:ClearAllPoints()
    legacyButton:SetPoint(point, relativeTo, relativePoint, x, y)
    logout:ClearAllPoints()
    logout:SetPoint("TOP", legacyButton, "BOTTOM", 0, -1)
    GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + legacyButton:GetHeight() + 1)
end

---------------------------------------------------------------------------
-- Hook the correct menu implementation for the current client
---------------------------------------------------------------------------
if GameMenuFrame and type(GameMenuFrame.InitButtons) == "function" then
    hooksecurefunc(GameMenuFrame, "InitButtons", AddReloadButtonModern)
elseif type(GameMenuFrame_UpdateVisibleButtons) == "function" then
    hooksecurefunc("GameMenuFrame_UpdateVisibleButtons", AddReloadButtonLegacy)
end

---------------------------------------------------------------------------
-- /rl  (/reload is already built into the game)
---------------------------------------------------------------------------
SLASH_ESCRELOADRL1 = "/rl"
SlashCmdList["ESCRELOADRL"] = function()
    ReloadUI()
end

---------------------------------------------------------------------------
-- /escreload debug
---------------------------------------------------------------------------
SLASH_ESCRELOAD1 = "/escreload"
SlashCmdList["ESCRELOAD"] = function(msg)
    if msg == "debug" then
        print("|cff33ff99EscReload|r " .. L.DEBUG_HEADER)
        if #debugLines == 0 then
            print("  " .. L.NO_INFO)
        end
        for _, line in ipairs(debugLines) do
            print("  " .. line)
        end
    else
        print("|cff33ff99EscReload|r: " .. L.USAGE)
    end
end