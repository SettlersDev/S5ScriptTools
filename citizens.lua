---------------------------------------------------------------------------------------
--                                   Citizens                                        --
---------------------------------------------------------------------------------------
--[[
  Dependencies: 
    community_comforts.lua

]]--
function InitCitizens(_citizensPerPoint, _newNames)
	wpcList = {}
	citList = {}
  citizenNameCnt = 0
	local citizens = {
    { Entity = Entities.CU_AlchemistIdle }, 
    { Entity = Entities.CU_ChiefIdle }, 
    { Entity = Entities.CU_EngineerIdle }, 
    { Entity = Entities.CU_FarmerIdle }, 
    { Entity = Entities.CU_Major02Idle }, 
    { Entity = Entities.CU_MasterBuilder }, 
    { Entity = Entities.CU_Trader }, 
    { Entity = Entities.CU_Princess, Name = Umlaute("Bürgerin") }, 
    { Entity = Entities.CU_SmelterIdle }
	}
	local ent
	repeat 
		ent = { Logic.GetEntities( Entities.XD_RockTidelandGreen4, 9000)};
		for i=2, ent[1]+1 do
			local str = GetEntityName(ent[i]);
			if string.sub(str, 1, 3) == "wpc" then
				local pId = tonumber(string.sub(str, 4, 4))

				local thisNum = tonumber(string.sub(str, 6, 7))
				wpcList[thisNum] = { 
					nextWP = { },
					pos = GetPosition(ent[i])
				}
				
				local strPos = 8
				local strLen = string.len(str)
				repeat
					table.insert(wpcList[thisNum].nextWP, tonumber(string.sub(str, strPos+1, strPos+2)))
					strPos = strPos + 3
				until strPos >= strLen
				
				DestroyEntity(ent[i])
				for i = 1, _citizensPerPoint do
					local citizenType = GetRandom(1, table.getn(citizens))
					local eID = CreateEntity(pId, citizens[citizenType].Entity, wpcList[thisNum].pos)
					if _newNames then
            local eName = GetCitizenName()
            SetEntityName(eID, eName)
            _newNames[eName] = citizens[citizenType].Name or Umlaute("Bürger")
					end
					table.insert(citList, {eId = eID, lastWP = 0, nextWP = thisNum})
				end
			end
		end
	until ent[1] ~= 16
	
	StartSimpleJob("CitizensControlJob")
	
end

function GetCitizenName()
  citizenNameCnt = citizenNameCnt + 1
  return "citizen" .. citizenNameCnt
end

function CitizensControlJob()
	for i = 1, table.getn(citList) do
		if not Logic.IsEntityMoving(citList[i].eId) then
			if GetRandom(1, 2) == 1 then
				local nextWpId
				local nextOptions = table.getn(wpcList[citList[i].nextWP].nextWP)
				if nextOptions ~= 1 then
					repeat
						nextWpId = GetRandom(1, nextOptions)
					until wpcList[citList[i].nextWP].nextWP[nextWpId] ~= citList[i].lastWP
				else
					nextWpId = 1
				end
				citList[i].lastWP = citList[i].nextWP
				citList[i].nextWP = wpcList[citList[i].nextWP].nextWP[nextWpId]
				Logic.MoveSettler(citList[i].eId, wpcList[citList[i].nextWP].pos.X, wpcList[citList[i].nextWP].pos.Y)
			end
		end
	end
end