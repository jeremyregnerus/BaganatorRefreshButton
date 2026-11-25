-- Baganator Refresh Button 0.2.0 -- WoW Forever
-- Adds a *manual* in-place Categories refresh without sorting or reopening bags.

local ICON_PATH = "Interface\\AddOns\\BaganatorRefreshButton\\Assets\\Refresh"

-- Blizzard reads these names for the standard AddOns keybindings menu.
BINDING_HEADER_BAGANATOR_REFRESH_BUTTON = "Baganator Refresh Button"
BINDING_NAME_BAGANATOR_REFRESH_BUTTON_REFRESH = "Refresh Baganator Categories"

-- Keep the proven working callback completely unchanged.
function BaganatorRefreshButton_Refresh()
    local registry = Baganator and Baganator.CallbackRegistry
    if registry and type(registry.TriggerEvent) == "function" then
        registry:TriggerEvent("RefreshStateChange", { [2] = true, [128] = true })
    end
end

SLASH_BAGANATORREFRESHBUTTON1 = "/bgrrefresh"
SLASH_BAGANATORREFRESHBUTTON2 = "/bgrr"
SlashCmdList.BAGANATORREFRESHBUTTON = BaganatorRefreshButton_Refresh

local installed = setmetatable({}, { __mode = "k" }) -- [native sort] = refresh button
local knownBackpackFrames = setmetatable({}, { __mode = "k" })
local isCreating = false
local discoveredSorts = 0

local function HasTag(tags, desired)
    if type(tags) ~= "table" then return false end
    for key, value in pairs(tags) do
        if value == desired or (key == desired and value == true) then
            return true
        end
    end
    return false
end

local function FindBagFrame(sort)
    local frame = sort
    for _ = 1, 8 do
        if not frame or not frame.GetParent then break end
        -- BackpackView normally has these properties, including in older versions.
        if (frame.BagSlots and frame.TransferButton)
            or (frame.SortButton == sort and frame.TransferButton)
            or knownBackpackFrames[frame] then
            return frame
        end
        frame = frame:GetParent()
    end
    return nil
end

local function Reposition(sort)
    local refresh = installed[sort]
    if not refresh then return end

    refresh:ClearAllPoints()
    refresh:SetPoint("RIGHT", sort, "LEFT", 0, 0)
    refresh:SetShown(sort:IsShown())
    if sort.GetAlpha then refresh:SetAlpha(sort:GetAlpha()) end

    if not sort:IsShown() then return end

    -- Baganator uses this slot for its transfer/vendor button when appropriate.
    -- Find the actual backpack frame, rather than assuming its button hierarchy.
    local bagFrame = FindBagFrame(sort)
    local transfer = bagFrame and bagFrame.TransferButton
    if transfer and transfer ~= refresh and transfer:IsShown() then
        transfer:ClearAllPoints()
        transfer:SetPoint("RIGHT", refresh, "LEFT", 0, 0)
    end
end

local function SetIcon(button)
    if button.Icon and button.Icon.SetTexture then
        button.Icon:SetTexture(ICON_PATH)
        button.Icon:SetTexCoord(0, 1, 0, 1)
        button.Icon:SetVertexColor(1, 1, 1, 1)
    else
        -- Future-proof the icon path if Baganator renames its icon region.
        local icon = button:CreateTexture(nil, "OVERLAY", nil, 7)
        icon:SetTexture(ICON_PATH)
        icon:SetPoint("CENTER", 0, 0)
        icon:SetSize(17, 17)
        button.RefreshButtonIcon = icon
    end
end

local function CreateRefreshButton(sort)
    if not sort or installed[sort] or isCreating then return end
    if not sort.GetParent or not sort:GetParent() then return end

    isCreating = true
    -- Use Baganator's actual Sort template for the same borders, skin and hover.
    -- Use a plain button only if the internal template no longer exists.
    local ok, button = pcall(CreateFrame, "Button", nil, sort:GetParent(), "BaganatorSortButtonTemplate")
    if not ok or not button then
        button = CreateFrame("Button", nil, sort:GetParent())
        local bg = button:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.13, 0.13, 0.13, 0.85)
        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 1, 1, 0.14)
    end
    isCreating = false

    button.BaganatorRefreshCompanion = true
    button:SetSize(math.max(sort:GetWidth(), 19), math.max(sort:GetHeight(), 19))
    button:SetFrameStrata(sort:GetFrameStrata())
    button:SetFrameLevel(sort:GetFrameLevel())
    button:RegisterForClicks("LeftButtonUp")
    SetIcon(button)

    button:SetScript("OnClick", function() BaganatorRefreshButton_Refresh() end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Refresh Categories")
        GameTooltip:AddLine("Rebuilds the category layout without sorting or closing the bags.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    installed[sort] = button

    sort:HookScript("OnShow", function() Reposition(sort) end)
    sort:HookScript("OnHide", function() button:Hide() end)

    local bagFrame = FindBagFrame(sort)
    if bagFrame then
        bagFrame:HookScript("OnShow", function() Reposition(sort) end)
        if type(bagFrame.UpdateTransferButton) == "function" then
            hooksecurefunc(bagFrame, "UpdateTransferButton", function()
                Reposition(sort)
            end)
        end
    end
    Reposition(sort)
end

local function SkinListener(details)
    if isCreating or type(details) ~= "table" then return end
    local region = details.region
    if not region or region.BaganatorRefreshCompanion then return end

    if details.regionType == "ButtonFrame" and HasTag(details.tags, "backpack") then
        knownBackpackFrames[region] = true
        if region.SortButton then CreateRefreshButton(region.SortButton) end
    elseif details.regionType == "IconButton" and HasTag(details.tags, "sort") then
        discoveredSorts = discoveredSorts + 1
        -- In v868 and later, the Sort button may no longer be exposed as
        -- backpackFrame.SortButton. Hook the button itself via its skin tag.
        CreateRefreshButton(region)
    end
end

local listenerRegistered = false
local function Initialize()
    if listenerRegistered then return end
    local skins = Baganator and Baganator.API and Baganator.API.Skins
    if not skins or type(skins.RegisterListener) ~= "function" then return end
    listenerRegistered = true

    skins.RegisterListener(SkinListener)
    if type(skins.GetAllFrames) == "function" then
        for _, details in ipairs(skins.GetAllFrames()) do
            SkinListener(details)
        end
    end
end

-- Diagnostic command in case Baganator changes its layout again.
SLASH_BAGANATORREFRESHDEBUG1 = "/bgrdebug"
SlashCmdList.BAGANATORREFRESHDEBUG = function()
    local total = 0
    for _ in pairs(installed) do total = total + 1 end
    local registry = Baganator and Baganator.API and Baganator.API.Skins
    print("|cff94D7FFBaganator Refresh Button|r v0.2.0: skin API " ..
        (registry and "available" or "missing") .. ", sort events " ..
        discoveredSorts .. ", refresh buttons " .. total)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
    Initialize()
    if C_Timer and C_Timer.After then C_Timer.After(1, Initialize) end
end)
