--------------------------------------------------------------------
--					          Häuserreihe erstellen									      --
--------------------------------------------------------------------
--[[
  Dependencies: 
    community_comforts.lua
    
  quantity:   anzahl der Gebäude in der Reihe
  jitter:     Ungenauigkeit, d.h. das Haus ist ein bisschen schief bzw. verrutscht.
]]--
function CreateHouseRow(pos1, pos2, houses, quantity, orientation, pID, jitter)
	local jitter = jitter or false
	local howOften
	local houseIDs = {}
	local k = {}
	if type(houses) == "table" then
		howOften = table.getn(houses)
	else
		howOften = 1
	end
	local p1
	local p2
	if type(pos1) == "string" and type(pos2) == "string" then
		p1 = GetPosition(pos1)
		p2 = GetPosition(pos2)
	elseif type(pos1) == "number" and type(pos2) == "number" then
		p1 = pos1
		p2 = pos2
	end
	k.X = (p1.X - p2.X) / (quantity - 1)
	k.Y = (p1.Y - p2.Y) / (quantity - 1)
	local housePos = {}
	local house = 0
	local rotation
	local randomOrient
	local randomBonus
	for i = 1, quantity do
		local whichHouse
		if jitter then
			randomOrient = GetRandom(-10, 10)
		else
			randomOrient = 0
		end
		if howOften ~= 1 then
			whichHouse = GetRandom(1, howOften)
			rotation = orientation - buildingInfo[houses[whichHouse]].orient + randomOrient
		else
			rotation = orientation - buildingInfo[houses].orient + randomOrient
		end
		if jitter then
			randomBonus = GetRandom(-50, 50)
		else
			randomBonus = 0
		end
		housePos.X = p1.X - (k.X * house) + randomBonus
		housePos.Y = p1.Y - (k.Y * house) + randomBonus
		local hID = Logic.CreateEntity(houses[whichHouse], housePos.X, housePos.Y, rotation, pID)
		if howOften ~= 1 then
			if buildingInfo[houses[whichHouse]].ruin then
				PlaceRuinFragments(housePos, pID)
			end
		else
			if buildingInfo[houses].ruin then
				PlaceRuinFragments(housePos, pID)
			end
		end
		table.insert(houseIDs, hID)
		house = house + 1
	end
	return houseIDs
end

function PlaceRuinFragments(housePos, pID)
	local ruinFragment = {Entities.XD_RuinFragment1, Entities.XD_RuinFragment2, Entities.XD_RuinFragment3, Entities.XD_RuinFragment4, Entities.XD_RuinFragment5, Entities.XD_RuinFragment6}
	for i = 1, 5 do
		local random1 = GetRandom(-300, 300)
		local random2 = GetRandom(-300, 300)
		local whichFragment = GetRandom(1, 6)
		local fragmentRotation = GetRandom(1, 360)
		local fragmentPos = {X = housePos.X + random1, Y = housePos.Y + random2}
		Logic.CreateEntity(ruinFragment[whichFragment], fragmentPos.X, fragmentPos.Y, fragmentRotation, pID)
	end
end
buildingInfo = {
  [Entities.PB_Beautification03] = { orient = 90, ruin = false},
  [Entities.PB_Blacksmith1] = { orient = 90, ruin = false},
  [Entities.PB_Blacksmith2] = { orient = 90, ruin = false},
  [Entities.PB_Blacksmith3] = { orient = 90, ruin = false},
  [Entities.PB_Foundry1] = { orient = 90, ruin = false},
  [Entities.PB_Foundry2] = { orient = 90, ruin = false},
  [Entities.PB_MasterBuilderWorkshop] = { orient = 90, ruin = false},
  [Entities.PB_Residence1] = { orient = 90, ruin = false},
  [Entities.PB_Residence2] = { orient = 90, ruin = false},
  [Entities.PB_Residence3] = { orient = 90, ruin = false},
  [Entities.PB_VillageCenter1] = { orient = 90, ruin = false},
  [Entities.PB_VillageCenter2] = { orient = 90, ruin = false},
  [Entities.PB_VillageCenter3] = { orient = 90, ruin = false},
  [Entities.XD_RuinResidence1] = { orient = 90, ruin = true},
  --
  [Entities.CB_HermitHut1] = { orient = 0, ruin = false},
  [Entities.CB_Camp01] = { orient = 0, ruin = false},
  [Entities.CB_Camp02] = { orient = 0, ruin = false},
  [Entities.CB_Camp03] = { orient = 0, ruin = false},
  [Entities.CB_Camp04] = { orient = 0, ruin = false},
  [Entities.CB_Camp05] = { orient = 0, ruin = false},
  [Entities.CB_Camp06] = { orient = 0, ruin = false},
  [Entities.CB_Camp07] = { orient = 0, ruin = false},
  [Entities.CB_Camp08] = { orient = 0, ruin = false},
  [Entities.CB_Camp09] = { orient = 0, ruin = false},
  [Entities.CB_Camp10] = { orient = 0, ruin = false},
  [Entities.CB_Camp11] = { orient = 0, ruin = false},
  [Entities.CB_Camp12] = { orient = 0, ruin = false},
  [Entities.CB_Camp13] = { orient = 0, ruin = false},
  [Entities.CB_Camp14] = { orient = 0, ruin = false},
  [Entities.CB_Camp15] = { orient = 0, ruin = false},
  [Entities.CB_Camp16] = { orient = 0, ruin = false},
  [Entities.CB_Camp17] = { orient = 0, ruin = false},
  [Entities.CB_Camp18] = { orient = 0, ruin = false},
  [Entities.CB_Camp19] = { orient = 0, ruin = false},
  [Entities.CB_Camp20] = { orient = 0, ruin = false},
  [Entities.CB_Camp21] = { orient = 0, ruin = false},
  [Entities.CB_Camp22] = { orient = 0, ruin = false},
  [Entities.CB_Camp23] = { orient = 0, ruin = false},
  [Entities.CB_Camp24] = { orient = 0, ruin = false},
  [Entities.PB_Alchemist1] = { orient = 0, ruin = false},
  [Entities.PB_Alchemist2] = { orient = 0, ruin = false},
  [Entities.PB_Archery1] = { orient = 0, ruin = false},
  [Entities.PB_Archery2] = { orient = 0, ruin = false},
  [Entities.PB_Bank1] = { orient = 0, ruin = false},
  [Entities.PB_Bank2] = { orient = 0, ruin = false},
  [Entities.PB_Barracks1] = { orient = 0, ruin = false},
  [Entities.PB_Barracks2] = { orient = 0, ruin = false},
  [Entities.PB_Beautification01] = { orient = 0, ruin = false},
  [Entities.PB_Beautification02] = { orient = 0, ruin = false},
  [Entities.PB_Beautification04] = { orient = 0, ruin = false},
  [Entities.PB_Beautification05] = { orient = 0, ruin = false},
  [Entities.PB_Beautification06] = { orient = 0, ruin = false},
  [Entities.PB_Beautification07] = { orient = 0, ruin = false},
  [Entities.PB_Beautification08] = { orient = 0, ruin = false},
  [Entities.PB_Beautification09] = { orient = 0, ruin = false},
  [Entities.PB_Beautification10] = { orient = 0, ruin = false},
  [Entities.PB_Beautification11] = { orient = 0, ruin = false},
  [Entities.PB_Beautification12] = { orient = 0, ruin = false},			
  [Entities.PB_Brickworks1] = { orient = 0, ruin = false},
  [Entities.PB_Brickworks2] = { orient = 0, ruin = false},
  [Entities.PB_Bridge1] = { orient = 0, ruin = false},
  [Entities.PB_Bridge2] = { orient = 0, ruin = false},
  [Entities.PB_Bridge3] = { orient = 0, ruin = false},
  [Entities.PB_Bridge4] = { orient = 0, ruin = false},
  [Entities.PB_DarkTower1] = { orient = 0, ruin = false},
  [Entities.PB_DarkTower2] = { orient = 0, ruin = false},
  [Entities.PB_DarkTower2_Ballista] = { orient = 0, ruin = false},
  [Entities.PB_DarkTower3] = { orient = 0, ruin = false},
  [Entities.PB_DarkTower3_Cannon] = { orient = 0, ruin = false},
  [Entities.PB_Farm1] = { orient = 0, ruin = false},
  [Entities.PB_Farm2] = { orient = 0, ruin = false},
  [Entities.PB_Farm3] = { orient = 0, ruin = false},
  [Entities.PB_GenericBridge] = { orient = 0, ruin = false},
  [Entities.PB_GenericMine] = { orient = 0, ruin = false},
  [Entities.PB_GunsmithWorkshop1] = { orient = 0, ruin = false},
  [Entities.PB_GunsmithWorkshop2] = { orient = 0, ruin = false},
  [Entities.PB_Headquarters1] = { orient = 0, ruin = false},
  [Entities.PB_Headquarters2] = { orient = 0, ruin = false},
  [Entities.PB_Headquarters3] = { orient = 0, ruin = false},
  [Entities.PB_Market1] = { orient = 0, ruin = false},
  [Entities.PB_Market2] = { orient = 0, ruin = false},			
  [Entities.PB_Monastery1] = { orient = 0, ruin = false},
  [Entities.PB_Monastery2] = { orient = 0, ruin = false},
  [Entities.PB_Monastery3] = { orient = 0, ruin = false},
  [Entities.PB_Outpost1] = { orient = 0, ruin = false},
  [Entities.PB_Outpost2] = { orient = 0, ruin = false},
  [Entities.PB_Outpost3] = { orient = 0, ruin = false},
  [Entities.PB_PowerPlant1] = { orient = 0, ruin = false},
  [Entities.PB_Monastery1] = { orient = 0, ruin = false},
  [Entities.PB_Monastery2] = { orient = 0, ruin = false},
  [Entities.PB_Monastery3] = { orient = 0, ruin = false},
  [Entities.PB_Outpost1] = { orient = 0, ruin = false},
  [Entities.PB_Outpost2] = { orient = 0, ruin = false},
  [Entities.PB_Outpost3] = { orient = 0, ruin = false},
  [Entities.PB_Sawmill1] = { orient = 0, ruin = false},
  [Entities.PB_Sawmill2] = { orient = 0, ruin = false},
  [Entities.PB_Stable1] = { orient = 0, ruin = false},
  [Entities.PB_Stable2] = { orient = 0, ruin = false},
  [Entities.PB_StoneMason1] = { orient = 0, ruin = false},
  [Entities.PB_StoneMason2] = { orient = 0, ruin = false},
  [Entities.PB_Tavern1] = { orient = 0, ruin = false},
  [Entities.PB_Tavern2] = { orient = 0, ruin = false},
  [Entities.PB_Tower1] = { orient = 0, ruin = false},
  [Entities.PB_Tower2] = { orient = 0, ruin = false},
  [Entities.PB_Tower2_Ballista] = { orient = 0, ruin = false},
  [Entities.PB_Tower3] = { orient = 0, ruin = false},
  [Entities.PB_Tower3_Cannon] = { orient = 0, ruin = false},
  [Entities.PB_University1] = { orient = 0, ruin = false},
  [Entities.PB_University2] = { orient = 0, ruin = false},
  [Entities.PB_WeatherTower1] = { orient = 0, ruin = false},
  [Entities.PB_Weathermachine] = { orient = 0, ruin = false},
  [Entities.PB_Weathermachine_Activated] = { orient = 0, ruin = false},
  [Entities.CB_MinerCamp1] = { orient = 0, ruin = false},
  [Entities.CB_MinerCamp2] = { orient = 90, ruin = false},
  [Entities.CB_MinerCamp3] = { orient = 90, ruin = false},
  [Entities.CB_MinerCamp4] = { orient = 0, ruin = false},
  [Entities.CB_MinerCamp5] = { orient = 0, ruin = false},
  [Entities.CB_MinerCamp6] = { orient = 0, ruin = false }
}