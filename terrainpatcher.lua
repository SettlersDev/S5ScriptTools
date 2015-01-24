--------------------------------------------------------------------
--					                Terrainpatcher					              --
--------------------------------------------------------------------
--[[
  Dependencies: 
    bb_comforts.lua
]]--
function InitTerrainPatching(_regionNames, _luaPath)
  terrainPatcher = {
    regionNames = _regionNames,
    luaPath = _luaPath or "data\\maps\\externalmap\\",
    SaveGameOrig = Framework.SaveGame,
  }
  entityControl = {
    doubleUsedEntities = {},
    highestEntityId = 65537
  }
  LoadAllRegions()
  Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_CREATED,"","EntityControl_EntityCreated",1)
  Logic.DestroyEntity(Logic.CreateEntity(Entities.XD_ScriptEntity, 2, 2, 0, 0))
  Framework.SaveGame = function(SaveGameName, Description)
    local transporter = {}
    setmetatable(transporter, patchRegions)
    patchRegions = nil
    collectgarbage()
    terrainPatcher.SaveGameOrig(SaveGameName, Description)
    patchRegions = getmetatable(transporter)
    transporter = nil
    collectgarbage()
  end
  AddOnSaveGameLoaded(LoadAllRegions)
end

function PatchRegion(_name)
  patchRegions[_name]()
end

function LoadAllRegions()
  patchRegions = {}
  for i = 1, table.getn(terrainPatcher.regionNames) do
    Script.Load(terrainPatcher.luaPath .. terrainPatcher.regionNames[i])
  end
end

function EntityControl_EntityCreated()
  local eId = Event.GetEntityID()
  if eId > 131072 then
    oldEId = (eId - math.floor(eId/65536)*65536) + 65536
    entityControl.doubleUsedEntities[oldEId] = eId
  else
    entityControl.highestEntityId = eId
  end
end

function RemoveEntitiesInRegion(posBoundaries)
  for i = 65536, entityControl.highestEntityId do
    local eId = i
    if entityControl.doubleUsedEntities[eId] then
      eId = entityControl.doubleUsedEntities[eId]
    end
    if IsInRectangle(eId, posBoundaries) then
      Logic.DestroyEntity(eId)
    end
  end
end

function IsInRectangle(eId, posBoundaries)
  local X, Y, Z = Logic.EntityGetPos(eId)
  if 
  X < posBoundaries.low.X or 
  X > posBoundaries.high.X or 
  Y < posBoundaries.low.Y or 
  Y > posBoundaries.high.Y then
    return false
  end
  return true
end

