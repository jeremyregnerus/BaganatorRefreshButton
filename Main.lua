-- Baganator Refresh Button v0.9.1 -- WoW Forever
-- Manual in-place Categories view refresh.  No changes to inventory slots.

local VERSION = "0.9.1"
local GLYPH_PATH = "Interface\\AddOns\\BaganatorRefreshButton\\Assets\\RefreshGlyph.tga"

BINDING_HEADER_BAGANATOR_REFRESH_BUTTON = "Baganator Refresh Button"
BINDING_NAME_BAGANATOR_REFRESH_BUTTON_REFRESH = "Refresh"

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
local lastPadding
local observedNativePadding
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

-- Use the exact same Baganator XML template as its own Sort button.
-- The inherited UIPanelButtonTemplate owns the full normal/pushed/highlight
-- styling, including the grey textured Blizzard border. We only supply a
-- transparent, gold refresh symbol as the Icon artwork.
local glyphTexture

local function ApplyButtonDimensions(sort)
    if not button or not sort then return false end
    local width, height = sort:GetSize()
    if not width or not height or width < 11 or height < 11 then return false end

    local changed = math.abs(width - button:GetWidth()) > 0.1
        or math.abs(height - button:GetHeight()) > 0.1
    if changed then button:SetSize(width, height) end

    -- Match the dimensions of Baganator's own Sort glyph too, not a percentage
    -- of the surrounding rectangular button. The gold refresh icon stays square.
    local iconWidth, iconHeight = 17, 17
    if sort.Icon and sort.Icon.GetSize then
        local sw, sh = sort.Icon:GetSize()
        if sw and sh and sw > 1 and sh > 1 then
            iconWidth, iconHeight = sw, sh
        end
    end
    local side = math.min(iconWidth, iconHeight, width - 4, height - 2)
    side = math.max(8, side)
    glyphTexture:SetSize(side, side)
    return changed
end

local function CreateButton()
    if button then return end

    -- This is the exact template inherited by BaganatorSortButtonTemplate.
    -- Unlike our former handmade panel, it uses the very same border,
    -- normal, pushed and hover textures as the adjacent native controls.
    button = CreateFrame("Button", "BaganatorRefreshCompanionButton", UIParent,
        "BaganatorTooltipIconButtonTemplate")
    button:SetFrameStrata("FULLSCREEN_DIALOG")
    button:SetFrameLevel(100)
    button:RegisterForClicks("LeftButtonUp")
    button:EnableMouse(true)
    button:Hide()
    button.tooltipHeader = "Refresh Categories"
    button.tooltipText = "Clear empty placeholders without closing bags or sorting items."

    glyphTexture = button:CreateTexture(nil, "OVERLAY", nil, 1)
    glyphTexture:SetTexture(GLYPH_PATH)
    glyphTexture:SetSize(17, 17)
    glyphTexture:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.Icon = glyphTexture

    -- Let Baganator's selected skin treat Refresh as a regular IconButton.
    -- This is also what its own Sort and Transfer buttons register as.
    if Baganator and Baganator.Skins and type(Baganator.Skins.AddFrame) == "function" then
        Baganator.Skins.AddFrame("IconButton", button, {"refresh"})
    end

    button:SetScript("OnClick", BaganatorRefreshButton_Refresh)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.tooltipHeader)
        GameTooltip:AddLine(self.tooltipText, 1, 1, 1, true)
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

-- Derive the gap from Baganator's own adjoining header controls whenever
-- possible, instead of reproducing an approximate fixed offset.
-- Keep a conservative 2-unit fallback when there is no visible neighbor.
local function HeaderPadding(sort, neighbors)
    local sortLeft = sort:GetLeft()
    if sortLeft then
        local best
        for _, other in ipairs(neighbors) do
            local gap = sortLeft - other.right
            if gap >= 0 and gap <= 10 and (not best or gap < best) then
                best = gap
            end
        end
        if best then observedNativePadding = best end
    end
    if BaganatorRefreshButtonDB and type(BaganatorRefreshButtonDB.gap) == "number" then
        return BaganatorRefreshButtonDB.gap
    end
    return observedNativePadding or 2
end

local function UpdatePosition()
    if not button then return end
    if testMode then
        selectedSort = nil
        lastAnchor = nil
        lastPadding = nil
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
        lastPadding = nil
        button:Hide()
        anchorName = "none"
        return
    end

    -- Match the real Sort button, even if Baganator's skin or UI scale changes.
    -- Re-anchor on a size change so bank Transfer fallback keeps its spacing.
    if ApplyButtonDimensions(sort) then
        lastAnchor = nil
    end

    -- Sort controls exist for both backpack and bank, but Refresh belongs
    -- exclusively to the backpack header.
    local neighbors = HeaderNeighbors(sort)
    nearbyCount = #neighbors
    local target = sort
    local sortLeft = sort:GetLeft()
    local targetLeft = sortLeft
    local buttonWidth = button:GetWidth()
    local padding = HeaderPadding(sort, neighbors)

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
    if selectedSort ~= sort or lastAnchor ~= target or lastReserve ~= bankReserve or lastPadding ~= padding then
        selectedSort = sort
        lastAnchor = target
        lastReserve = bankReserve
        lastPadding = padding
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
        print(string.format("  Anchor=%s; nearby header buttons=%d; bank fallback=%s; size=%.1fx%.1f; gap=%.2f", anchorName, nearbyCount, tostring(bankReserve), button:GetWidth(), button:GetHeight(), lastPadding or 0))
    else
        print("Refresh frame: not created (skin API not initialized)")
    end
end

-- Optional fine tuning: /bgrgap auto or /bgrgap <0..10>.
-- Only changes spacing, never physical bag contents or the refresh handler.
SLASH_BAGANATORREFRESHGAP1 = "/bgrgap"
SlashCmdList.BAGANATORREFRESHGAP = function(text)
    local arg = (text or ""):lower():match("^%s*(.-)%s*$")
    if arg == "auto" then
        if not BaganatorRefreshButtonDB then BaganatorRefreshButtonDB = {} end
        BaganatorRefreshButtonDB.gap = nil
        observedNativePadding = nil
    else
        local number = tonumber(arg)
        if not number or number < 0 or number > 10 then
            print("|cff94D7FFBaganator Refresh Button|r: /bgrgap auto or /bgrgap 0-10")
            return
        end
        if not BaganatorRefreshButtonDB then BaganatorRefreshButtonDB = {} end
        BaganatorRefreshButtonDB.gap = number
    end
    selectedSort, lastAnchor, lastPadding = nil, nil, nil
    UpdatePosition()
    print("|cff94D7FFBaganator Refresh Button|r: header gap " .. tostring(lastPadding or "auto") .. " (" .. (BaganatorRefreshButtonDB and BaganatorRefreshButtonDB.gap and "manual" or "auto") .. ")")
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
