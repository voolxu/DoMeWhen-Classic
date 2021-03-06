local DMW = DMW
DMW.Bot.Misc = {}
local LibDraw = LibStub("LibDraw-1.0")
local Misc = DMW.Bot.Misc
local Log = DMW.Bot.Log
local Navigation = DMW.Bot.Navigation

local PauseFlags = {
    Hotspotting = false,
    Mapwalking = false
}

local mapX, mapY, mapZ

function Misc:ClamTask()
    -- instantly opens clams and deletes meat
    if not DMW.Player.Casting then
        for BagID = 0, 4 do
            for BagSlot = 1, GetContainerNumSlots(BagID) do
                CurrentItemLink = GetContainerItemLink(BagID, BagSlot)
                if CurrentItemLink then
                    name = GetItemInfo(CurrentItemLink)
                    if string.find(name, 'Clam Meat') then
                        PickupContainerItem(BagID,BagSlot); 
                        DeleteCursorItem();
                        return
                    end
                    
                    if name == 'Big-mouth Clam' or name == 'Thick-shelled Clam' or name == 'Small Barnacled Clam' then
                        UseContainerItem(BagID, BagSlot)
                        return
                    end
                end
            end
        end
        self:LootAllSlots()
    end
end

function Misc:LootAllSlots()
    for i = GetNumLootItems(), 1, -1 do
        LootSlot(i)
        ConfirmLootSlot(i)
    end
    CloseLoot()
end

function Misc:DeleteTask()
    -- Deletes quest items so we dont get stuck looting the same shit.
    for BagID = 0, 4 do
        for BagSlot = 1, GetContainerNumSlots(BagID) do
            CurrentItemLink = GetContainerItemLink(BagID, BagSlot)
            if CurrentItemLink then
                name = GetItemInfo(CurrentItemLink)
                if string.find(name, 'Distress') then
                    PickupContainerItem(BagID, BagSlot); 
                    DeleteCursorItem();
                end
            end
        end
    end
    -- Uses oozing bags
    if self:HasItem('Oozing Bag') then
        UseItemByName('Oozing Bag')
        self:LootAllSlots()
    end
end

function Misc:Hotspotter()
    local cx, cy, cz = GetLastClickInfo()
    local altDown = IsAltKeyDown()
    local shiftDown = IsShiftKeyDown()
    local ctrlDown = IsControlKeyDown()
    local middleMouseDown = GetKeyState(0x04)
    local roamSize = DMW.Settings.profile.Grind.RoamDistance / 2
    local deleteSize = 10
    local x, y = GetMousePosition()
    local mx, my, mz = ScreenToWorld(x, y)
    
    if mx and my and mz then
        if shiftDown and altDown then
            LibDraw.SetColor(255, 0, 0, 100)
            LibDraw.GroundCircle(mx, my, mz, deleteSize)
            LibDraw.Text("DELETE", "GameFontNormalLarge", mx, my, mz + 3)
            if middleMouseDown and mx ~= 0 and not PauseFlags.Hotspotting then
                if self:RemoveClickSpot(mx, my, mz) then
                    Log:DebugInfo('Removed Grind Hotspot [X: ' .. Round(cx) .. '] [Y: ' .. Round(cy) .. '] [Z: ' .. Round(cz) .. '] [Distance: ' .. Round(GetDistanceBetweenPositions(DMW.Player.PosX, DMW.Player.PosY, DMW.Player.PosZ, mx, my, mz)) .. ']')
                end
            end
        end

        if altDown and not shiftDown then
            LibDraw.GroundCircle(mx, my, mz, roamSize)
            LibDraw.Text("x", "GameFontNormalLarge", mx, my, mz + 1)
            if middleMouseDown and mx ~= 0 and not PauseFlags.Hotspotting then
                if self:AddClickSpot(mx, my, mz) then
                    Log:DebugInfo('Added Grind Hotspot [X: ' .. Round(mx) .. '] [Y: ' .. Round(my) .. '] [Z: ' .. Round(mz) .. '] [Distance: ' .. Round(GetDistanceBetweenPositions(DMW.Player.PosX, DMW.Player.PosY, DMW.Player.PosZ, mx, my, mz)) .. ']')
                end
            end
        end
    end
end

function Misc:RemoveClickSpot(x, y, z)
    local keyremove
    for k in pairs (DMW.Settings.profile.Grind.HotSpots) do
        local hx, hy, hz = DMW.Settings.profile.Grind.HotSpots[k].x, DMW.Settings.profile.Grind.HotSpots[k].y, DMW.Settings.profile.Grind.HotSpots[k].z
        local dist = GetDistanceBetweenPositions(x, y, z, hx, hy, hz)
        if dist < 20 then
            keyremove = k
            break
        end
    end
    if keyremove then
        DMW.Settings.profile.Grind.HotSpots [keyremove] = nil
        PauseFlags.Hotspotting = true
        C_Timer.After(0.3, function()
            PauseFlags.Hotspotting = false
        end)
        return true
    end
    return false
end

function Misc:AddClickSpot(xx, yy, zz)
    local Spot = {x = xx, y = yy, z = zz}
    for k in pairs (DMW.Settings.profile.Grind.HotSpots) do
        local hx, hy, hz = DMW.Settings.profile.Grind.HotSpots[k].x, DMW.Settings.profile.Grind.HotSpots[k].y, DMW.Settings.profile.Grind.HotSpots[k].z
        local dist = GetDistanceBetweenPositions(xx, yy, zz, hx, hy, hz)
        if dist < DMW.Settings.profile.Grind.RoamDistance then
            return false
        end
    end
    table.insert(DMW.Settings.profile.Grind.HotSpots, Spot)
    PauseFlags.Hotspotting = true
    C_Timer.After(0.3, function()
        PauseFlags.Hotspotting = false
    end)
    return true
end

function Misc:RotationToggle()
    if DMW.Settings.profile.Grind.SkipCombatOnTransport then
        -- if we have skip aggro enabled then if we are near hotspot(200 yards) enable rotation otherwise disable it.
        if Navigation:NearHotspot(250) then
            RunMacroText('/LILIUM HUD Rotation 1')
        else
            RunMacroText('/LILIUM HUD Rotation 2')
        end
    else
        -- If we dont have skip aggro then Enable rotation if its disabled
            RunMacroText('/LILIUM HUD Rotation 1')
    end
end

function Misc:HasItem(itemname)
    for BagID = 0, 4 do
        for BagSlot = 1, GetContainerNumSlots(BagID) do
            CurrentItemLink = GetContainerItemLink(BagID, BagSlot)
            if CurrentItemLink then
                name, void, Rarity, void, void, itype, SubType, void, void, void, ItemPrice = GetItemInfo(CurrentItemLink)
                if name == itemname then
                    return true
                end
            end
        end
    end
    return false
end

function Misc:WorldMapHook()
    if WorldMapFrame:IsVisible() and IsControlKeyDown() and IsMouseButtonDown("LeftButton") and not Mapwalking then
        local x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()
        local continentID, worldPosition = C_Map.GetWorldPosFromMapPos(WorldMapFrame:GetMapID(), CreateVector2D(x, y))
        local WX, WY = worldPosition:GetXY()
        local WZ = select(3, TraceLine(WX, WY, 10000, WX, WY, -10000, 0x110))
        if not WZ and WorldPreload(WX, WY, DMW.Player.PosZ) then
            WZ = select(3, TraceLine(WX, WY, 9999, WX, WY, -9999, 0x110))
        end
        if WZ then
            Log:NormalInfo('Moving to your selected destination.')
            mapX, mapY, mapZ = WX, WY, WZ
            Mapwalking = true
            C_Timer.After(1, function() Mapwalking = false end)
        end
    end

    if not mapX then return false end

    if mapX then
        local Distance = sqrt((mapX - DMW.Player.PosX) ^ 2) + ((mapY - DMW.Player.PosY) ^ 2)
        if Distance > 1 then
            Navigation:MoveTo(mapX, mapY, mapZ, true)
            return true
        else
            Log:NormalInfo('Destination reached.')
            mapX = nil mapY = nil mapZ = nil
        end
    end
end

function Misc:GetFreeSlots()
    local Total = 0
    for Bag = 0, NUM_BAG_SLOTS do
        local Free = GetContainerNumFreeSlots(Bag)
        Total = Total + Free
    end
    return Total
end