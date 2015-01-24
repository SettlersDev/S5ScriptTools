---------------------------------------------------------------------------------------
--                                    Bionomics                                      --
---------------------------------------------------------------------------------------
--[[
  Dependencies: 
    none

]]--
function SetupRecoverableTreeStumps(_ressAmount)
  gvTreeStumps = {
    stumps = {},
    ressourceAmount = _ressAmount
  }
  Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_DESTROYED, "", "TreeStumpCreation", 1)
end

function TreeStumpCreation()
  local eId = Event.GetEntityID()
  local eType = Logic.GetEntityType(eId)
  if (eType == Entities.XD_ResourceTree) and (not gvTreeStumps.stumps[eId]) then
    gvTreeStumps.JobID = gvTreeStumps.JobID or StartSimpleJob("ControlTreeStumps")
    local pos = GetPosition(eId)
    local stumps, treeStump = Logic.GetEntitiesInArea(Entities.XD_TreeStump1, pos.X, pos.Y, 5, 1)
    if not treeStump then
      return
    end
    local ressourceEntity = Logic.CreateEntity(Entities.XD_ResourceTree, pos.X, pos.Y)
    Logic.SetResourceDoodadGoodAmount(ressourceEntity, 50 + gvTreeStumps.ressourceAmount)
    Logic.SetModelAndAnimSet(ressourceEntity, Models.XD_Plant4)
    gvTreeStumps.stumps[ressourceEntity] = treeStump
  end
end
 
function ControlTreeStumps()
  local stumpCnt = 0
  for ressourceEntity, treeStump in pairs(gvTreeStumps.stumps) do
    if IsExisting(treeStump) then
      if Logic.GetResourceDoodadGoodAmount(ressourceEntity) <= 50 then
        local pos = GetPosition(ressourceEntity)
        DestroyEntity(ressourceEntity)
        DestroyEntity(treeStump)
        Logic.CreateEffect(GGL_Effects.FXBuildingSmoke, pos.X, pos.Y, 0)
        gvTreeStumps.stumps[ressourceEntity] = nil
      else
        stumpCnt = stumpCnt + 1
      end
    else
      DestroyEntity(ressourceEntity)
      gvTreeStumps.stumps[ressourceEntity] = nil
    end
  end 
  if stumpCnt == 0 then
    gvTreeStumps.JobID = nil
    return true
  end
end
-------------------------------------------------------------