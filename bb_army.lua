---------------------------------------------------------------------------------------
--                                    bb Army                                        --
---------------------------------------------------------------------------------------
--[[
  Dependencies: 
    bb_comforts.lua

]]--
function Setup_bb_Armies()
	bb_Armies = {}
	StartSimpleJob("Control_bb_Armies")
	BATTLE_SIEGE = 1
	BATTLE_PATROL = 2
	BATTLE_DEFEND = 3
	bb_ArmyIdCounter = 0
    --[[testArmy = {
		types = {
			["PU_LeaderBow2"] = 2,
			["PU_LeaderCavalry1"] = 4, 
			["PU_LeaderCavalry2"] = 1,
			["PU_LeaderHeavyCavalry2"] = 5,
			["PV_Cannon4"] = 12
		},								-- in der Form: [Nummer des Typs] = Anzahl an Truppen,
		nameOfWp = "tWP",				-- Der Name der Waypoints, wird intern so fortgesetzt: tWP1, tWP2, tWP3   | Der Erste WP ist der Entstehungspunkt
		attackRadius = 3000,				-- Entities in diesem Radius werden angegriffen
		spawnGenerator = "drake",	-- Wenn dieses Gebäude zerstört ist wird nicht mehr gespawnt
		spawnTime = 10,				-- Zeit in Sekunden nach der tote Truppen neugespawnt werden
		pId = 2,
		attackType = BATTLE_SIEGE
	}
    bb_CreateArmy(testArmy)
	SetHostile(4, 2)]] -- example :O
	bb_GetArmyId = function() 
    bb_ArmyIdCounter = bb_ArmyIdCounter + 1
    return bb_ArmyIdCounter
  end
end

function bb_CreateArmy(_armyTable)
  if IsDead(_armyTable.spawnGenerator) then
    return
  else
    local id = bb_GetArmyId()
    local newArmy = {
      types = _armyTable.types or assert(false),
      attackRadius = _armyTable.attackRadius or 600,
      spawnGenerator = _armyTable.spawnGenerator or assert(false),
      spawnTime = _armyTable.spawnTime or 120,
      spawnTimeOrig = _armyTable.spawnTime or 60,
      pId = _armyTable.pId or assert(false, "bb_Armies: no player id given"),
      attackType = _armyTable.attackType or BATTLE_SIEGE,
      experience = _armyTable.experience or 0,
      numberOfSoldiers = _armyTable.numberOfSoldiers or 16,
      spawnPos = GetPosition(_armyTable.spawnPos),
      
    }
    newArmy.troopIds = {}
    newArmy.waypoints = {}
    if newArmy.attackType == BATTLE_DEFEND then
      newArmy.defendPos = GetPosition(_armyTable.defendPos)
      assert(newArmy.defendPos.X ~= 0, "bb_Armies: defendPos isn't valid")
      bb_Armies[id] = newArmy
    else
      bb_Armies[id] = newArmy
      bb_AddWaypointsToArmy(id, _armyTable.nameOfWp)
    end
    bb_SpawnTroopsOfArmy(id, true)
    return id
  end
end

function bb_SpawnTroopsOfArmy(_id, _firstTime)
  local armyTable = bb_Armies[_id]
  local spawnPos = armyTable.waypoints[1]
  local wpIndex = 2
  if armyTable.spawnPos.X ~= 0 then
    spawnPos = armyTable.spawnPos
    wpIndex = 1
  end
  if _firstTime then
    for leaderType, troopAmount in pairs(armyTable.types) do
      for i = 1, troopAmount do   
        local troopId = AI.Entity_CreateFormation(armyTable.pId, Entities[leaderType], 0, armyTable.numberOfSoldiers, spawnPos.X, spawnPos.Y, 0, 0, armyTable.experience, 0)
        local defendPos = armyTable.defendPos
        if armyTable.attackType == BATTLE_DEFEND then
          defendPos = GetRandomPos(armyTable.defendPos, 1000)
        end
        armyTable.troopIds[troopId] = {wpIndex = wpIndex, leaderType = Entities[leaderType], attackRadius = armyTable.attackRadius, defendPos = defendPos}
      end
    end
  else
    for id, troopInformation in pairs(armyTable.troopIds) do
      if IsDead(id) and not IsDead(armyTable.spawnGenerator) then
        local defendPos = armyTable.defendPos
        if armyTable.attackType == BATTLE_DEFEND then
          defendPos = GetRandomPos(armyTable.defendPos, 1000)
        end
        local troopId = AI.Entity_CreateFormation(armyTable.pId, troopInformation.leaderType, 0, armyTable.numberOfSoldiers, spawnPos.X, spawnPos.Y, 0, 0, armyTable.experience, 0)
        armyTable.troopIds[troopId] = {wpIndex = wpIndex, leaderType = troopInformation.leaderType, attackRadius = armyTable.attackRadius, defendPos = defendPos}
        armyTable.troopIds[id] = nil
      end
    end
  end
end

function bb_SetSpawnPosOfArmy(_id, _spawnPos)
  if bb_Armies[_id] then
    bb_Armies[_id].spawnPos = GetPosition(_spawnPos)
    return true
  end
  return false
end

function bb_ChangeArmyAttackType(_id, _attackType, _defendPos)
  if bb_Armies[_id] then
    if _attackType == BATTLE_DEFEND then
      bb_Armies[_id].defendPos = GetPosition(_defendPos)
      for id, troopInformation in pairs(bb_Armies[_id].troopIds) do 
        troopInformation.defendPos = GetRandomPos(bb_Armies[_id].defendPos, 1000)
      end
    end
    for id, troopInformation in pairs(bb_Armies[_id].troopIds) do 
      troopInformation.stopMovement = false
      troopInformation.wpIndex = 1
    end
    bb_Armies[_id].attackType = _attackType
    return true
  end
  return false
end

function bb_SetWaypointsOfArmy(_id, _nameOfWp)
  if not bb_Armies[_id] then
    return false
  end
  bb_Armies[_id].waypoints = nil
  bb_Armies[_id].waypoints = {}
  bb_AddWaypointsToArmy(_id, _nameOfWp)
  return true
end

function bb_AddWaypointsToArmy(_id, _nameOfWp)
  if not bb_Armies[_id] then
    return false
  end
  local nameOfWp
  if type(_nameOfWp) == "string" then
    nameOfWp = {_nameOfWp}
  elseif type(_nameOfWp) == "table" then
    nameOfWp = _nameOfWp
  else
    assert(false, "bb_Armies: Waypoints to add aren't decleared correctly")
  end
  for i = 1, table.getn(nameOfWp) do
    local nameCount = 1
    local WPpos = GetPosition(nameOfWp[i]..nameCount)
    while WPpos.X ~= 0 do
      table.insert(bb_Armies[_id].waypoints, WPpos)
      CreateEntity(1, Entities.XD_BuildBlockScriptEntity, WPpos)
      nameCount = nameCount + 1
      WPpos = GetPosition(nameOfWp[i]..nameCount)
    end
  end
  return true
end

function bb_DestroyArmy(_id, _killAll)
  if not bb_Armies[_id] then
    return false
  end
  bb_Armies[_id].spawnGenerator = nil
  if _killAll then
    for id, troopInformation in pairs(bb_Armies[_id].troopIds) do
      DestroyEntity(id)
    end
  end
  return true
end

function Control_bb_Armies()
	for armyId, armyTable in pairs(bb_Armies) do
		-- cntrol movement and attacking
		for id, troopInformation in pairs(armyTable.troopIds) do
			if not IsDead(id) then	
				local troopPos = GetPosition(id)
				-- attack if enemy is in range
				inBattle = false
				local task = Logic.GetCurrentTaskList(id)
				if task then
          if string.find(task, "BATTLE") then
            inBattle = true
          end
        end			
				local nearestEnemy = GetNearestEnemy(armyTable.pId, id, armyTable.attackRadius)	
				if nearestEnemy and (not inBattle) then
					Attack(id, nearestEnemy)
				-- move to next WP
				elseif (not Logic.IsEntityMoving(id)) and (not inBattle) then		
          if armyTable.attackType == BATTLE_DEFEND then
            if GetDistance(id, troopInformation.defendPos) > 1000 then
              MoveDirectly(id, troopInformation.defendPos)
            else
              local nextEnemy = GetNearestEnemy(armyTable.pId, id, Logic.WorldGetSize()/2)
              if nextEnemy then
                LookAt(id, nextEnemy)
              end
            end
          elseif not troopInformation.stopMovement then
            if GetDistance(id, armyTable.waypoints[troopInformation.wpIndex]) < 500 then
              troopInformation.wpIndex = troopInformation.wpIndex + 1
              if not armyTable.waypoints[troopInformation.wpIndex] then
                if armyTable.attackType == BATTLE_SIEGE then
                  troopInformation.stopMovement = true
                  troopInformation.attackRadius = 20000
                  troopInformation.wpIndex = table.getn(armyTable.waypoints)
                elseif armyTable.attackType == BATTLE_PATROL then
                  troopInformation.wpIndex = 1
                end
              end
            end
            MoveDirectly(id, armyTable.waypoints[troopInformation.wpIndex])
          end
				end
			end
		end
		-- respawn dead troops if spawnTime is over
		armyTable.spawnTime = armyTable.spawnTime - 1
		if armyTable.spawnTime == 0 then
      bb_SpawnTroopsOfArmy(armyId)
			armyTable.spawnTime = armyTable.spawnTimeOrig
		end
		-- check if spawngenerator is still alive
		-- else remove army from table if no troop is alive
		if IsDead(armyTable.spawnGenerator) then
			local deadTroops = 0
			local allTroops = 0
			for id, troopInformation in pairs(armyTable.troopIds) do
				if IsDead(id) then
					deadTroops = deadTroops + 1
				end
				allTroops = allTroops + 1
			end
			if allTroops == deadTroops then
				bb_Armies[armyId] = nil
			end
		end	
	end
end

categoryImportance = {
  [EntityCategories.SplashDamage] = 0.1,
  [EntityCategories.MilitaryBuilding] = 0.2,
  [EntityCategories.Hero] = 0.5,
  [EntityCategories.Headquarters] = 0.8,
  [EntityCategories.VillageCenter] = 1,
  [EntityCategories.LongRange] = 1,		
  [EntityCategories.Melee] = 1,
  [EntityCategories.Residence] = 2,	
  [EntityCategories.Serf] = 1,	
  [EntityCategories.Worker] = 2,
  [EntityCategories.Workplace] = 2,
  
  [EntityCategories.Wall] = -1,
  [EntityCategories.Bridge] = -1
}

function CreateMilitaryImportance()
	militaryImportance = { [0] = -1 }
	for entType, entNumber in pairs(Entities) do
		for catNumber, catImportance in pairs(categoryImportance) do
			if Logic.IsEntityTypeInCategory(entNumber, catNumber) == 1 then
				militaryImportance[entNumber] = catImportance
			end
		end
		if not militaryImportance[entNumber] then
			militaryImportance[entNumber] = -1
		end
	end
end

function CheckImportanceConflicts()
	local militaryImportanceCheck = {}
	for entType, entNumber in pairs(Entities) do
		for catNumber, catImportance in pairs(categoryImportance) do
			if Logic.IsEntityTypeInCategory(entNumber, catNumber) == 1 then
				if not militaryImportanceCheck[entNumber] then
					militaryImportanceCheck[entNumber] = catNumber
				else
					Message("CONFLICT!!: ".. catNumber.." | ".. militaryImportanceCheck[entNumber])
				end
			end
		end
	end
end

CreateMilitaryImportance()