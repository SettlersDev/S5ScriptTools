--------------------------------------------------------------------
--					             Items to Find									          --
--------------------------------------------------------------------
--[[
  Dependencies: 
    heroinventory.lua
    
]]--
function InitItemsToFind()
  if not HeroInventory then
    assert(false, "ItemsToFind: HeroInventoryIsRequired")
  end
  ItemsToFind = {
    ItemList = {},
    LockLevel = {
      [1] = "leicht",
      [2] = Umlaute("mittelmäßig"),
      [3] = "knifflig",
      [4] = "aufwendig",
      [5] = "schwer",
      [6] = "sehr schwer",
      [7] = "meisterhaft",
      [8] = Umlaute("unmöglich")
    },
    Picklock = {
      Name = "Dietrich",
      NameColor = gvCol.hellblau2,
      InfoText  = "Das Werkzeug eines jeden Diebes. @cr Es wird euch sicher noch nützlich sein",	
      Icon  = "MultiSelectionSource_thief",
      Sellable = true,
      Costs = {Gold = 50},
      Inflation = 1.01,
      MarketFactor = 1
    },
  }
  ------------------------------------------------------------------------
  ItemsToFind.Show = function(_itemIndex)
    XGUIEng.ShowWidget("ItemsToFind", 1)
    local itemToFind = ItemsToFind.ItemList[_itemIndex]
    XGUIEng.SetText("ItemsToFind_PickUpText", "@center " .. itemToFind.Type)
    if ItemsToFind.ItemList[_itemIndex].Locked then
      XGUIEng.ShowWidget("ItemsToFind_LockedButton", 1)
      XGUIEng.ShowWidget("ItemsToFind_ItemButton", 0)
      local amount = GetItemAmount(HeroInventory.ActiveHero, ItemsToFind.Picklock)
      XGUIEng.SetText("ItemsToFind_LockedTooltip_PicklockAmount", "@center " .. amount)
      XGUIEng.SetText("ItemsToFind_LockedTooltip_LockLevel", "@center " .. ItemsToFind.LockLevel[itemToFind.Locked])
    else
      local item = itemToFind.Item
      HeroInventory.SetTexture("ItemsToFind_ItemButton", item)
      XGUIEng.ShowWidget("ItemsToFind_LockedButton", 0)
      XGUIEng.ShowWidget("ItemsToFind_ItemButton", 1)
      XGUIEng.SetText("ItemsToFind_ItemTooltip_Name", item.NameColor .. " @center " .. item.Name)
      XGUIEng.SetText("ItemsToFind_ItemTooltip_Amount", " @center " .. itemToFind.Amount)
    end
    ItemsToFind.ActiveItem = _itemIndex
  end
  ------------------------------------------------------------------------
  ItemsToFind.Hide = function()
    XGUIEng.ShowWidget("ItemsToFind",  0)
  end
  ------------------------------------------------------------------------
  AddSeveralItemsToFind = function(_itemTable, _pos, _type, _entity, _lockLevel, _callback)
    local callback, locklevel, entity
    for i = 1, table.getn(_itemTable) do
      if i == 1 then
        callback = _callback
        entity = _entity
      elseif i == table.getn(_itemTable) then
        locklevel = _lockLevel
      else
        callback = false
        entity = false
      end
      AddItemToFind(_itemTable[i].Item, _itemTable[i].Amount, _pos, _type, entity, locklevel, callback)
    end
  end
  ------------------------------------------------------------------------
  AddItemToFind = function(_item, _amount, _pos, _type, _entity, _lockLevel, _callback)
    newItemToFind = {}
    assert(type(_item) == "table", "ItemToFind: item is not defined correctly")
    newItemToFind.Item 		= _item
    assert(type(_amount) == "number", "ItemToFind: amount has to be a number")
    newItemToFind.Amount 	= _amount
    if type(_pos) == "table" then
      newItemToFind.Position 		= _pos
    else 
      newItemToFind.Position 		= GetPosition(_pos)
    end
    if _entity then
      newItemToFind.ItemEntity = CreateEntity(1, _entity, newItemToFind.Position)
    end
    newItemToFind.Type = _type or "Aufnehmen"
    newItemToFind.BuildBlockId = CreateEntity(1, Entities.XD_BuildBlockScriptEntity, newItemToFind.Position)
    newItemToFind.MarkerId = CreateEntity(1, Entities.XD_Sparkles, newItemToFind.Position)
    newItemToFind.Locked = (_lockLevel or false)
    newItemToFind.Callback = _callback
    table.insert(ItemsToFind.ItemList, newItemToFind) 
  end
  ------------------------------------------------------------------------
  ItemsToFind.ModifyGUI = function()
    ItemsToFind.SelectionChanged = GameCallback_GUI_SelectionChanged
    GameCallback_GUI_SelectionChanged = function()
      ItemsToFind.SelectionChanged()
      local eID = GUI.GetSelectedEntity()
      local eName = GetEntityName(eID)
      if HeroInventory.Heroes[eName] then
        ItemsToFind.ControlJob = StartSimpleHiResJob("ItemsToFind_ControlJob")
      else
        EndJob(ItemsToFind.ControlJob)
        ItemsToFind.Hide()
      end
    end
  end
  ------------------------------------------------------------------------
  ItemsToFind_ControlJob = function()
    for i = table.getn(ItemsToFind.ItemList), 1, -1	do 
      local x, y = Camera.ScrollGetLookAt()
      local camPos = {X = x, Y = y}
      local Condition1 = GetDistance(HeroInventory.ActiveHero, ItemsToFind.ItemList[i].Position) < 400
      local Condition2 = GetDistance(camPos, ItemsToFind.ItemList[i].Position) < 1000
      if Condition1 and Condition2 then
        ItemsToFind.Show(i)
        return
      end
    end
    ItemsToFind.Hide()
  end
  ------------------------------------------------------------------------
  ItemsToFind_ItemButtonClicked = function()
    local itemToFind = ItemsToFind.ItemList[ItemsToFind.ActiveItem]
    if itemToFind then
      local item = itemToFind.Item
      AddItem(HeroInventory.ActiveHero, itemToFind.Item, itemToFind.Amount)
      DestroyEntity(itemToFind.MarkerId)
      DestroyEntity(itemToFind.ItemEntity)
      DestroyEntity(itemToFind.BuildBlockId)
      Message(itemToFind.Amount.."x "..item.NameColor .. " " .. item.Name .. COLOR0 .. " erhalten!")
      if itemToFind.Callback then
        itemToFind.Callback()
      end
      table.remove(ItemsToFind.ItemList, ItemsToFind.ActiveItem)
    end
  end
  ------------------------------------------------------------------------
  ItemsToFind_LockedButtonClicked = function()
    if HasItem(HeroInventory.ActiveHero, ItemsToFind.Picklock) then
      local uppermax = math.floor(1.5^ItemsToFind.ItemList[ItemsToFind.ActiveItem].Locked)
      local chance = GetRandom(1, uppermax)
      if chance == 1 then
        ItemsToFind.ItemList[ItemsToFind.ActiveItem].Locked = false
        Message("Schloss erfolgreich geknackt!")
        XGUIEng.ShowWidget("ItemsToFind_ItemTooltip", 1)
      else
        RemoveItem(HeroInventory.ActiveHero, ItemsToFind.Picklock, 1)
        Message("Dietrich abgebrochen")
      end
    else
      Message("Ihr habt keinen Dietrich!")
    end
  end
  ItemsToFind.ModifyGUI()
end