---------------------------------------------------------------------------------------
--                                    DROPS                                          --
---------------------------------------------------------------------------------------
--[[
  Dependencies: 
    heroinventory.lua
    itemstofind.lua

  Example:
  _items = {
    {item = itemTable, amount = 5},
    {item = itemTable2, amount = 2}
  }
]]--
function AddDropToEntity(_entity, _items, _dropEntity, _pickCallback)
  if not drops then
    drops = {}
    drops.Trigger = Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_DESTROYED,"","Drops_EntityDestroyed",1)
  end
  local eName = GetEntityName(_entity)
  _items.dropEntity = _dropEntity
  _items.pickCallback = _pickCallback
  drops[eName] = _items
  if Logic.IsHero(GetEntityId(_entity)) == 1 then
    SetupDestroy{
      Target = eName,
      Callback = function() CreateDroppedItem(eName, GetPosition(eName)); end
    }
  end
end

function Drops_EntityDestroyed()
  local eID = Event.GetEntityID()
  local eName = GetEntityName(eID)
  if drops[eName] then
    local pos = GetPosition(eID)
    CreateDroppedItem(eName, pos)
    drops[eName] = nil
  end
end

function CreateDroppedItem(_eName, _pos)
  local itemTable = drops[_eName]
  for i = 1, table.getn(itemTable) do
    AddItemToFind(itemTable[i].Item, itemTable[i].Amount, _pos, nil, itemTable.dropEntity, nil, itemTable.pickCallback)
    if i == 1 then
      itemTable.pickCallback = nil
    end
  end
end
    