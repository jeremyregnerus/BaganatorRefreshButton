-- Baganator Refresh Button v0.4.0 -- WoW Forever
-- Manual in-place Categories view refresh.  No changes to inventory slots.

local VERSION = "0.4.0"
local ICON_PATH = "Interface\\AddOns\\BaganatorRefreshButton\\Assets\\Refresh.tga"

BINDING_HEADER_BAGANATOR_REFRESH_BUTTON = "Baganator Refresh Button"
BINDING_NAME_BAGANATOR_REFRESH_BUTTON_REFRESH = "Refresh Baganator Categories"

-- This is the exact event/flags confirmed working by the user.
function BaganatorRefreshButton_Refresh()
    local registry = Baganator and Baganator.CallbackRegistry
    if registry and type(registry.TriggerEvent) == "function" then
        registry:TriggerEvent("RefreshStateChange", { [2] = true, [128] = true })
    end
end

SLASH_BAGANATORREFRESHBUTTON1 = "/bgrrefresh"
SLASH_BAGANATORREFRESHBUTTON2 = "/bgrr"
SlashCmdList.BAGANATORREFRESHBUTTON = BaganatorRefreshButton_Refresh

local sorts = {}       -- Ordered list; v0.3 debug accidentally described only one of two.
local sortSet = {}     -- Each actual Sort frame is listed only once.
local button
local selectedSort
local testMode = false
local initialized = false

local function HasTag(tags, desired)
    if type(tags) ~= "table" then return false end
    for key, value in pairs(tags) do
        if value == desired or (key == desired and value == true) then return true end
    end
    return false
end

local function ParentInfo(frame)
    local names = {}
    local backpack = false
    local current = frame
    for i = 1, 16 do
        if not current then break end
        local name = (current.GetName and current:GetName()) or ""
        if name == "" and current.GetDebugName then
            name = current:GetDebugName() or ""
        end
        if name ~= "" then
            if name:lower():find("backpack", 1, true) then backpack = true end
            if i <= 5 then names[#names + 1] = name end
        end
        if not current.GetParent then break end
        current = current:GetParent()
    end
    return backpack, (#names > 0 and table.concat(names, " / ") or "unnamed")
end

local function CandidateInfo(sort)
    local w, h = UIParent:GetWidth(), UIParent:GetHeight()
    local x, y = sort:GetCenter()
    local visible = sort:IsVisible() and sort:GetEffectiveAlpha() > 0.05
    local onScreen = x ~= nil and y ~= nil and w and h
        and x >= 0 and x <= w and y >= 0 and y <= h
    local backpack, parents = ParentInfo(sort)
    return {x=x, y=y, visible=visible, onScreen=onScreen, backpack=backpack, parents=parents}
end

local function ChooseSort()
    local best, bestScore
    local w = UIParent:GetWidth()
    for _, sort in ipairs(sorts) do
        local info = CandidateInfo(sort)
        if info.visible and info.onScreen then
            -- The backpack Sort is preferred to bank/other Sort controls.
            -- When neither is named, favor the right-hand side inventory view.
            local score = (info.backpack and 100 or 0) + ((info.x or 0) / (w > 0 and w or 1))
            if not bestScore or score > bestScore then
                best, bestScore = sort, score
            end
        end
    end
    return best
end

local function CreateButton()
    if button then return end
    button = CreateFrame("Button", "BaganatorRefreshCompanionButton", UIParent)
    button:SetSize(24, 24)
    button:SetFrameStrata("FULLSCREEN_DIALOG") -- Above Baganator's header; below tooltips.
    button:SetFrameLevel(100)
    button:RegisterForClicks("LeftButtonUp")
    button:EnableMouse(true)
    button:Hide()

    -- Visible border even if a custom texture fails to load.
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(button)
    bg:SetColorTexture(0.13, 0.13, 0.13, 0.95)
    local function Edge(point1, point2, size, horizontal)
        local t = button:CreateTexture(nil, "BORDER")
        t:SetColorTexture(0.65, 0.65, 0.65, 0.95)
        t:SetPoint(point1, button, point1)
        t:SetPoint(point2, button, point2)
        if horizontal then t:SetHeight(size) else t:SetWidth(size) end
    end
    Edge("TOPLEFT", "TOPRIGHT", 1, true)
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", 1, true)
    Edge("TOPLEFT", "BOTTOMLEFT", 1, false)
    Edge("TOPRIGHT", "BOTTOMRIGHT", 1, false)

    local artwork = button:CreateTexture(nil, "ARTWORK")
    artwork:SetTexture(ICON_PATH)
    artwork:SetPoint("CENTER", button, "CENTER", 0, 0)
    artwork:SetSize(20, 20)
    artwork:SetVertexColor(1, 1, 1, 1)
    button.Icon = artwork

    local hover = button:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints(button)
    hover:SetColorTexture(1, 1, 1, 0.16)

    button:SetScript("OnClick", BaganatorRefreshButton_Refresh)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Refresh Categories")
        GameTooltip:AddLine("Clear empty placeholders without closing bags or sorting items.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function UpdatePosition()
    if not button then return end
    if testMode then
        if selectedSort then selectedSort = nil end
        button:ClearAllPoints()
        button:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        button:Show()
        return
    end

    local sort = ChooseSort()
    if not sort then
        selectedSort = nil
        button:Hide()
        return
    end

    if selectedSort ~= sort then
        selectedSort = sort
        button:ClearAllPoints()
        -- Anchor to the real Sort control.  No coordinates/scaling guessed.
        button:SetPoint("RIGHT", sort, "LEFT", -3, 0)
    end
    -- V0.3 was sometimes underneath the header's later-added regions.
    -- Keep an independent strata/level instead of copying Sort's level.
    button:SetFrameStrata("FULLSCREEN_DIALOG")
    button:SetFrameLevel(100)
    button:Show()
end

local function SkinListener(details)
    if type(details) ~= "table" then return end
    if details.regionType == "IconButton" and HasTag(details.tags, "sort") then
        local sort = details.region
        if sort and sort.IsObjectType and sort:IsObjectType("Button") and not sortSet[sort] then
            sortSet[sort] = true
            sorts[#sorts + 1] = sort
        end
    end
end

local function Initialize()
    if initialized then return end
    local api = Baganator and Baganator.API and Baganator.API.Skins
    if not api or type(api.RegisterListener) ~= "function" then return end
    initialized = true
    CreateButton()
    api.RegisterListener(SkinListener)
    if type(api.GetAllFrames) == "function" then
        for _, details in ipairs(api.GetAllFrames()) do SkinListener(details) end
    end
    local ticker = CreateFrame("Frame")
    local elapsed = 0
    ticker:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed > 0.20 then
            elapsed = 0
            UpdatePosition()
        end
    end)
    UpdatePosition()
end

SLASH_BAGANATORREFRESHDEBUG1 = "/bgrdebug"
SlashCmdList.BAGANATORREFRESHDEBUG = function()
    print("|cff94D7FFBaganator Refresh Button|r v" .. VERSION .. ": " .. #sorts .. " sort candidates; UIParent " ..
        string.format("%.0fx%.0f", UIParent:GetWidth(), UIParent:GetHeight()) .. "; testMode=" .. tostring(testMode))
    for i, sort in ipairs(sorts) do
        local info = CandidateInfo(sort)
        print(string.format("Sort %d: visible=%s onscreen=%s backpack=%s center=%s,%s strata=%s level=%d", i,
            tostring(info.visible), tostring(info.onScreen), tostring(info.backpack),
            info.x and string.format("%.0f", info.x) or "nil",
            info.y and string.format("%.0f", info.y) or "nil",
            sort:GetFrameStrata(), sort:GetFrameLevel()))
        print("  Parents: " .. info.parents)
    end
    if button then
        local x, y = button:GetCenter()
        print(string.format("Refresh: shown=%s visible=%s center=%s,%s strata=%s level=%d selected=%s", 
            tostring(button:IsShown()), tostring(button:IsVisible()),
            x and string.format("%.0f", x) or "nil", y and string.format("%.0f", y) or "nil",
            button:GetFrameStrata(), button:GetFrameLevel(), tostring(selectedSort ~= nil)))
    else
        print("Refresh frame: not created (skin API not initialized)")
    end
end

SLASH_BAGANATORREFRESHTEST1 = "/bgrtest"
SlashCmdList.BAGANATORREFRESHTEST = function()
    testMode = not testMode
    selectedSort = nil
    UpdatePosition()
    print("|cff94D7FFBaganator Refresh Button|r: center-screen visibility test " .. (testMode and "ON" or "OFF"))
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    Initialize()
    if C_Timer and C_Timer.After then C_Timer.After(1, Initialize) end
end)
