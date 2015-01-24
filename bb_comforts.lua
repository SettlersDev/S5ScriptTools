---------------------------------------------------------------------------------------
--                                   My Functions                                    --
---------------------------------------------------------------------------------------
--[[
  Dependencies: 
    none

]]--

function GetCirclePositions(_position, _distance, _amount)
  local pos = GetPosition(_position)
  local circlePositions = {}
  local angle = 0
  local angleStep = 2 * math.pi / _amount
  for i = 1, _amount do
    angle = angle + angleStep
    circlePositions[i] = { X = math.cos(angle) * _distance, Y = math.sin(angle) * _distance }
  end
  return circlePositions
end

function AddOnSaveGameLoaded(_function)
  if not OnSaveGameLoaded then
    InitOnSaveGameLoaded()
  end
  table.insert(OnSaveGameLoaded.Functions, _function)
end

function InitOnSaveGameLoaded()
  OnSaveGameLoaded = OnSaveGameLoaded or {
    Functions = {},
    OrigFunction = Mission_OnSaveGameLoaded
  }
  Mission_OnSaveGameLoaded = function()
    OnSaveGameLoaded.OrigFunction()
    for i = 1, table.getn(OnSaveGameLoaded.Functions) do
      OnSaveGameLoaded.Functions[i]()
    end
  end
end

function MoveNear(_entity, _destination, _distance, _callback)
  Move(_entity, _destination)
  SetupExpedition{
    EntityName = GetEntityName(_entity),
    TargetName = GetEntityName(_destination),
    Distance = _distance,
    Callback = function(_expedition) StopFig(_expedition.EntityName); _expedition.StopCallback(); end,
    StopCallback = _callback or function() end
  }
end

function MoveAndLookAt(_entity, _destination, _lookAt)
  Move(_entity, _destination)
  SetupExpedition{
    EntityName = GetEntityName(_entity),
    TargetName = GetEntityName(_destination),
    Distance = 50,
    Callback = function(_expedition) LookAt(_expedition.EntityName, _expedition.LookAt); end,
    LookAt = _lookAt
  }
end

function MoveAndDestroy(_entity, _destination)
  Move(_entity, _destination)
  SetupExpedition{
    EntityName = GetEntityName(_entity),
    TargetName = GetEntityName(_destination),
    Distance = 50,
    Callback = function(_expedition) DestroyEntity(_expedition.EntityName); end
  }
end

function SetDisplayNameOfEntity(_entity, _displayName)
  if not displayNameEntities then
    GUIUpdate_SelectionName_OrigSelect = GUIUpdate_SelectionName
    GUIUpdate_SelectionName = function()
      GUIUpdate_SelectionName_OrigSelect()
      local eId = GUI.GetSelectedEntity()
      local eName = GetEntityName(eId)
      if displayNameEntities[eName] then
        XGUIEng.SetText("Selection_Name", Umlaute(displayNameEntities[eName]))
      end
    end
    displayNameEntities = {}
  end
  assert(type(_displayName) == "string", "DisplayNames: display name is no string")
  local eId = GetEntityId(_entity)
  if eId == 0 then
    return false
  end
  local eName = GetEntityName(eId)
  displayNameEntities[eName] = _displayName
end

function CreateName()
  globalNameCounter = (globalNameCounter or 0) + 1
  return "NewName" .. globalNameCounter
end

function GetRandomPos(_position, _distance)
  local pos = _position
  if type(_position) ~= "table" then
    pos = GetPosition(_position)
  end
  local rndmDist = GetRandom(0, _distance)
  local rndmAngle = GetRandom(0, 360)
  local sinus = math.sin(rndmAngle)
  local cosinus = math.cos(rndmAngle)
  local newPos = {
    X = pos.X + sinus * rndmDist,
    Y = pos.Y + cosinus * rndmDist
  }
  return newPos
end


------------------------------------------------------------------------
function ExecuteNextTick(_func)
  gFuncToExecuteAfterNextTick = _func
  gvTickCounterForExecuteAfterNextTick = 0
  StartSimpleHiResJob("NextTickJob")
end

function NextTickJob()
  gvTickCounterForExecuteAfterNextTick = gvTickCounterForExecuteAfterNextTick + 1 -- ^^
  if gvTickCounterForExecuteAfterNextTick == 5 then
    gFuncToExecuteAfterNextTick()
    return true
  end
end

function CreatePulse(_pos, _type, _static)
  globalPulseList = globalPulseList or {}
  globalPulseCounter = (globalPulseCounter or 0) + 1
  local pos = GetPosition(_pos)
  if _static then
    GUI.CreateMinimapMarker(pos.X, pos.Y, _type)
  else
    GUI.CreateMinimapPulse(pos.X, pos.Y, _type)
  end
  globalPulseList[globalPulseCounter] = pos
  return globalPulseCounter
end

function DestroyPulse(_id)
  if _id then
    local pos = globalPulseList[_id]
    GUI.DestroyMinimapPulse(pos.X, pos.Y)
  end
end

function MoveDirectly(entityId, position)
  if (not entityId) or (type(position) ~= "table") then
    return
  end
  Logic.MoveSettler(entityId, position.X, position.Y)
end

function QuestDone(id, _type)
  Logic.SetQuestType(1, id, _type)
end

function AddQuest(id, _type, title, text)
  Logic.AddQuest(1, id, _type, Umlaute(title), Umlaute(text))
end

--------------------------------------------------------------------
--					Entity rotieren									
--------------------------------------------------------------------
function RotateEntity(entity, rotation)
	local eID 
	if type(entity) == "string" then
		eID = GetEntityId(entity)
	else
		eID = entity
	end
	Logic.RotateEntity(eID, rotation)
end
--------------------------------------------------------------------
--				Entity mit Rotation erstellen									
--------------------------------------------------------------------
-- für Häuser usw.
function CreateRotatedEntity(pID, pos, entity, rotation)
	local ePos = GetPosition(pos)
	Logic.CreateEntity(entity, ePos.X, ePos.Y, rotation, pID)
end
--------------------------------------------------------------------
--					Kamera zu Position bewegen									
--------------------------------------------------------------------
function CameraSetLookAt(_entityName)
	local ePos = GetPosition(_entityName)
	Camera.ScrollSetLookAt(ePos.X, ePos.Y)
end
--------------------------------------------------------------------
--					Bwusstlose Helden Abfrage									
--------------------------------------------------------------------
-- funkioniert aufgrund eines Bugs?? Wenn Helden bewusstlos sind gelten sie für die Abfrage "IsDead" als tot!
function AreHeroesInAreaDead(position, range)
	local pos = GetPosition(position)
	for i = 1, 8 do
		local heroId = {Logic.GetPlayerEntitiesInArea(1, 0, pos.X, pos.Y, range, 1)}
		if heroId == nil then
			return true
		else
			if IsDead(heroId) then
				return true
			else
				return false
			end
		end
	end
end

--------------------------------------------------------------------
--						Steinbombe XD							
--------------------------------------------------------------------
-- mithilfe dieser Funktion lassen sich große Steine sehr schön ZERBOMBEN!!!
function RockBomb(name, smallstones)
	local delta = 100	--abstand der explosionen
	local side = 2  --explosionen in jede richting
	
	local pos = GetPosition(name)
	local exPos = { X = pos.X - (delta*(side-1))/2, Y = pos.Y - (delta*(side))/2 }
	-- mehrere Explosionen in einem Raster legen
	for x = 1, side do
		for y = 1, side do
			Logic.CreateEffect(GGL_Effects.FXExplosionPilgrim, exPos.X, exPos.Y, 3)
			exPos.Y = exPos.Y + delta
		end
		
		exPos.Y = pos.Y
		exPos.X = exPos.X + delta
	end
	-- Stein "removen"
	DestroyEntity(name)
	-- Effekt yay :D
	Logic.CreateEffect(GGL_Effects.FXBuildingSmokeLarge, pos.X, pos.Y, 3)
	-- meherer kleine und große Steine neben die Explosion legen
	if smallstones then
    for i = 1, 4 do
      CreateEntity(3, Entities.XD_RockMedium2, { X = pos.X + math.random(-500, 500), Y = pos.Y + math.random(-500, 500) })
    end
      
    for i = 1, 15 do
      CreateEntity(3, Entities.XD_RockMedium1, { X = pos.X + math.random(-700, 700), Y = pos.Y + math.random(-700, 700) })
    end
  end
end
--------------------------------------------------------------------
--					Tore öffnen und schließen							
--------------------------------------------------------------------
gateTypeNr = {
  [Entities.XD_WallStraightGate] = 1,
  [Entities.XD_WallStraightGate_Closed] = 1,
  [Entities.XD_PalisadeGate2] = 2,
  [Entities.XD_PalisadeGate1] = 2,
  [Entities.XD_DrawBridgeOpen1] = 3,
  [Entities.PB_DrawBridgeClosed1] = 3,
  [Entities.XD_DrawBridgeOpen2] = 4,
  [Entities.PB_DrawBridgeClosed2] = 4  
}
gates = {
  { 
    opened =  Entities.XD_WallStraightGate, 
    closed = Entities.XD_WallStraightGate_Closed 
  },
  
  { 
    opened = Entities.XD_PalisadeGate2,
    closed = Entities.XD_PalisadeGate1
  },
  
  { 
    opened = Entities.XD_DrawBridgeOpen1,
    closed = Entities.PB_DrawBridgeClosed1
  },
  
  { 
    opened = Entities.XD_DrawBridgeOpen2,
    closed = Entities.PB_DrawBridgeClosed2
  }
}
function GetGateTypeNr(gateType)
	for i = 1, table.getn(gates) do
		if gates[i].opened == gateType or gates[i].closed == gateType then
			return i
		end
	end
end

function OpenGate(name)
	local gateType = Logic.GetEntityType(GetEntityId(name))
	local newType = gates[gateTypeNr[gateType]].opened;
	SetEntityName(ReplaceEntity(name, newType), name)
end

function CloseGate(name)
	local gateType = Logic.GetEntityType(GetEntityId(name))
	local newType = gates[gateTypeNr[gateType]].closed;
	SetEntityName(ReplaceEntity(name, newType), name)
end

function ToggleGate(name)
	local gateType = Logic.GetEntityType(GetEntityId(name))
	local newType = 0
	for i = 1, table.getn(gates) do
		if gates[i].opened == gateType then
			newType = gates[i].closed
			break
		end
		if gates[i].closed == gateType then
			newType = gates[i].opened
			break
		end
	end
	SetEntityName(ReplaceEntity(name, newType), name)
end
--------------------------------------------------------------------
--					Move To mit Callback							
--------------------------------------------------------------------
-- Move Fig bewegt sich zu DestFig. Wenn kurz davor stoppen beide sehen sich an und func wird aufgerufen!
-- Muss in dieser Form in einen Job: return MoveTo(MoveFig, DestFig, func)

function MoveTo(MoveFig, DestFig, func)
	Move(MoveFig, DestFig)
	if IsNear(MoveFig, DestFig, 500) then
		StopFig(MoveFig)
		StopFig(DestFig)
		FaceEachOther(MoveFig, DestFig)
		func()
		return true
	end
end
--------------------------------------------------------------------
--					Einander ansehen							
--------------------------------------------------------------------
function FaceEachOther(figA, figB)
	LookAt(figA, figB)
	LookAt(figB, figA)
end
--------------------------------------------------------------------
--					Entity stoppen							
--------------------------------------------------------------------
function StopFig(figA)
	Move(figA, figA)
end
--------------------------------------------------------------------
--					Mittlere Position							
--------------------------------------------------------------------
-- für Briefing o. ä.
function GetMiddlePos(figA, figB)
	local posA = GetPosition(figA)
	local posB = GetPosition(figB)
	local pos = { }
	pos.X = (posA.X + posB.X) / 2;
	pos.Y = (posA.Y + posB.Y) / 2;
	return pos
end
--------------------------------------------------------------------
--					Distanz ermitteln							
--------------------------------------------------------------------
function GetDistance(_e1, _e2)
	local pos1, pos2
	if type(_e1) == "table" then
		pos1 = _e1	
	else
		pos1 = GetPosition(_e1)
	end
	if type(_e2) == "table" then
		pos2 = _e2
	else
		pos2 = GetPosition(_e2)
	end
	local distance = math.sqrt((pos1.X - pos2.X)^2 + (pos1.Y - pos2.Y)^2)
	return distance 
end

--------------------------------------------------------------------
--					Scriptingvalues							
--------------------------------------------------------------------
function ScaleSettler(_entity, _scale)
  local eId = GetEntityId(_entity)
  Logic.SetEntityScriptingValue(eId, -33, Float2Int(_scale))
  Logic.SetSpeedFactor(eId, _scale)
end

function SetScale(_entity, _scale)
  local eId = GetEntityId(_entity)
  Logic.SetEntityScriptingValue(eId, -33, Float2Int(_scale))
end

function GetMoveTo(_entity)
  local eId = GetEntityId(_entity)
  local x = Logic.GetEntityScriptingValue(eId, 8)
  local y = Logic.GetEntityScriptingValue(eId, 9)
  return {X = x, Y = y}
end

function GetLeader(_soldier)
  return Logic.GetEntityScriptingValue(_soldier, 69)
end

function Float2Int(fval)
    if(fval == 0) then
        return 0
    end

    local frac, exp = math.frexp(fval)
 
    local signSub = 0
    if(frac < 0) then
        frac = frac * -1
        signSub = 2147483648
    end

    local outVal = 0
    local bitVal = 4194304

    frac = frac * 4 - 2
    for i = 1, 23 do
        if(frac >= 1) then
            outVal = outVal + bitVal
            frac = frac - 1
        end
        if(frac == 0) then
            break
        end
        bitVal = bitVal / 2
        frac = frac * 2
    end
    if(frac >= 1) then
        outVal = outVal + 1
    end

    return outVal + (exp+126)*8388608 - signSub
end

function Int2Float(inum)
    if(inum == 0) then
        return 0
    end

    local sign = 1
    if(inum < 0) then
        inum = 2147483648 + inum
        sign = -1
    end

    local frac = math.mod(inum, 8388608)
    local exp = (inum-frac)/8388608 - 127
    local fraction = 1
    local fracVal = 0.5
    local bitVal = 4194304
    for i = 23, 1, -1 do
        if(frac - bitVal) > 0 then
            fraction = fraction + fracVal
            frac = frac - bitVal
        end
        bitVal = bitVal / 2
        fracVal = fracVal / 2
    end
    fraction = fraction + fracVal * frac * 2
    return math.ldexp(fraction, exp) * sign
end
