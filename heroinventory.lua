--------------------------------------------------------------------
--                HeroInventory Reloaded                          --
--------------------------------------------------------------------
--[[
  Dependencies: 
    community_comforts.lua
    bb_comforts.lua
    s5hook.lua
    modifiedgui.xml
  
]]--
HeroInventory = {}
NotEnoughSounds = {
  ["Gold"] = "VoicesMentor_INFO_NotEnoughGold_rnd_01",
  ["Clay"] = "VoicesMentor_INFO_NotEnoughClay_rnd_01",
  ["Wood"] = "VoicesMentor_INFO_NotEnoughWood_rnd_01",
  ["Iron"] = "VoicesMentor_INFO_NotEnoughIron_rnd_01",
  ["Stone"] = "VoicesMentor_INFO_NotEnoughStone_rnd_01",
  ["Sulfur"] = "VoicesMentor_INFO_NotEnoughSulfur_rnd_01"
}
ResourceNames = {"Gold", "Clay", "Wood", "Stone", "Iron", "Sulfur"}
EquipType = {
  Necklace = 1,
  RingRight = 2,
  RingLeft = 3,
  Belt = 4,
  Feet = 5,
  Breast = 6,
  RightHand = 7,
  LeftHand = 8,
  Head = 9, 
  Special = 20,
  OneHanded = 21,
  TwoHanded = 22,
  Ring = 23,
}
BlockUseableItemsType = {
  This = 1,
  Same = 2,
  All = 3,
}
EquipItemSlots = {
  [1] = { Name = "Hals", Button = "Inventory_EquipButton_Necklace" },
  [2] = { Name = "Rechter Ringfinger", Button = "Inventory_EquipButton_RingRight" },
  [3] = { Name = "Linker Ringfinger", Button = "Inventory_EquipButton_RingLeft" },
  [4] = { Name = "Taille", Button = "Inventory_EquipButton_Belt" },
  [5] = { Name = "Füße", Button = "Inventory_EquipButton_Feet" },
  [6] = { Name = "Brust", Button = "Inventory_EquipButton_Breast" },
  [7] = { Name = "Rechte Hand", Button = "Inventory_EquipButton_RightHand" },
  [8] = { Name = "Linke Hand", Button = "Inventory_EquipButton_LeftHand" },
  [9] = { Name = "Kopf", Button = "Inventory_EquipButton_Head" }
}

function InitHeroInventory(_itemTable, _defaultIconPath)
  HeroInventory.SampleItem = {
    Name = "SampleItem",
    NameColor = "@color:155,155,155", 
    InfoText = "This item is an example",
    Icon = "ring3",
    UseExternPath = true,
    --IconColor = {255, 255, 255, 255},
    Useable = true,
    Equipable = true,
    QuestItem = true,
    EquipType = EquipType.Belt,
    AddCallback = function(_hero) Message("add"); end,
    RemoveCallback = function(_hero) Message("remove"); end,
    EquipCondition = function(_hero) return true; end,
    EquipCallback = function(_hero) Message("equip"); end,
    UnequipCallback = function(_hero) Message("unequip"); end,
    UseCondition = function(_hero) return true; end,
    UseCallback = function(_hero) Message("use"); end,
    BlockSame = true,
    Cooldown = 5,
    PreperationTime = 5,
    Unswapable = true,
    Sellable = true,
    Costs = { Gold = 6, Clay = 5, Wood = 4, Stone = 3, Iron = 2, Sulfur = 1 },
    Inflation = 1.05,
    MarketFactor = 1
  }
  
  for itemName, item in pairs(_itemTable) do
    if item.Inflation then 
      item.MarketFactor = 1
    end
  end
  HeroInventory.Items = _itemTable
  HeroInventory.IconPath = _defaultIconPath
  HeroInventory.Active = false
  HeroInventory.Heroes = {}
  HeroInventory.Traders = {}
  HeroInventory.SwitchModeActive = false
  HeroInventory.InitGUIModifications()
  HeroInventory.ResetCostWidgets()
  HeroInventory.Items = {}
  HeroInventory.EquipSlots = 9
  HeroInventory.IsSomeoneTalking = 0
  HeroInventory.InitKeyBindings()
  
  AddOnSaveGameLoaded(HeroInventory.InitKeyBindings)
end
--------------------------------------------------------------------
-- Public Functions & Comforts
--------------------------------------------------------------------
function CreateItemTrader(_name, _briefing, _voice)
	return CreateHeroInventory(_name, _briefing, _voice, true)
end
--------------------------------------------------------------------
function CreateHeroInventory(_hero, _displayName, _voice, _createTrader)
	_createTrader = _createTrader or false
	assert(type(_hero) == "string", "HeroInventory: Entity must be defined per name")
	
	local properties
	if not _createTrader then
    HeroInventory.Heroes[_hero] = {}
    properties = HeroInventory.Heroes[_hero];
    properties.DisplayName = _displayName
  else
    HeroInventory.Traders[_hero] = {}
    properties = HeroInventory.Traders[_hero];
		assert(type(_displayName) == "table", "HeroInventory: Trader has no briefing")
		properties.TraderBriefing = _displayName
		EnableNpcMarker(GetEntityId(_hero))
		if JobIsRunning("HeroInventory_TraderControl") ~= 1 then
			StartSimpleJob("HeroInventory_TraderControl")
		end
  end
	properties.Items = {}
	properties.HeroIsTalking = false
	properties.EquipedItems = {}
	properties.QuickAccessItems = {}
	properties.CooldowningItems = {}
	properties.IsTrader = _createTrader
	properties.ScrollValue = 0
	properties.SwitchMode = false
	properties.Voice = _voice or "VoicesHero1_HERO1_NO_rnd_01"
end

function RemoveHeroInventory(_name)
	assert(type(_name) == "string", "HeroInventory: name is not valid")
	HeroInventory.Heroes[_name] = nil
	HeroInventory.HideInventory()
end

function AddItem(_hero, _item, _amount)
  assert(type(_hero) == "string", "HeroInventory: name is not valid")
  local heroInv = HeroInventory.Heroes[_hero] or HeroInventory.Traders[_hero]
  local itemCollection = heroInv.Items
  local index, itemProperties = HeroInventory.GetItem(_hero, _item)
  if itemProperties then
    itemProperties.Amount = itemProperties.Amount + _amount
    return index
  else
    local newItem = {
      Amount = _amount, 
      Item = _item,
      Cooldown = 0,
      PreperationTime = 0
    }
    table.insert(itemCollection, newItem)
    if _item.AddCallback then
      _item.AddCallback(_hero)
    end
    if HeroInventory.ActiveHero then
      HeroInventory.Design(HeroInventory.ActiveHero)
    end
    return table.getn(itemCollection)
  end
end

function RemoveItem(_hero, _item, _amount, _force)
  assert(type(_hero) == "string", "HeroInventory: name is not valid")
  local heroInv = HeroInventory.Heroes[_hero] or HeroInventory.Traders[_hero]
  local itemCollection = heroInv.Items
  local index, itemProperties = HeroInventory.GetItem(_hero, _item)
  if not index then
    if _force then
      for i = 1, _amount do
        local isEquiped, equipedItemindex = IsItemEquipped(_hero, _item)
        local isInQuickAccess, quickAccessItemIndex = IsItemInQuickAccess(_hero, _item)
        if isEquiped then
          HeroInventory.UnequipItem(_hero, equipedItemindex)
          RemoveItem(_hero, _item, 1)
        elseif isInQuickAccess then
          heroInv.QuickAccessItems[quickAccessItemIndex] = nil
          HeroInventory.RefreshQuickAccessSlots(_hero)
        end
      end
    else
      return false
    end
  else
    if _amount then
      itemProperties.Amount = itemProperties.Amount - _amount
      if itemProperties.Amount > 0 then
        return true
      end
    end
    if _item.RemoveCallback then
      _item.RemoveCallback(_hero)
    end
    table.remove(itemCollection, index)
    if HeroInventory.ActiveHero then
      HeroInventory.Design(HeroInventory.ActiveHero)
    end
  end
  return true
end

function GetItemAmount(_heroName, _item)
  local index, itemProperties = HeroInventory.GetItem(_heroName, _item)
  local amount = 0
  if index then
   amount = itemProperties.Amount
  end
  return amount
end

function HasItem(_heroName, _item)
  return GetItemAmount(_heroName, _item) > 0
end

function IsItemEquipped(_heroName, _item)
  local heroInv = HeroInventory.Heroes[_heroName]
  local equipedItems = heroInv.EquipedItems
  for i = 1, HeroInventory.EquipSlots do
    if equipedItems[i] then
      if equipedItems[i] == _item then
        return true, i
      end
    end
  end
  return false
end

function IsItemInQuickAccess(_heroName, _item)
  local heroInv = HeroInventory.Heroes[_heroName]
  local quickAccessItems = heroInv.QuickAccessItems
  for i = 1, 10 do
    if quickAccessItems[i] then
      if quickAccessItems[i].Item == _item then
        return true, i
      end
    end
  end
  return false
end

function IsItemCooldowning(_heroName, _item)
  local isInQuickAccess, index = IsItemInQuickAccess(_heroName, _item)
  if isInQuickAccess then
    if HeroInventory.Heroes[_heroName].QuickAccessItems[index].Cooldown ~= 0 then
      return true
    end
  end
  return false
end
--------------------------------------------------------------------
-- Initializing
--------------------------------------------------------------------
function HeroInventory.InitGUIModifications()
	HeroInventory.OrigExpelSettler = GUIAction_ExpelSettler
	GUIAction_ExpelSettler = function()
		local eID = GUI.GetSelectedEntity()
		local eName = GetEntityName(eID)
    if HeroInventory.Heroes[eName] then
      if not HeroInventory.Active then
        HeroInventory.ShowInventory(eName)
      else
        HeroInventory.HideInventory()
      end
      HeroInventory.Active = not HeroInventory.Active
      return
    end
		HeroInventory.OrigExpelSettler()
	end
	HeroInventory.SelectionChanged = GameCallback_GUI_SelectionChanged
	GameCallback_GUI_SelectionChanged = function()
		HeroInventory.SelectionChanged()
		HeroInventory.HideInventory()
		HeroInventory.Active = false
		local eID = GUI.GetSelectedEntity()
		local eName = GetEntityName(eID)
    if HeroInventory.Heroes[eName] then
      XGUIEng.ShowWidget("QuickAccessBar", 1)
      XGUIEng.TransferMaterials("Build_Blacksmith", "Command_Expel")
      XGUIEng.TransferMaterials("Build_Blacksmith", "ExpelSerf")
      XGUIEng.DisableButton("Command_Expel", 0)
      HeroInventory.ActiveHero = eName
      HeroInventory.RefreshQuickAccessSlots(eName)
      HeroInventory.UpdateCooldownView(eName)
    else
      HeroInventory.ActiveHero = nil
      XGUIEng.ShowWidget("QuickAccessBar", 0)
      XGUIEng.TransferMaterials("HeroInventory_PrototypeButton_Expel", "Command_Expel")
      XGUIEng.TransferMaterials("HeroInventory_PrototypeButton_Expel", "ExpelSerf")
    end	
	end
	HeroInventory.GUITooltip_NormalButton = GUITooltip_NormalButton
	GUITooltip_NormalButton = function(a, b)
		local eID = GUI.GetSelectedEntity()
		local eName = GetEntityName(eID)
    if (a == "MenuCommandsGeneric/expel") then
      if HeroInventory.Heroes[eName] then
				XGUIEng.SetText( gvGUI_WidgetID.TooltipBottomCosts, "" )
				XGUIEng.SetText( gvGUI_WidgetID.TooltipBottomText, "@color:176,176,176 Inventar @cr @color:255,255,255 Dieser Schalter öffnet das Inventar des Helden!")
				XGUIEng.SetText( gvGUI_WidgetID.TooltipBottomShortCut, "Taste: [I]")
			end
		else
      HeroInventory.GUITooltip_NormalButton(a, b)
    end
	end
end

function HeroInventory.ShowInventory(_heroName)
  XGUIEng.ShowWidget("HeroInventory", 1)
  Inventory_OwnInventoryButtonClicked()
  HeroInventory.Design(_heroName)
end

function HeroInventory.ShowOtherInventory()
  XGUIEng.ShowWidget("OtherInventory", 1)
  XGUIEng.ShowWidget("Inventory_Equipment", 0)  
  XGUIEng.ShowWidget("Inventory_Title_EquipmentTitle", 0)
  HeroInventory.Design(HeroInventory.ActiveHero)
end

function HeroInventory.HideInventory()
  XGUIEng.ShowWidget("HeroInventory", 0)
end

function HeroInventory.HideOtherInventory()
  XGUIEng.ShowWidget("OtherInventory", 0)
  XGUIEng.ShowWidget("Inventory_Equipment", 1)
  XGUIEng.ShowWidget("Inventory_Title_EquipmentTitle", 1)
end

function HeroInventory.InitKeyBindings()
  Input.KeyBindDown(Keys.D1, "HeroInventory.QuickAccess(1)", 2)
  Input.KeyBindDown(Keys.D2, "HeroInventory.QuickAccess(2)", 2)
  Input.KeyBindDown(Keys.D3, "HeroInventory.QuickAccess(3)", 2)
  Input.KeyBindDown(Keys.D4, "HeroInventory.QuickAccess(4)", 2)
  Input.KeyBindDown(Keys.D5, "HeroInventory.QuickAccess(5)", 2)
  Input.KeyBindDown(Keys.D6, "HeroInventory.QuickAccess(6)", 2)
  Input.KeyBindDown(Keys.D7, "HeroInventory.QuickAccess(7)", 2)
  Input.KeyBindDown(Keys.D8, "HeroInventory.QuickAccess(8)", 2)
  Input.KeyBindDown(Keys.D9, "HeroInventory.QuickAccess(9)", 2)
  Input.KeyBindDown(Keys.D0, "HeroInventory.QuickAccess(10)", 2)
  Input.KeyBindDown(Keys.I, "GUIAction_ExpelSettler()", 2)
end
--------------------------------------------------------------------
-- Refreshing
--------------------------------------------------------------------
function HeroInventory.RefreshItemCollection(_heroName, _widgetPrefix)
  local heroInv = HeroInventory.Heroes[_heroName] or HeroInventory.Traders[_heroName]
  local itemCollection = heroInv.Items
  local itemIndex = heroInv.ScrollValue * 12
  for i = 1, 12 do
    local itemProperties = itemCollection[itemIndex + i]
    local button = _widgetPrefix .. "_ItemButton" .. i
    if itemProperties then
      local item = itemProperties.Item
      HeroInventory.SetTexture(button, item)
    else
      XGUIEng.TransferMaterials("HeroInventory_PrototypeButton_Empty", button)
    end
  end
  if heroInv.ScrollValue == 0 then
    XGUIEng.DisableButton(_widgetPrefix .. "_ItemCollection_ButtonLeft", 1)
  else
    XGUIEng.DisableButton(_widgetPrefix .. "_ItemCollection_ButtonLeft", 0)
  end
  if table.getn(itemCollection) > heroInv.ScrollValue * 12 + 12 then
    XGUIEng.DisableButton(_widgetPrefix .. "_ItemCollection_ButtonRight", 0)
  else
    XGUIEng.DisableButton(_widgetPrefix .. "_ItemCollection_ButtonRight", 1)
  end
end

function HeroInventory.RefreshEquipedItems(_heroName)
  local heroInv = HeroInventory.Heroes[_heroName]
  local equipedItems = heroInv.EquipedItems
  for i = 1, HeroInventory.EquipSlots do
    local item = equipedItems[i]
    local button = EquipItemSlots[i].Button
    if item then
      HeroInventory.SetTexture(button, item)
    else
      XGUIEng.TransferMaterials("HeroInventory_PrototypeButton_Empty", button)
    end
  end
end

function HeroInventory.RefreshQuickAccessSlots(_heroName)
  local heroInv = HeroInventory.Heroes[_heroName]
  local quickAccessItems = heroInv.QuickAccessItems
  for i = 1, 10 do
    local itemProperties = heroInv.QuickAccessItems[i]
    local button = "QuickAccessBar_ItemButton" .. i
    if itemProperties then
      local item = itemProperties.Item
      HeroInventory.SetTexture(button, item)
    else
      XGUIEng.TransferMaterials("QuickAccessBar_PrototypeButton_Empty", button)
    end
  end
end

function HeroInventory.UpdateCooldownView(_heroName)
  local heroInv = HeroInventory.Heroes[_heroName]
  local quickAccessItems = heroInv.QuickAccessItems
  for i = 1, 10 do
    local progressbar = XGUIEng.GetWidgetID("QuickAccessBar_Progressbar" .. i)
    local button = XGUIEng.GetWidgetID("QuickAccessBar_ItemButton" .. i)
    local itemPropertiesMain = quickAccessItems[i]
    local cooldownMain = 0
    local cooldownMainMax = 0
    local perperationTimeMain = 0
    local perperationTimeMainMax = 0
    if itemPropertiesMain then
      for o = 1, 10 do
        local itemProperties = quickAccessItems[o]
        if itemProperties then
          if itemProperties.Cooldown > 0 or itemProperties.PreperationTime > 0 then
            local blockSame = itemProperties.Item.BlockSame or false
            if (o == i) or (blockSame and (itemProperties.Item == itemPropertiesMain.Item))then
              cooldownMain = cooldownMain + itemProperties.Cooldown
              cooldownMainMax = cooldownMainMax + (itemProperties.Item.Cooldown or 0)
              perperationTimeMain = perperationTimeMain + itemProperties.PreperationTime
              perperationTimeMainMax = perperationTimeMainMax + (itemProperties.Item.PreperationTime or 0)
            end
          end
        end
      end
    end
    if cooldownMain > 0 or perperationTimeMain > 0 then
      itemPropertiesMain.Blocked = true
      XGUIEng.ShowWidget(progressbar, 1)
      XGUIEng.DisableButton(button, 1)
      local progressbarFrame
      if perperationTimeMain > 0 then
        progressbarFrame = math.ceil((perperationTimeMain / (perperationTimeMainMax * 10)) * 56 ) + 1
        XGUIEng.SetMaterialColor(progressbar, 0, 163, 207, 13, 150)
      else
        progressbarFrame = math.ceil((1 - (cooldownMain / (cooldownMainMax * 10))) * 56 ) + 1
        XGUIEng.SetMaterialColor(progressbar, 0, 207, 13, 22, 150)
      end
      XGUIEng.SetMaterialTexture(progressbar, 0, "owngraphics/progressbar/progressbar" .. progressbarFrame .. ".png")
    else
      if itemPropertiesMain then
        itemPropertiesMain.Blocked = false
      end
      XGUIEng.DisableButton(button, 0)
      XGUIEng.ShowWidget(progressbar, 0)
    end
  end
end

function HeroInventory.Design(_heroName)
  HeroInventory.RefreshItemCollection(_heroName, "Inventory")
  if XGUIEng.IsWidgetShown("OtherInventory") == 1 then
    if HeroInventory.SwitchModeActive then
      HeroInventory.RefreshItemCollection(HeroInventory.NearestHero, "OtherInventory")
    else
      HeroInventory.RefreshItemCollection(HeroInventory.ActiveTrader, "OtherInventory")
    end
  else
    HeroInventory.RefreshEquipedItems(_heroName)
  end
  HeroInventory.RefreshQuickAccessSlots(_heroName)
  HeroInventory.UpdateCooldownView(_heroName)
end
--------------------------------------------------------------------
-- Button Callbacks
--------------------------------------------------------------------
function HeroInventory_Close()
  HeroInventory.Active = false
  HeroInventory.HideInventory()
end

function Inventory_ItemButtonClicked(_btnNr)
  local itemProperties = HeroInventory.GetItemToInventoryButton(_btnNr, HeroInventory.ActiveHero)
  if not itemProperties then
    return
  end
  local item = itemProperties.Item
  if HeroInventory.SwitchModeActive or HeroInventory.TradeModeActive then
    if HeroInventory.SwitchModeActive and (not item.Unswapable) then
      AddItem(HeroInventory.NearestHero, item, 1)
      RemoveItem(HeroInventory.ActiveHero, item, 1)
    elseif HeroInventory.TradeModeActive and item.Sellable then
      HeroInventory.TradeItem(HeroInventory.ActiveHero, HeroInventory.ActiveTrader, item, HeroInventory.TradeAmount)
    else
      HeroInventory.PlaySound(HeroInventory.Heroes[HeroInventory.ActiveHero].Voice, 128)
    end
  else
    if item.Useable or item.Equipable then
      HeroInventory.CurrentDragButton = { BtnNr = _btnNr, Item = item, ItemProperties = itemProperties }
      XGUIEng.DisableButton("Inventory_ItemButton" .. HeroInventory.CurrentDragButton.BtnNr, 1)
      XGUIEng.ShowWidget("HeroInventory_DragDropButton", 1)
      HeroInventory.SetTexture("HeroInventory_DragDropButton", item)
    end
  end
end

function OtherInventory_ItemButtonClicked(_btnNr)
  local itemProperties
  if HeroInventory.SwitchModeActive then
    itemProperties = HeroInventory.GetItemToInventoryButton(_btnNr, HeroInventory.NearestHero)
  else
    itemProperties = HeroInventory.GetItemToInventoryButton(_btnNr, HeroInventory.ActiveTrader)
  end
  if not itemProperties then
    return
  end
  local item = itemProperties.Item
  if HeroInventory.SwitchModeActive and (not item.Unswapable) then
    AddItem(HeroInventory.ActiveHero, item, 1)
    RemoveItem(HeroInventory.NearestHero, item, 1)
  elseif HeroInventory.TradeModeActive and item.Sellable then
    HeroInventory.TradeItem(HeroInventory.ActiveTrader, HeroInventory.ActiveHero, item, HeroInventory.TradeAmount)
  else
    HeroInventory.PlaySound(HeroInventory.Heroes[HeroInventory.NearestHero].Voice, 128)
  end
end

function HeroInventory_DragDropButtonClicked()
  XGUIEng.DisableButton("Inventory_ItemButton" .. HeroInventory.CurrentDragButton.BtnNr, 0)
  XGUIEng.ShowWidget("HeroInventory_DragDropButton", 0)
  local cursorPos = GetVirtualCursorPosition()
  local item = HeroInventory.CurrentDragButton.Item
  if IsPositionInWidget("Inventory_Equipment_bg", cursorPos) and item.Equipable then
    local allowEquip = true
    if item.EquipCondition then
      allowEquip = item.EquipCondition()
    end
    if allowEquip then
      HeroInventory.EquipItem(HeroInventory.ActiveHero, item)
    else
      HeroInventory.PlaySound(HeroInventory.Heroes[HeroInventory.ActiveHero].Voice, 128 )
    end
  elseif IsPositionInWidget("QuickAccessBar_bg", cursorPos) and item.Useable then
    if HeroInventory.CurrentQuickAccesBarSlot then
      HeroInventory.AddQuickAccessItem(HeroInventory.ActiveHero, HeroInventory.CurrentDragButton.ItemProperties, HeroInventory.CurrentQuickAccesBarSlot)
      XGUIEng.HighLightButton(HeroInventory.CurrentQuickAccesBarSlot.Button, 0)
    end
  end
  XGUIEng.SetMaterialColor("Inventory_Equipment_bg", 0, 220, 220, 220, 255)
  XGUIEng.SetMaterialColor("QuickAccessBar_bg", 0, 200, 200, 200, 255)
end

function Inventory_EquipButtonClicked(_btnNr)
  HeroInventory.UnequipItem(HeroInventory.ActiveHero, _btnNr)
  HeroInventory.Design(HeroInventory.ActiveHero)
end

function QuickAccessBar_ItemButtonClicked(_btnNr)
  local hero = HeroInventory.ActiveHero
  local heroInv = HeroInventory.Heroes[hero]
  local quickAccessItems = heroInv.QuickAccessItems
  if quickAccessItems[_btnNr] then
    local item = quickAccessItems[_btnNr].Item
    if XGUIEng.IsWidgetShown("HeroInventory") == 1 then
      local index = AddItem(hero, item, 1)
      quickAccessItems[_btnNr] = nil
      HeroInventory.RefreshQuickAccessSlots(hero)
      if not (HeroInventory.SwitchModeActive or HeroInventory.TradeModeActive) then
        Inventory_ItemButtonClicked(index - heroInv.ScrollValue)
      end
    else
      HeroInventory.UseItem(hero, _btnNr)
    end
  end
end

function Inventory_ItemCollection_ScrollLeft()
  HeroInventory.Heroes[HeroInventory.ActiveHero].ScrollValue = HeroInventory.Heroes[HeroInventory.ActiveHero].ScrollValue - 1
  HeroInventory.RefreshItemCollection(HeroInventory.ActiveHero, "Inventory")
end

function Inventory_ItemCollection_ScrollRight()
  HeroInventory.Heroes[HeroInventory.ActiveHero].ScrollValue = HeroInventory.Heroes[HeroInventory.ActiveHero].ScrollValue + 1
  HeroInventory.RefreshItemCollection(HeroInventory.ActiveHero, "Inventory")
end

function OtherInventory_ItemCollection_ScrollLeft()
  local heroName = HeroInventory.GetCurrentOtherInventoryOwner()
  local heroInv = HeroInventory.Heroes[heroName] or HeroInventory.Traders[heroName]
  heroInv.ScrollValue = heroInv.ScrollValue - 1
  HeroInventory.RefreshItemCollection(heroName, "OtherInventory")
end

function OtherInventory_ItemCollection_ScrollRight()
  local heroName = HeroInventory.GetCurrentOtherInventoryOwner()
  local heroInv = HeroInventory.Heroes[heroName] or HeroInventory.Traders[heroName]
  heroInv.ScrollValue = heroInv.ScrollValue + 1
  HeroInventory.RefreshItemCollection(heroName, "OtherInventory")
end

function HeroInventory.GetCurrentOtherInventoryOwner()
  if HeroInventory.SwitchModeActive then
    return HeroInventory.NearestHero
  else
    return HeroInventory.ActiveTrader
  end
end

function Inventory_SwitchModeButtonClicked()
  HeroInventory.SwitchModeActive = true
  HeroInventory.TradeModeActive = false
  HeroInventory.ShowOtherInventory()
  XGUIEng.ShowWidget("Inventory_CostsTooltip", 0)
  XGUIEng.HighLightButton("Inventory_ModesButton_SwitchMode", 1)
  XGUIEng.HighLightButton("Inventory_ModesButton_TradeMode", 0)
  XGUIEng.HighLightButton("Inventory_ModesButton_OwnInventory", 0)
  HeroInventory.Design(HeroInventory.ActiveHero)
end

function Inventory_TradeModeButtonClicked()
  HeroInventory.TradeModeActive = true
  HeroInventory.SwitchModeActive = false
  HeroInventory.ShowOtherInventory()
  XGUIEng.ShowWidget("Inventory_CostsTooltip", 1)
  XGUIEng.HighLightButton("Inventory_ModesButton_SwitchMode", 0)
  XGUIEng.HighLightButton("Inventory_ModesButton_TradeMode", 1)
  XGUIEng.HighLightButton("Inventory_ModesButton_OwnInventory", 0)
  HeroInventory.Design(HeroInventory.ActiveHero)
end

function Inventory_OwnInventoryButtonClicked()
  HeroInventory.TradeModeActive = false
  HeroInventory.SwitchModeActive = false
  XGUIEng.ShowWidget("Inventory_CostsTooltip", 0)
  HeroInventory.HideOtherInventory()
  XGUIEng.HighLightButton("Inventory_ModesButton_SwitchMode", 0)
  XGUIEng.HighLightButton("Inventory_ModesButton_TradeMode", 0)
  XGUIEng.HighLightButton("Inventory_ModesButton_OwnInventory", 1)
  HeroInventory.Design(HeroInventory.ActiveHero)
end
--------------------------------------------------------------------
-- Update Functions
--------------------------------------------------------------------
function HeroInventory_ControlDragDrop()
  if XGUIEng.IsWidgetShown("HeroInventory_DragDropButton") == 1 then
    local cursorPos = GetVirtualCursorPosition()
    XGUIEng.SetWidgetPosition("HeroInventory_DragDropButton", cursorPos.X - 16, cursorPos.Y -16)
    if IsPositionInWidget("Inventory_Equipment_bg", cursorPos) and HeroInventory.CurrentDragButton.Item.Equipable then
      XGUIEng.SetMaterialColor("Inventory_Equipment_bg", 0, 255, 255, 255, 255)
    elseif IsPositionInWidget("QuickAccessBar_bg", cursorPos) and HeroInventory.CurrentDragButton.Item.Useable then
      XGUIEng.SetMaterialColor("QuickAccessBar_bg", 0, 255, 255, 255, 255)
      for i = 1, 10 do
        local button = XGUIEng.GetWidgetID("QuickAccessBar_ItemButton" .. i)
        if IsPositionInWidget(button, cursorPos) then
          XGUIEng.HighLightButton(button, 1)
          HeroInventory.CurrentQuickAccesBarSlot = { Button = button, Nr = i }
        else
          XGUIEng.HighLightButton(button, 0)
        end
      end
    else
      XGUIEng.SetMaterialColor("Inventory_Equipment_bg", 0, 220, 220, 220, 255)
      XGUIEng.SetMaterialColor("QuickAccessBar_bg", 0, 200, 200, 200, 255)
    end
  end
end

function HeroInventory_TraderControl()
  local heroName = HeroInventory.ActiveHero 
  if heroName then
    for traderName, traderProps in pairs(HeroInventory.Traders) do
      if IsNear(heroName, traderName, 300) then
        if not HeroInventory.ActiveTrader then
          LookAt(heroName, traderName)
          LookAt(traderName, heroName)
          GUI.SetSelectedEntity(GetEntityId(heroName))
          CameraSetLookAt(GetEntityId(heroName))
          if type(npcSpeech) == "table" then
            bb_StartDialog(traderProps.TraderBriefing)
          else
            StartBriefing(traderProps.TraderBriefing)
          end
          traderProps.TraderBriefing.finished = function()
            HeroInventory.ShowInventory(GetEntityName(GUI.GetSelectedEntity()))
            Inventory_TradeModeButtonClicked()
          end
          HeroInventory.ActiveTrader = traderName
          XGUIEng.DisableButton("Inventory_ModesButton_TradeMode", 0)
          return
        end
      elseif HeroInventory.ActiveTrader == traderName then
        HeroInventory.HideOtherInventory()
        HeroInventory.ActiveTrader = nil
        Inventory_OwnInventoryButtonClicked()
        XGUIEng.DisableButton("Inventory_ModesButton_TradeMode", 1)
      end
    end
  end
end

function HeroInventory_CooldownPreperationControl()
  local cooldownCnt = 0
  for heroName, heroProps in pairs(HeroInventory.Heroes) do
    local quickAccessItems = heroProps.QuickAccessItems
    for i = 1, 10 do
      if quickAccessItems[i] then
        local itemProperties = quickAccessItems[i]
        if itemProperties.Cooldown > 0 or itemProperties.PreperationTime > 0 then
          cooldownCnt = cooldownCnt + 1
          local item = itemProperties.Item
          if itemProperties.PreperationTime > 0 then
            itemProperties.PreperationTime = itemProperties.PreperationTime - 1
            if itemProperties.PreperationTime == 0 then
              item.UseCallback(heroName)
            end
          elseif itemProperties.Cooldown > 0 then
            itemProperties.Cooldown = itemProperties.Cooldown - 1
            if itemProperties.Cooldown == 0 then
              if item.CooldownCallback then
                item.CooldownCallback(heroName)
              end
            end
          end  
          if itemProperties.Cooldown == 0 and itemProperties.PreperationTime == 0 then
            if item.Consumeable then
              if not RemoveItem(heroName, item, 1) then
                quickAccessItems[i] = nil
                HeroInventory.RefreshQuickAccessSlots(heroName)
              end
            end
          end
        end
      end
    end
  end
  if HeroInventory.ActiveHero then
    HeroInventory.UpdateCooldownView(HeroInventory.ActiveHero)
  end
  if cooldownCnt == 0 then
    return true
  end
end

function Inventory_Modes_ControlSwitchMode()
  local oldNearestHero = HeroInventory.NearestHero
  HeroInventory.NearestHero = HeroInventory.GetNearestHero()
  if HeroInventory.NearestHero then
    XGUIEng.DisableButton("Inventory_ModesButton_SwitchMode", 0)
  else
    XGUIEng.DisableButton("Inventory_ModesButton_SwitchMode", 1)
    if not HeroInventory.TradeModeActive then
      Inventory_OwnInventoryButtonClicked()
    end
  end
  if HeroInventory.NearestHero ~= oldNearestHero then
    HeroInventory.Design(HeroInventory.ActiveHero)
  end
end
--------------------------------------------------------------------
-- Tooltips
--------------------------------------------------------------------
function GUITooltip_Inventory_EquipmentTooltip(_equipedItemNr)
  XGUIEng.SetText("Inventory_EquipmentTooltip_Type", "@center " .. EquipItemSlots[_equipedItemNr].Name)
  local equipedItems = HeroInventory.Heroes[HeroInventory.ActiveHero].EquipedItems
  if equipedItems[_equipedItemNr] then
    local item = equipedItems[_equipedItemNr]
    XGUIEng.SetText("Inventory_EquipmentTooltip_Name", item.NameColor .. " @center " .. item.Name)
    XGUIEng.SetText("Inventory_EquipmentTooltip_InfoTooltip_Type", "@center " .. HeroInventory.GetTypeString(item))
    XGUIEng.SetText("Inventory_EquipmentTooltip_InfoTooltip_Info", item.InfoText)
    XGUIEng.SetText("Inventory_EquipmentTooltip_InfoTooltip_Name", item.NameColor .. " @center " .. item.Name)
    XGUIEng.SetText("Inventory_EquipmentTooltip_InfoTooltip_Amount", "")
  else
    XGUIEng.SetText("Inventory_EquipmentTooltip_Name", "@center -")
    XGUIEng.SetText("Inventory_EquipmentTooltip_InfoTooltip_Type", "")
    XGUIEng.SetText("Inventory_EquipmentTooltip_InfoTooltip_Info", "")
    XGUIEng.SetText("Inventory_EquipmentTooltip_InfoTooltip_Name", "")
    XGUIEng.SetText("Inventory_EquipmentTooltip_InfoTooltip_Amount", "")
  end
end

function GUITooltip_Inventory_Items_InfoTooltip(_btnNr)
  HeroInventory.TradeState = "Erlös"
  HeroInventory.SetInventoryInfoTooltipValues(_btnNr, HeroInventory.ActiveHero)
end

function GUITooltip_OtherInventory_Items_InfoTooltip(_btnNr)
  if HeroInventory.SwitchModeActive then
    HeroInventory.SetInventoryInfoTooltipValues(_btnNr, HeroInventory.NearestHero)
  else
    HeroInventory.TradeState = "Kaufpreis"
    HeroInventory.SetInventoryInfoTooltipValues(_btnNr, HeroInventory.ActiveTrader)
  end
end

function HeroInventory.SetInventoryInfoTooltipValues(_btnNr, _heroName)
  local itemProperties = HeroInventory.GetItemToInventoryButton(_btnNr, _heroName)
  if itemProperties then
    local item = itemProperties.Item
    XGUIEng.SetText("Inventory_Items_InfoTooltip_Type", "@center " .. HeroInventory.GetTypeString(item))
    XGUIEng.SetText("Inventory_Items_InfoTooltip_Info", item.InfoText)
    XGUIEng.SetText("Inventory_Items_InfoTooltip_Name", item.NameColor .. " @center " .. item.Name)
    XGUIEng.SetText("Inventory_Items_InfoTooltip_Amount", "@center " .. itemProperties.Amount .."x")
    if HeroInventory.TradeModeActive then
      if item.Costs then
        local selling = HeroInventory.Heroes[_heroName] ~= nil 
        if XGUIEng.IsModifierPressed(Keys.ModifierControl) == 1 then
          HeroInventory.TradeAmount = 5
          if itemProperties.Amount < HeroInventory.TradeAmount then
            HeroInventory.TradeAmount = itemProperties.Amount
          end
          HeroInventory.TradeState = HeroInventory.TradeState .. " x" .. HeroInventory.TradeAmount
        else
          HeroInventory.TradeAmount = 1
        end
        local costs, newMarketFactor = HeroInventory.CalculateCostsAndMarketFactor(selling, item, HeroInventory.TradeAmount)
        for i = 1, table.getn(ResourceNames) do
          local resource = ResourceNames[i]
          local widget = XGUIEng.GetWidgetID("Inventory_CostsTooltip_" .. resource .. "Amount")
          local neededRes = costs[resource] or 0
          local color = "@color:120,120,120"
          if _heroName ~= HeroInventory.ActiveHero then
            if not HasEnoughResources(neededRes, 1, resource) then
              color = "@color:150,0,0"
            end
          end
          XGUIEng.SetText(widget, color .. " @center " .. (costs[resource] or "-"))
        end
        XGUIEng.SetText("Inventory_CostsTooltip_TradeState", "@center " .. HeroInventory.TradeState)
      else
        XGUIEng.SetText("Inventory_CostsTooltip_TradeState", "@color:150,0,0 @center " .. "Unverkäuflich!")
        HeroInventory.ResetCostWidgets()
      end
    end
  else
    XGUIEng.SetText("Inventory_CostsTooltip_TradeState", "@center Leerer Slot")
    HeroInventory.ResetCostWidgets()
    XGUIEng.SetText("Inventory_Items_InfoTooltip_Type", "@center -")
    XGUIEng.SetText("Inventory_Items_InfoTooltip_Info", "")
    XGUIEng.SetText("Inventory_Items_InfoTooltip_Name", "@center Leerer Slot")
    XGUIEng.SetText("Inventory_Items_InfoTooltip_Amount", "@center -")
  end
end

function HeroInventory.ResetCostWidgets()
  for i = 1, table.getn(ResourceNames) do
    local res = ResourceNames[i]
    XGUIEng.SetText("Inventory_CostsTooltip_" .. res .. "Amount", "@color:120,120,120 @center -")
  end
end

function GUITooltip_QuickAccessBar_InfoTooltip(_quickAccessSlot)
  local quickAccessItems = HeroInventory.Heroes[HeroInventory.ActiveHero].QuickAccessItems
  if quickAccessItems[_quickAccessSlot] then
    local item = quickAccessItems[_quickAccessSlot].Item
    XGUIEng.SetText("Inventory_Items_InfoTooltip_Type", "@center " .. HeroInventory.GetTypeString(item))
    XGUIEng.SetText("Inventory_Items_InfoTooltip_Info", item.InfoText)
    XGUIEng.SetText("Inventory_Items_InfoTooltip_Name", item.NameColor .. " @center " .. item.Name)
  else
    XGUIEng.SetText("Inventory_Items_InfoTooltip_Type", "")
    XGUIEng.SetText("Inventory_Items_InfoTooltip_Info", "")
    XGUIEng.SetText("Inventory_Items_InfoTooltip_Name", "")
  end
  XGUIEng.SetText("Inventory_Items_InfoTooltip_Amount", "@center Slot" .. _quickAccessSlot)
end

function GUITooltip_InventoryTooltip(_mode)
  local text, title
  if _mode == 1 then
    local nearestHero = HeroInventory.NearestHero
    if nearestHero then
      nearestHero = HeroInventory.Heroes[nearestHero].DisplayName
    else
      nearestHero = "-"
    end
    title = "Tausch Modus"
    text = "Tauscht Items mit einem Held in der Nähe @cr Nächster Held: " .. nearestHero
  elseif _mode == 2 then
    title = "Handels Modus"
    text = "Wechselt in den Handelsmodus mit dem zuvor angesprochenen Händler"
  elseif _mode == 3 then
    title = "Inventar Modus"
    text = "Wechselt in das eigene Inventar eures Helden."
  end
  XGUIEng.SetText("Inventory_Tooltip_Title", "@center " .. title)
  XGUIEng.SetText("Inventory_Tooltip_Text", text)
end

function GUITooltip_OtherInventory_HeroName()
  XGUIEng.SetText("Inventory_EquipmentTooltip_Type", "@center " .. "Inventar von")
  local name = "Händler"
  if HeroInventory.Heroes[HeroInventory.NearestHero] then
    name = HeroInventory.Heroes[HeroInventory.NearestHero].DisplayName
  end
  XGUIEng.SetText("Inventory_EquipmentTooltip_Name", " @center " .. name)
  XGUIEng.SetText("Inventory_EquipmentTooltip_InfoTooltip_Type", "")
  XGUIEng.SetText("Inventory_EquipmentTooltip_InfoTooltip_Info", "")
  XGUIEng.SetText("Inventory_EquipmentTooltip_InfoTooltip_Name", "")
  XGUIEng.SetText("Inventory_EquipmentTooltip_InfoTooltip_Amount", "")
end
--------------------------------------------------------------------
-- Transmissions
--------------------------------------------------------------------
function HeroInventory.EquipItem(_hero, _item)
  if not _item.Equipable then
    return
  end
  if RemoveItem(_hero, _item, 1) then
    local equipedItems = HeroInventory.Heroes[_hero].EquipedItems
    local itemsToAdd = {}
    if _item.EquipType > EquipType.Special then
      if _item.EquipType == EquipType.OneHanded then
        if equipedItems[EquipType.LeftHand] then
          equipedItems[EquipType.LeftHand].UnequipCallback(_hero)
          table.insert(itemsToAdd, equipedItems[EquipType.LeftHand])
          if equipedItems[EquipType.LeftHand].EquipType == EquipType.TwoHanded then
            equipedItems[EquipType.RightHand] = null
            equipedItems[EquipType.LeftHand] = null
          end
        end
        equipedItems[EquipType.LeftHand] = equipedItems[EquipType.RightHand]
        equipedItems[EquipType.RightHand] = _item
      elseif _item.EquipType == EquipType.TwoHanded then
        
        if equipedItems[EquipType.RightHand] then
          if equipedItems[EquipType.RightHand].EquipType ~= EquipType.TwoHanded then
            if equipedItems[EquipType.LeftHand] then
              equipedItems[EquipType.LeftHand].UnequipCallback(_hero)
              table.insert(itemsToAdd, equipedItems[EquipType.LeftHand])
            end
          end
          equipedItems[EquipType.RightHand].UnequipCallback(_hero)
          table.insert(itemsToAdd, equipedItems[EquipType.RightHand])
        end
        equipedItems[EquipType.RightHand] = _item
        equipedItems[EquipType.LeftHand] = _item
      elseif _item.EquipType == EquipType.Ring then
        if equipedItems[EquipType.RingLeft] then
          equipedItems[EquipType.RingLeft].UnequipCallback(_hero)
          table.insert(itemsToAdd, equipedItems[EquipType.RingRight])
        end
        equipedItems[EquipType.RingLeft] = equipedItems[EquipType.RingRight]
        equipedItems[EquipType.RingRight] = _item
      end 
    else
      if equipedItems[_item.EquipType] then
        equipedItems[_item.EquipType].UnequipCallback(_hero)
        table.insert(itemsToAdd, equipedItems[_item.EquipType])
      end
      equipedItems[_item.EquipType] = _item
    end
    _item.EquipCallback(_hero)
    for i = 1, table.getn(itemsToAdd) do
      AddItem(_hero, itemsToAdd[i], 1)
    end
    HeroInventory.Design(_hero)
  end
end

function HeroInventory.UnequipItem(_hero, _equipType)
  local equipedItems = HeroInventory.Heroes[_hero].EquipedItems
  local item = equipedItems[_equipType]
  if not item then
    return
  end
  item.UnequipCallback(_hero)
  AddItem(_hero, item, 1)
  if item.EquipType > EquipType.Special then
    if item.EquipType == EquipType.OneHanded then
      if _equipType == EquipType.RightHand then
        equipedItems[EquipType.RightHand] = equipedItems[EquipType.LeftHand]
      end
      equipedItems[EquipType.LeftHand] = null
    elseif item.EquipType == EquipType.TwoHanded then
      equipedItems[EquipType.RightHand] = null
      equipedItems[EquipType.LeftHand] = null
    elseif item.EquipType == EquipType.Ring then
      if _equipType == EquipType.RingRight then
        equipedItems[EquipType.RingRight] = equipedItems[EquipType.RingLeft]
      end
      equipedItems[EquipType.RingLeft] = null
    end
  else
    equipedItems[_equipType] = null
  end
end

function HeroInventory.AddQuickAccessItem(_hero, _itemProperties, _quickAccessSlot)
  local item = _itemProperties.Item
  if not item.Useable then
    return
  end
  local quickAccessItems = HeroInventory.Heroes[_hero].QuickAccessItems
  if quickAccessItems[_quickAccessSlot.Nr] then
    if quickAccessItems[_quickAccessSlot.Nr].Cooldown ~= 0 or quickAccessItems[_quickAccessSlot.Nr].PreperationTime ~= 0 then
      return
    end
  end
  if RemoveItem(_hero, item, 1) then
    if quickAccessItems[_quickAccessSlot.Nr] then
      AddItem(_hero, quickAccessItems[_quickAccessSlot.Nr].Item, 1)
    end
    quickAccessItems[_quickAccessSlot.Nr] = { Item = _itemProperties.Item, Cooldown = 0, PreperationTime = 0 }
    HeroInventory.Design(HeroInventory.ActiveHero)
  end
end

function HeroInventory.TradeItem(_fromName, _toName, _item, _amount)
  local selling = HeroInventory.Heroes[_fromName] ~= nil
  local costs, newMarketFactor = HeroInventory.CalculateCostsAndMarketFactor(selling, _item, _amount)
  if HeroInventory.TransferRessources(_toName, _fromName, costs) then
    if _item.MarketFactor then
      _item.MarketFactor = newMarketFactor
    end
    AddItem(_toName, _item, _amount)
    RemoveItem(_fromName, _item, _amount)
  end
end

function HeroInventory.TransferRessources(_fromName, _toName, _costs)
  local playerIdFrom = Logic.EntityGetPlayer(GetEntityId(_fromName))
  local playerIdTo = Logic.EntityGetPlayer(GetEntityId(_toName))
  for i = 1, table.getn(ResourceNames) do
    local fromRes
    local resource = ResourceNames[i]
    local neededRes = (_costs[resource] or 0)
    if playerIdFrom == 1 then
      if not HasEnoughResources(neededRes, playerIdFrom, resource) then
        HeroInventory.PlaySound(NotEnoughSounds[resource], 128)
        return false
      end
      Logic.AddToPlayersGlobalResource(playerIdFrom, ResourceType[resource], - neededRes)
    end
    Logic.AddToPlayersGlobalResource(playerIdTo, ResourceType[resource], neededRes)
  end
  return true
end
--------------------------------------------------------------------
-- Use of Items
--------------------------------------------------------------------
function HeroInventory.UseItem(_hero, _nr)
  local heroInv = HeroInventory.Heroes[HeroInventory.ActiveHero]
  local quickAccessItems = heroInv.QuickAccessItems
  local itemProperties = quickAccessItems[_nr]
  if not itemProperties then
    return
  end
  local item = itemProperties.Item
  local allowUse = true
  if itemProperties.Cooldown > 0 or itemProperties.PreperationTime > 0 or itemProperties.Blocked then
    allowUse = false
  elseif item.UseCondition then
    allowUse = item.UseCondition(_hero)
  end
  if allowUse then
    heroInv.UseableActive = itemProperties
    if not item.PreperationTime then
      item.UseCallback(_hero)
      itemProperties.PreperationTime = 0
    else
      itemProperties.PreperationTime = itemProperties.Item.PreperationTime * 10
      if item.PreperationCallback then
        item.PreperationCallback(_hero)
      end
    end
    if item.Cooldown then
      itemProperties.Cooldown = itemProperties.Item.Cooldown * 10
    else
      itemProperties.Cooldown = 0
    end
    if JobIsRunning(HeroInventory.CooldownPreperationControl) ~= 1 then
      HeroInventory.CooldownPreperationControl = StartSimpleHiResJob("HeroInventory_CooldownPreperationControl")
    end
    XGUIEng.DisableButton("QuickAccessBar_ItemButton" .. _nr, 1)
  else
    HeroInventory.PlaySound(HeroInventory.Heroes[HeroInventory.ActiveHero].Voice, 128 )
  end
end

function HeroInventory.QuickAccess(_nr)
  if HeroInventory.ActiveHero then
    HeroInventory.UseItem(HeroInventory.ActiveHero, _nr)
  end
end
--------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------
function HeroInventory.CalculateCostsAndMarketFactor(_selling, _item, _amount)
  local curMarketFactor = _item.MarketFactor or 1
  local curInflation = _item.Inflation or 1
  local newCosts = {}
  local costs = _item.Costs
  for i = 1, _amount do
    if _selling then
      curMarketFactor = curMarketFactor / curInflation
    end
    for resource, value in pairs(costs) do
      newCosts[resource] = (newCosts[resource] or 0) + round(value * curMarketFactor)
    end
    if not _selling then
      curMarketFactor =  curMarketFactor * curInflation
    end
  end
  return newCosts, curMarketFactor
end

function HasEnoughResources(_amount, _pId, _resource)
  fromRes = Logic.GetPlayersGlobalResource(_pId, ResourceType[_resource]) + Logic.GetPlayersGlobalResource(_pId, ResourceType[_resource .. "Raw"])
  if fromRes < _amount then
    return false
  end
  return true
end
function HeroInventory.PlaySound(_sound, _volume)
  if HeroInventory.IsSomeoneTalking == 0 then
    Sound.PlayGUISound(Sounds[_sound], _volume)
    HeroInventory.IsSomeoneTalking = 2
    StartSimpleJob("HeroInventory_TalkControl")
  end
end
function HeroInventory_TalkControl()
  HeroInventory.IsSomeoneTalking = HeroInventory.IsSomeoneTalking - 1
  if HeroInventory.IsSomeoneTalking == 0 then
    return true
  end
end

function HeroInventory.GetNearestHero(_trader)
  local activeHero = HeroInventory.ActiveHero
  local heroes = {}
  for heroName, heroProps in pairs(HeroInventory.Heroes) do
    if heroName ~= activeHero then
      if IsNear(heroName, activeHero, 500) then
        local newHero = {
          Distance = GetDistance(heroName, activeHero),
          Name = heroName
        }
        table.insert(heroes, newHero)
      end
    end	
  end
  table.sort(heroes, function(a, b) return a.Distance < b.Distance; end)
  if table.getn(heroes) > 0 then
    return heroes[1].Name
  end
end

function HeroInventory.GetItemToInventoryButton(_btnNr, _heroName)
  local heroInv = HeroInventory.Heroes[_heroName] or HeroInventory.Traders[_heroName]
  if _btnNr > table.getn(heroInv.Items) then
    return false
  end
  local itemIndex = heroInv.ScrollValue * 12 + _btnNr
  local itemProperties = heroInv.Items[itemIndex]
  return itemProperties
end

function HeroInventory.SetTexture(_widget, _item)
  if _item.UseExternPath then
    XGUIEng.TransferMaterials("HeroInventory_PrototypeButton_Empty", _widget)
    for i = 0, 4 do
      local nr = i + 1
      if nr > 3 then
        nr = nr - 1
      end
      local path = HeroInventory.IconPath .. _item.Icon .. "-" .. nr .. ".png"
      XGUIEng.SetMaterialTexture(_widget, i, path)
    end
    XGUIEng.SetMaterialColor(_widget, 3, 150, 150, 150, 150)
  else
    XGUIEng.TransferMaterials(_item.Icon, _widget)
  end
  local colors = _item.IconColor
  if colors then
    for i = 0, 3 do
      XGUIEng.SetMaterialColor(_widget, i, colors[1], colors[2], colors[3], colors[4])
    end
  end
end

function HeroInventory.GetTypeString(_item)
  local textTable = {}
  if _item.QuestItem then
    table.insert(textTable, "questitem")
  end
  if _item.Equipable then
    table.insert(textTable, "ausrüstbar")
  end
  if _item.Useable then
    if _item.Consumeable then
      table.insert(textTable, "verbrauchbar")
    else
      table.insert(textTable, "verwendbar")
    end
  end
  return HeroInventory.CreateSuperString(textTable)
end

function HeroInventory.CreateSuperString(_stringTable)
  local text = ""
  if type(_stringTable) == "table" and table.getn(_stringTable) > 0 then
    text = _stringTable[1]
    for i = 2, table.getn(_stringTable) do
      text = text .. " / " .. _stringTable[i]
    end
  end
  return text
end

function HeroInventory.GetEquipButtonToType(_equipType)
  local button
  if _equipType > EquipType.Special then
    if _equipType == EquipType.OneHanded or _equipType == EquipType.TwoHanded then
      button = EquipItemSlots[EquipType.RightHand].Button
    elseif _equipType == EquipType.Ring then
      button = EquipItemSlots[EquipType.RingRight].Button
    end
  else
    button = EquipItemSlots[_equipType].Button
  end
  return button
end

function HeroInventory.GetItem(_hero, _item)
  local heroInv = HeroInventory.Heroes[_hero] or HeroInventory.Traders[_hero]
  local itemCollection = heroInv.Items
  for i = 1, table.getn(itemCollection) do
    if itemCollection[i].Item == _item then
      return i, itemCollection[i]
    end
  end
  return false
end

function GetVirtualCursorPosition()
  local xMouse, yMouse = GUI.GetMousePosition()
	local xScreen, yScreen = GUI.GetScreenSize()
	return {
    X = 1024 / xScreen * xMouse,
    Y = 768 / yScreen * yMouse 
  }
end

function GetAbsoluteWidgetPosition(_widget)
  if not S5Hook then
    return
  end
  local x, y = S5Hook.GetWidgetPosition(_widget)
  local motherId = XGUIEng.GetWidgetsMotherID(_widget)
  while motherId ~= 0 do
    local motherX, motherY = S5Hook.GetWidgetPosition(motherId)
    x = x + motherX
    y = y + motherY
    motherId = XGUIEng.GetWidgetsMotherID(motherId)
  end
  return { X = x, Y = y }
end

function IsPositionInWidget(_widget, _position)
  local widgetPos = GetAbsoluteWidgetPosition(_widget)
  local w, h = S5Hook.GetWidgetSize(_widget)
  if _position.X > widgetPos.X and _position.X < widgetPos.X + w then
    if _position.Y > widgetPos.Y and _position.Y < widgetPos.Y + h then
      return true
    end
  end
  return false
end