-- BaganatorRefreshButton v0.1.0 - World of Warcraft: Forever
-- Manual in-place refresh for Baganator Categories view.
-- Does not close/reopen the window, sort inventory, or refresh on vendoring.

local ICON = "Interface\\AddOns\\BaganatorRefreshButton\\Assets\\Refresh"
local installedFrames = setmetatable({}, { __mode = "k" })

-- These two global strings are read by Blizzard's Key Bindings UI.
BINDING_HEADER_BAGANATOR_REFRESH_BUTTON = "Baganator Refresh Button"
BINDING_NAME_BAGANATOR_REFRESH_BUTTON_REFRESH = "Refresh Baganator Categories"

-- This is the *exact* internal Baganator event that was tested successfully.
-- Flags 2 and 128 cause its category layout to be rebuilt in-place.
function BaganatorRefreshButton_Refresh()
    local registry = Baganator and Baganator.CallbackRegistry
    if registry and type(registry.TriggerEvent) == "function" then
        registry:TriggerEvent("RefreshStateChange", { [2] = true, [128] = true })
    end
end

SLASH_BAGANATORREFRESHBUTTON1 = "/bgrrefresh"
SLASH_BAGANATORREFRESHBUTTON2 = "/bgrr"
SlashCmdList.BAGANATORREFRESHBUTTON = BaganatorRefreshButton_Refresh

local function HasTag(details, sought)
    if type(details.tags) ~= "table" then return false end
    for _, tag in pairs(details.tags) do
        if tag == sought then return true end
    end
    return false
end

-- Used after a Baganator header relayout. Baganator itself moves the Transfer
-- button when visiting a merchant, so put it to the left of our new button.
local function PositionButton(bagFrame)
    local button = installedFrames[bagFrame]
    local sort = bagFrame and bagFrame.SortButton
    if not button or not sort then return end

    button:ClearAllPoints()
    button:SetPoint("RIGHT", sort, "LEFT", 0, 0)
    button:SetShown(sort:IsShown())

    local transfer = bagFrame.TransferButton
    if transfer and transfer:IsShown() then
        transfer:ClearAllPoints()
        transfer:SetPoint("RIGHT", button, "LEFT", 0, 0)
    end
end

local function InstallButton(bagFrame)
    if not bagFrame or installedFrames[bagFrame] or not bagFrame.SortButton then return end

    local sort = bagFrame.SortButton

    -- Reuse the exact button template as Baganator's Sort control, rather than
    -- putting a mismatched Blizzard default button in the header.
    local button = CreateFrame("Button", nil, bagFrame, "BaganatorSortButtonTemplate")
    button:SetSize(sort:GetWidth(), sort:GetHeight())
    button:SetFrameLevel(sort:GetFrameLevel())

    -- The native Sort template provides the existing border, mouseover, and
    -- pressed visuals. Change only its actual icon to a circular refresh arrow.
    if button.Icon then
        button.Icon:SetTexture(ICON)
    else
        -- Fallback for versions where the native template has no Icon key.
        -- Cover any inherited icon texture with our own 16px glyph.
        button.RefreshIcon = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.RefreshIcon:SetTexture(ICON)
        button.RefreshIcon:SetPoint("CENTER", button, "CENTER", 0, 0)
        button.RefreshIcon:SetSize(17, 17)
    end

    button:SetScript("OnClick", BaganatorRefreshButton_Refresh)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Refresh Categories")
        GameTooltip:AddLine("Clear empty spaces and rebuild the visible category layout.", 1, 1, 1, true)
        GameTooltip:AddLine("Does not move inventory items or close the bags.", 0.65, 0.82, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    installedFrames[bagFrame] = button

    -- Retain compatibility with Baganator's Alt-to-show-header-buttons setting.
    if type(bagFrame.AllButtons) == "table" then
        table.insert(bagFrame.AllButtons, button)
    end

    sort:HookScript("OnShow", function() PositionButton(bagFrame) end)
    sort:HookScript("OnHide", function() button:Hide() end)
    bagFrame:HookScript("OnShow", function() PositionButton(bagFrame) end)

    -- Baganator relocates Transfer during its normal updates. Keep transfer
    -- just to the left of our Refresh button, so nothing overlaps at vendors.
    if type(bagFrame.UpdateTransferButton) == "function" then
        hooksecurefunc(bagFrame, "UpdateTransferButton", function()
            PositionButton(bagFrame)
        end)
    end

    PositionButton(bagFrame)
end

local function OnSkinFrame(details)
    if type(details) ~= "table" then return end
    if details.regionType == "ButtonFrame" and HasTag(details, "backpack") then
        InstallButton(details.region)
    end
end

local initialized = false
local function Initialize()
    if initialized then return end
    local skins = Baganator and Baganator.API and Baganator.API.Skins
    if not skins or type(skins.GetAllFrames) ~= "function"
        or type(skins.RegisterListener) ~= "function" then
        return
    end

    initialized = true
    skins.RegisterListener(OnSkinFrame)
    for _, details in ipairs(skins.GetAllFrames()) do
        OnSkinFrame(details)
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    -- Baganator builds frames on login; waiting one frame avoids load-order
    -- differences between client versions without any permanent polling.
    if C_Timer and C_Timer.After then
        C_Timer.After(0, Initialize)
    else
        Initialize()
    end
end)
