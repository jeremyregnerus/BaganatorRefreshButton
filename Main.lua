-- Baganator Refresh Button v0.5.0 -- WoW Forever
-- Manual in-place Categories view refresh.  No changes to inventory slots.

local VERSION = "0.5.0"
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

local sorts = {}       -- Known Sort buttons (backpack and bank).
local sortSet = {}     -- Each actual Sort frame is listed only once.
local headerButtons = {} -- Other skinned header buttons, including Transfer if registered.
local headerSet = {}
local anchorName = "none"
local nearbyCount = 0
local bankReserve = false
local button
local selectedSort
local lastAnchor
local lastReserve
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

-- Return the shared Backpack view ancestor for any of its children.
-- The client names subframes dynamically, so avoid depending on their suffixes.
local function BackpackRoot(frame)
    local current, root = frame, nil
    for i = 1, 16 do
        if not current or current == UIParent then break end
        local name = (current.GetName and current:GetName()) or ""
        if name == "" and current.GetDebugName then
            name = current:GetDebugName() or ""
        end
        if name:find("CategoryViewBackpackViewFrame", 1, true) then
            root = current -- keep the outermost matching BackpackViewFrame
        end
        current = current.GetParent and current:GetParent() or nil
    end
    return root
end

-- Search the header's actual button frames as well as those known to the
-- skin registry.  Some context-dependent buttons do not announce a 'sort' tag.
local function HeaderNeighbors(sort)
    local list, seen = {}, {}
    local root = BackpackRoot(sort)
    local sortX, sortY = sort:GetCenter()
    if not sortX or not sortY then return list end

    local function Consider(candidate)
        if not candidate or candidate == sort or candidate == button or seen[candidate]
            or not candidate.IsObjectType or not candidate:IsObjectType("Button") then return end
        seen[candidate] = true
        if not candidate:IsVisible() or candidate:GetEffectiveAlpha() < 0.05 then return end
        local x, y = candidate:GetCenter()
        if not x or not y or math.abs(y - sortY) > 14 or x >= sortX or x < sortX - 190 then return end
        local width, height = candidate:GetWidth(), candidate:GetHeight()
        if not width or not height or width < 10 or width > 60 or height < 10 or height > 60 then return end
        local left, right = candidate:GetLeft(), candidate:GetRight()
        if not left or not right then return end
        list[#list + 1] = { frame = candidate, left = left, right = right, x = x }
    end

    for _, candidate in ipairs(headerButtons) do
        if root and BackpackRoot(candidate) == root then Consider(candidate) end
    end

    local function Visit(parent, depth)
        if not parent or depth > 5 or not parent.GetChildren then return end
        local children = { parent:GetChildren() }
        for _, child in ipairs(children) do
            Consider(child)
            Visit(child, depth + 1)
        end
    end
    if root then Visit(root, 1) end
    return list
end

local function UpdatePosition()
    if not button then return end
    if testMode then
        selectedSort = nil
        lastAnchor = nil
        button:ClearAllPoints()
        button:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        anchorName = "center test"
        button:Show()
        return
    end

    local sort = ChooseSort()
    if not sort then
        selectedSort = nil
        lastAnchor = nil
        button:Hide()
        anchorName = "none"
        return
    end

    -- Sort controls exist for both backpack and bank, but Refresh belongs
    -- exclusively to the backpack header.
    local neighbors = HeaderNeighbors(sort)
    nearbyCount = #neighbors
    local target = sort
    local sortLeft = sort:GetLeft()
    local targetLeft = sortLeft
    local buttonWidth = button:GetWidth()
    local padding = 3

    -- Find a spot that does not collide with the adjacent Transfer or any
    -- other small visible header controls. Repeat for multiple adjacent icons.
    for attempt = 1, 8 do
        local proposedRight = targetLeft - padding
        local proposedLeft = proposedRight - buttonWidth
        local overlap = nil
        for _, other in ipairs(neighbors) do
            if other.left < proposedRight + 1 and other.right > proposedLeft - 1 then
                if not overlap or other.left < overlap.left then overlap = other end
            end
        end
        if not overlap then break end
        target = overlap.frame
        targetLeft = overlap.left
    end

    -- Fallback for Forever versions that do not register Transfer as a skinned
    -- Button. When the bank is visible, reserve one button-width left of Sort.
    -- Only use this when no collision was detected at the intended Sort slot.
    bankReserve = false
    if target == sort then
        for _, candidate in ipairs(sorts) do
            if candidate ~= sort then
                local info = CandidateInfo(candidate)
                if info.visible and info.onScreen and not info.backpack then
                    bankReserve = true
                    break
                end
            end
        end
    end

    -- Only re-anchor when the context changes; the relative anchor will move
    -- automatically when Baganator moves the window.
    if selectedSort ~= sort or lastAnchor ~= target or lastReserve ~= bankReserve then
        selectedSort = sort
        lastAnchor = target
        lastReserve = bankReserve
        button:ClearAllPoints()
        if bankReserve then
            button:SetPoint("RIGHT", sort, "LEFT", -(padding + buttonWidth + padding), 0)
            anchorName = "Sort (bank fallback)"
        else
            button:SetPoint("RIGHT", target, "LEFT", -padding, 0)
            anchorName = target == sort and "Sort" or "adjacent header button"
        end
    end
    button:SetFrameStrata("FULLSCREEN_DIALOG")
    button:SetFrameLevel(100)
    button:Show()
end

local function SkinListener(details)
    if type(details) ~= "table" then return end
    local region = details.region
    if not region or not region.IsObjectType or not region:IsObjectType("Button") then return end
    -- Track all Baganator icon buttons so context-dependent Transfer controls
    -- can be detected without relying on their localized names or textures.
    if (details.regionType == "IconButton" or details.regionType == "Button") and not headerSet[region] then
        headerSet[region] = true
        headerButtons[#headerButtons + 1] = region
    end
    if details.regionType == "IconButton" and HasTag(details.tags, "sort") and not sortSet[region] then
        sortSet[region] = true
        sorts[#sorts + 1] = region
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
        print(string.format("  Anchor=%s; nearby header buttons=%d; bank fallback=%s", anchorName, nearbyCount, tostring(bankReserve)))
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
