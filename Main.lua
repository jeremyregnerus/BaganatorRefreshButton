-- Baganator Refresh Button 0.3.0 -- WoW Forever
-- Manual, in-place Categories refresh, with a clickable header icon.

local ICON_PATH = "Interface\\AddOns\\BaganatorRefreshButton\\Assets\\Refresh"

BINDING_HEADER_BAGANATOR_REFRESH_BUTTON = "Baganator Refresh Button"
BINDING_NAME_BAGANATOR_REFRESH_BUTTON_REFRESH = "Refresh Baganator Categories"

-- Keep the refresh operation that has been confirmed to work in-game.
function BaganatorRefreshButton_Refresh()
    local registry = Baganator and Baganator.CallbackRegistry
    if registry and type(registry.TriggerEvent) == "function" then
        registry:TriggerEvent("RefreshStateChange", { [2] = true, [128] = true })
    end
end

SLASH_BAGANATORREFRESHBUTTON1 = "/bgrrefresh"
SLASH_BAGANATORREFRESHBUTTON2 = "/bgrr"
SlashCmdList.BAGANATORREFRESHBUTTON = BaganatorRefreshButton_Refresh

-- A Baganator skin callback gives us its real Sort button.
local buttons = setmetatable({}, { __mode = "k" })
local backpackFrames = setmetatable({}, { __mode = "k" })
local sortEvents = 0
local listening = false

local function HasTag(tags, desired)
    if type(tags) ~= "table" then return false end
    for key, value in pairs(tags) do
        if (key == desired and value == true) or value == desired then
            return true
        end
    end
    return false
end

local function FindBackpack(sort)
    local frame = sort
    for _ = 1, 12 do
        if not frame then return nil end
        if backpackFrames[frame]
            or (frame.TransferButton and frame.SortButton == sort)
            or (frame.TransferButton and frame.BagSlots) then
            return frame
        end
        if not frame.GetParent then return nil end
        frame = frame:GetParent()
    end
    return nil
end

local function UpdateEntry(sort, entry)
    local button = entry.button
    if not sort or not sort.IsVisible or not sort:IsVisible() then
        button:Hide()
        return
    end

    -- Unlike v0.2, this button belongs to UIParent rather than a possibly
    -- clipped/faded header container. It is still positioned relative to Sort.
    -- In particular, do NOT copy sort:GetAlpha(); some skins use alpha 0
    -- on their underlying frames and draw the actual icon separately.
    local w = math.max(18, math.min(26, sort:GetWidth() or 20))
    local h = math.max(18, math.min(26, sort:GetHeight() or 20))
    button:SetSize(w, h)
    button:SetAlpha(1)
    button:SetFrameStrata(sort:GetFrameStrata())
    button:SetFrameLevel(sort:GetFrameLevel() + 15)
    if not entry.anchored then
        button:ClearAllPoints()
        button:SetPoint("RIGHT", sort, "LEFT", 0, 0)
        entry.anchored = true
    end
    button:Show()

    -- Baganator positions Transfer immediately left of Sort at merchants.
    -- Keep that button to the left of Refresh, even when Baganator moves it.
    local backpack = entry.backpack or FindBackpack(sort)
    entry.backpack = backpack
    local transfer = backpack and backpack.TransferButton
    if transfer and transfer.IsShown and transfer:IsShown() then
        local _, currentRelative = transfer:GetPoint(1)
        if currentRelative ~= button then
            transfer:ClearAllPoints()
            transfer:SetPoint("RIGHT", button, "LEFT", 0, 0)
        end
    end
end

local function CreateRefreshButton(sort)
    if not sort or buttons[sort] or not sort.IsObjectType or not sort:IsObjectType("Button") then
        return
    end

    -- No borrowed template: v0.2's template/alpha could hide this control.
    -- The artwork is a small neutral circular arrow to match Baganator's UI.
    local button = CreateFrame("Button", nil, UIParent)
    button.BaganatorRefreshCompanion = true
    button:SetSize(20, 20)
    button:SetAlpha(1)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp")

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.10, 0.10, 0.10, 0.65)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ICON_PATH)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetSize(19, 19)
    icon:SetVertexColor(1, 1, 1, 1)
    button.BGRIcon = icon

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.20)

    button:SetScript("OnClick", BaganatorRefreshButton_Refresh)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Refresh Categories")
        GameTooltip:AddLine("Remove empty placeholders without closing the bags or sorting items.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local entry = { button = button, backpack = FindBackpack(sort), anchored = false }
    buttons[sort] = entry

    -- Changes to visibility and transfer positioning occur at various times
    -- during Baganator's bag/merchant updates. Check every 0.15 seconds.
    local elapsed = 0
    button:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        if elapsed >= 0.15 then
            elapsed = 0
            UpdateEntry(sort, entry)
        end
    end)

    sort:HookScript("OnShow", function() UpdateEntry(sort, entry) end)
    sort:HookScript("OnHide", function() button:Hide() end)
    UpdateEntry(sort, entry)
end

local function SkinListener(details)
    if type(details) ~= "table" then return end
    local region = details.region
    if not region or region.BaganatorRefreshCompanion then return end

    if details.regionType == "ButtonFrame" and HasTag(details.tags, "backpack") then
        backpackFrames[region] = true
        if region.SortButton then CreateRefreshButton(region.SortButton) end
    elseif details.regionType == "IconButton" and HasTag(details.tags, "sort") then
        sortEvents = sortEvents + 1
        CreateRefreshButton(region)
    end
end

local function Initialize()
    if listening then return end
    local skins = Baganator and Baganator.API and Baganator.API.Skins
    if not skins or type(skins.RegisterListener) ~= "function" then return end
    listening = true
    skins.RegisterListener(SkinListener)
    if type(skins.GetAllFrames) == "function" then
        for _, details in ipairs(skins.GetAllFrames()) do
            SkinListener(details)
        end
    end
end

SLASH_BAGANATORREFRESHDEBUG1 = "/bgrdebug"
SlashCmdList.BAGANATORREFRESHDEBUG = function()
    local total = 0
    local diagnostics = nil
    for sort, entry in pairs(buttons) do
        total = total + 1
        local btn = entry.button
        local x = btn.GetCenter and select(1, btn:GetCenter())
        local y = btn.GetCenter and select(2, btn:GetCenter())
        diagnostics = string.format(
            "Sort shown=%s visible=%s alpha=%.2f; Refresh shown=%s visible=%s alpha=%.2f position=%s,%s; backpack=%s",
            tostring(sort:IsShown()), tostring(sort:IsVisible()), sort:GetEffectiveAlpha(),
            tostring(btn:IsShown()), tostring(btn:IsVisible()), btn:GetEffectiveAlpha(),
            x and string.format("%.0f", x) or "nil",
            y and string.format("%.0f", y) or "nil",
            tostring(entry.backpack ~= nil)
        )
    end
    print("|cff94D7FFBaganator Refresh Button|r v0.3.0: sort events " .. sortEvents .. ", refresh buttons " .. total)
    if diagnostics then print(diagnostics) end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    Initialize()
    if C_Timer and C_Timer.After then C_Timer.After(1, Initialize) end
end)
