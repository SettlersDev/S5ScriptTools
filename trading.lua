--------------------------------------------------------------------
--					                Trading       					              --
--------------------------------------------------------------------
--[[
  Dependencies: 
    bb_comforts.lua
    heroinventory.lua [optional]
]]--

function SetupTrading()
	tRList = {}
	tradeRess = { GOLD = 1, CLAY = 2, WOOD = 3, IRON = 4, STONE = 5, SULFUR = 6 }
	activeTraders = {}
	trading_activeRess = 0
	tradingBuyWidgets		= { 
							"Trade_Market_BuyMoney",
							"Trade_Market_BuyClay",
							"Trade_Market_BuyWood",
							"Trade_Market_BuyIron",
							"Trade_Market_BuyStone",
							"Trade_Market_BuySulfur"
						}
	tradingSellWidgets 		= {
							"Trade_Market_SellMoney",
							"Trade_Market_SellClay",
							"Trade_Market_SellWood",
							"Trade_Market_SellIron",
							"Trade_Market_SellStone",
							"Trade_Market_SellSulfur"
						 }
	
	tradingIncreaseButton 	= { 
							"Trade_Market_IncreaseMoney",
							"Trade_Market_IncreaseClay",
							"Trade_Market_IncreaseWood",
							"Trade_Market_IncreaseIron",
							"Trade_Market_IncreaseStone",
							"Trade_Market_IncreaseSulfur"
							}
	subItemAmounts 			= {
								function(j) gvGUI.MarketMoneyToBuy 	= gvGUI.MarketMoneyToBuy - activeTraders[j].tradingAmount[tradeRess.GOLD] end,
								function(j) gvGUI.MarketClayToBuy 	= gvGUI.MarketClayToBuy - activeTraders[j].tradingAmount[tradeRess.CLAY] end,
								function(j) gvGUI.MarketWoodToBuy 	= gvGUI.MarketWoodToBuy - activeTraders[j].tradingAmount[tradeRess.WOOD] end,
								function(j) gvGUI.MarketIronToBuy 	= gvGUI.MarketIronToBuy - activeTraders[j].tradingAmount[tradeRess.IRON] end,
								function(j) gvGUI.MarketStoneToBuy 	= gvGUI.MarketStoneToBuy - activeTraders[j].tradingAmount[tradeRess.STONE] end,
								function(j) gvGUI.MarketSulfurToBuy = gvGUI.MarketSulfurToBuy - activeTraders[j].tradingAmount[tradeRess.SULFUR] end
							}
	setMaxItemAmounts 		= {
								function(maxToBuy) gvGUI.MarketMoneyToBuy 	= maxToBuy end,
								function(maxToBuy) gvGUI.MarketClayToBuy 	= maxToBuy end,
								function(maxToBuy) gvGUI.MarketWoodToBuy 	= maxToBuy end,
								function(maxToBuy) gvGUI.MarketIronToBuy 	= maxToBuy end,
								function(maxToBuy) gvGUI.MarketStoneToBuy 	= maxToBuy end,
								function(maxToBuy) gvGUI.MarketSulfurToBuy	= maxToBuy end
							}
	tradingIncreaseTooltips = {
								"menumarket/trade_increaseMoney",
								"menumarket/trade_increaseclay",
								"menumarket/trade_increaseWood",
								"menumarket/trade_increaseIron",
								"menumarket/trade_increaseStone",
								"menumarket/trade_increaseSulfur"
							}
	Trading_DisableTradeWidgets()
	AddOnSaveGameLoaded(Trading_DisableTradeWidgets)
	GUITooltip_Generic_OrigTrading = GUITooltip_Generic
	GUITooltip_Generic = function(a)
		for i = 1, 6 do
			if a == tradingIncreaseTooltips[i] then
				if XGUIEng.IsButtonDisabled(tradingIncreaseButton[i]) == 1 then
					local getamounts = {
										[1] = gvGUI.MarketMoneyToBuy,
										[2] = gvGUI.MarketClayToBuy,
										[3] = gvGUI.MarketWoodToBuy,
										[4] = gvGUI.MarketIronToBuy,
										[5] = gvGUI.MarketStoneToBuy,
										[6] = gvGUI.MarketSulfurToBuy 
									}
					local textString
					if getamounts[i] == 0 then
						if table.getn(activeTraders) > 1 then
							textString = " Die Händler haben all ihre Rohstoffe dieses Typs verkauft. @cr Ihr werdet warten müssen bis sie wiederkehren!"
						else
							textString = " Der Händler hat all seine Rohstoffe dieses Typs verkauft. @cr Ihr werdet warten müssen bis er wiederkehrt!"
						end
					else
						if table.getn(activeTraders) > 1 then
							textString = " Mehr Rohstoffe dieses Typs haben die Händler nicht dabei!"
						else
							textString = " Mehr Rohstoffe dieses Typs hat der Händler nicht dabei!"
						end
					end
					GUITooltip_Generic_OrigTrading(a)
					XGUIEng.SetText( gvGUI_WidgetID.TooltipBottomCosts, "" )
					XGUIEng.SetText( gvGUI_WidgetID.TooltipBottomText, Umlaute(gvCol.rot.." Hinweis: @cr "..COLOR0..textString))
					XGUIEng.SetText( gvGUI_WidgetID.TooltipBottomShortCut,"")
					return
				else
					GUITooltip_Generic_OrigTrading(a)
				end
			else
				GUITooltip_Generic_OrigTrading(a)
			end
		end
	end
	GameCallback_GUI_SelectionChanged_OrigTrading = GameCallback_GUI_SelectionChanged
	GameCallback_GUI_SelectionChanged = function()
    GameCallback_GUI_SelectionChanged_OrigTrading()
    local eId = GUI.GetSelectedEntity()
    local eTyp = Logic.GetEntityType(eId)
    if eTyp == Entities.PB_Market2 then
      XGUIEng.DisableButton("DestroyBuildingButton", 1)
    else
      XGUIEng.DisableButton("DestroyBuildingButton", 0)
    end
	end
	GUIAction_CancelTrade_OrigTrading = GUIAction_CancelTrade
	GUIAction_CancelTrade = function()
		Trading_ResumeMoving()
		GUIAction_CancelTrade_OrigTrading()
	end
	GameCallback_OnTransactionComplete_OrigTrading = GameCallback_OnTransactionComplete
	GameCallback_OnTransactionComplete = function(_BuildingId, _empty)
		GameCallback_OnTransactionComplete_OrigTrading(_BuildingId, _empty)
		Trading_FulFillTrade(1)
		Trading_ResumeMoving()
	end
	GUAction_MarketAcceptDeal_OrigTrading = GUAction_MarketAcceptDeal
	GUAction_MarketAcceptDeal = function(_SellResourceType)
    local SellAmount = InterfaceTool_MarketGetSellAmount(_SellResourceType)	
    local Costs = { }
    Costs[_SellResourceType] = SellAmount
    if InterfaceTool_HasPlayerEnoughResources_Feedback( Costs ) == 1 then			
      local BuildingID = GUI.GetSelectedEntity()
      local BuyResourceType, BuyResourceAmount = InterfaceTool_MarketGetBuyResourceTypeAndAmount()
      GUI.StartTransaction(BuildingID, _SellResourceType, BuyResourceType, BuyResourceAmount )
      XGUIEng.ShowWidget(gvGUI_WidgetID.TradeInProgress,1)		
      Trading_FulFillTrade(0, _ressType)
    end	
	end
	GUIAction_MarketToggleResource_OrigTrading = GUIAction_MarketToggleResource
	GUIAction_MarketToggleResource = function(_value, _resource)
		if XGUIEng.IsModifierPressed( Keys.ModifierControl ) == 1 then
			_value = _value * 5
		end
		_resource = _resource + _value
		if _resource <= 0 then
			_resource = 0
		end
		return _resource
	end
	GUIUpdate_MarketTradeWindow_OrigTrading = GUIUpdate_MarketTradeWindow
	GUIUpdate_MarketTradeWindow = function()
    GUIUpdate_MarketTradeWindow_OrigTrading()
    local tradeRessAmounts = GetTradeRessAmount()
    for ress = 1, table.getn( tradeRessAmounts ) do
      SellContainerStatus = 0
      if tradeRessAmounts[ress] > 0 then
        SellContainerStatus = 1	
        break
      end
    end
    XGUIEng.DisableButton("Trade_Market_AcceptWood", 0)
    XGUIEng.ShowWidget("Trade_Market_Sell", SellContainerStatus)
    Trading_CheckTradersRess()
	end
	StartSimpleJob("TradingControlJob")
end

function Trading_DisableTradeWidgets()
  for i = 1, 6 do 
		XGUIEng.ShowAllSubWidgets(tradingBuyWidgets[i], 0)
		XGUIEng.ShowAllSubWidgets(tradingSellWidgets[i], 0)
	end
end

function Trading_ResumeMoving()
	for i = 1, table.getn(activeTraders) do
		activeTraders[i].stopTrader = false
	end
end

function Trading_FulFillTrade(_state, _ressType) -- state is 1 or 0; if 0 then only stop traders on the active route
	if _state == 0 then
		tradingRest = {
							gvGUI.MarketMoneyToBuy,
							gvGUI.MarketClayToBuy,
							gvGUI.MarketWoodToBuy,
							gvGUI.MarketIronToBuy,
							gvGUI.MarketStoneToBuy,
							gvGUI.MarketSulfurToBuy 
						}
		cancelRest = {
							gvGUI.MarketMoneyToBuy,
							gvGUI.MarketClayToBuy,
							gvGUI.MarketWoodToBuy,
							gvGUI.MarketIronToBuy,
							gvGUI.MarketStoneToBuy,
							gvGUI.MarketSulfurToBuy 
						}
	end
	for i = table.getn(activeTraders), 1, -1 do
		for j = 1, 6 do
			if tradingRest[j] ~= 0 then
				if _state == 1 then
          if activeTraders[i].stopTrader then
            if (activeTraders[i].tradingAmount[j] - tradingRest[j]) <= 0 then	
              tradingRest[j] = tradingRest[j] - activeTraders[i].tradingAmount[j]
              activeTraders[i].tradingAmount[j] = 0
              activeTraders[i].wait = 1
            else
              activeTraders[i].tradingAmount[j] = activeTraders[i].tradingAmount[j] - tradingRest[j]
              tradingRest[j] = 0
            end
          end
				else
					if (activeTraders[i].cancelTradingAmount[j] - cancelRest[j]) < 0 then	
						cancelRest[j] = cancelRest[j] - activeTraders[i].cancelTradingAmount[j]
						if (activeTraders[i].cancelTradingAmount[j] >= 50) then
							activeTraders[i].stopTrader = true
						end
						activeTraders[i].cancelTradingAmount[j] = 0
						Trading_CopyCancelAmountTable(activeTraders[i].routeId, activeTraders[i].traderId)
					else
						activeTraders[i].cancelTradingAmount[j] = activeTraders[i].cancelTradingAmount[j] - cancelRest[j]
						cancelRest[j] = 0
						activeTraders[i].stopTrader = true
						Trading_CopyCancelAmountTable(activeTraders[i].routeId, activeTraders[i].traderId)
						return
					end
				end
			end
		end
	end
end

function Trading_CheckTradersRess()
	local maxToBuy = {
						[1] = 0,
						[2] = 0,
						[3] = 0,
						[4] = 0,
						[5] = 0,
						[6] = 0
					}
	tradingBuyRessources = {
						[1] = gvGUI.MarketMoneyToBuy,
						[2] = gvGUI.MarketClayToBuy,
						[3] = gvGUI.MarketWoodToBuy,
						[4] = gvGUI.MarketIronToBuy,
						[5] = gvGUI.MarketStoneToBuy,
						[6] = gvGUI.MarketSulfurToBuy
						}
	for i = 1, table.getn(activeTraders) do
		for o = 1, 6 do
			maxToBuy[o] = maxToBuy[o] + (activeTraders[i].tradingAmount[o] or 0)
		end
    for j = 1, table.getn(tRList[activeTraders[i].routeId].BuyRess) do
      if tradingBuyRessources[tRList[activeTraders[i].routeId].BuyRess[j]] > 0 then
        for ress = 1, table.getn(tRList[activeTraders[i].routeId].SellRess) do
          XGUIEng.ShowAllSubWidgets(tradingSellWidgets[tRList[activeTraders[i].routeId].SellRess[ress]], 1)
        end
        for ress = 1, 6 do
           local disable = true
          for sellRess = 1, table.getn(tRList[activeTraders[i].routeId].SellRess) do 
            if tRList[activeTraders[i].routeId].SellRess[sellRess] == ress then
              disable = false
            end
          end
          if disable then
            XGUIEng.ShowAllSubWidgets(tradingSellWidgets[ress], 0)
          end
        end
      end
      XGUIEng.ShowAllSubWidgets(tradingBuyWidgets[tRList[activeTraders[i].routeId].BuyRess[j]], 1)
    end
	end
	for i = 1, 6 do
		if (tradingBuyRessources[i] >= maxToBuy[i]) then
			XGUIEng.DisableButton(tradingIncreaseButton[i], 1)
			setMaxItemAmounts[i](maxToBuy[i])
		else
			XGUIEng.DisableButton(tradingIncreaseButton[i], 0)
		end
	end
end

function Trading_GetNameForItemTrader()
	trading_ItemTraderNameCount = (trading_ItemTraderNameCount or 0) + 1
	return "Trading_ItemTrader"..trading_ItemTraderNameCount
end

function AddTradeRoute(_pName, _SellRess, _BuyRess)
	local nameCount = 1
	local newTradeRoute = {}
	newTradeRoute.positions = {}
	local pos = GetPosition(_pName..nameCount)
	while pos.X ~= 0 do
		table.insert(newTradeRoute.positions, pos)
		nameCount = nameCount + 1
		pos = GetPosition(_pName..nameCount)
	end
	newTradeRoute.traders = {}
	if _SellRess and _BuyRess then
		newTradeRoute.SellRess = _SellRess
		newTradeRoute.BuyRess = _BuyRess
		newTradeRoute.tradingSystem = true
	else
		newTradeRoute.tradingSystem = false
	end
	table.insert(tRList, newTradeRoute)
	return table.getn(tRList)
end


function AddTraderToRoute(_RouteId, _pId, _tradingAmount, _multiparam) 
-- if multiparam == table then trader is a ITEMtrader elseif multiparam is a number its the amount of traders to be added on the route
	local i = _RouteId
	local posIndex = 1
	local direction = 1
	if type(_multiparam) == "number" then
		assert((_multiparam <= table.getn(tRList[i].positions)), "Trading: to much traders on a route")
		posIndex = _multiparam
	end
	local traderNames = {}
	for o = 1, posIndex do
		local newTraderIndex = table.getn(tRList[i].traders) + 1
		newTrader = {
						eId = CreateEntity(_pId, Entities.PU_Travelling_Salesman, tRList[i].positions[o]),
						pId = _pId,
						curWP = o,
						dir = direction,
						wait = 0,
						deadCounter = 10,
						routeId = i,
						traderId = newTraderIndex,
						tradingAmount = {},
						cancelTradingAmount = {},
						stopTrader = false,
						origTradingAmount = { 
												gold = _tradingAmount[tradeRess.GOLD] or 0,
												clay = _tradingAmount[tradeRess.CLAY] or 0,
												wood = _tradingAmount[tradeRess.WOOD] or 0,
												iron = _tradingAmount[tradeRess.IRON] or 0,
												stone = _tradingAmount[tradeRess.STONE] or 0,
												sulfur = _tradingAmount[tradeRess.SULFUR] or 0
											  }
						}
		if type(_multiparam) == "table" then
			newTrader.itemTrader = true
			newTrader.name = _multiparam.name
			newTrader.defaultItems = _multiparam.defaultItems
			newTrader.briefing = _multiparam.briefing
			SetEntityName(newTrader.eId, _multiparam.name)
			CreateItemTrader(_multiparam.name, _multiparam.briefing)
			DisableNpcMarker(newTrader.eId)
			table.insert(tRList[i].traders, newTrader)
			Trading_CheckItemsAndRefill(i, newTraderIndex)
			Trading_CopyAmountTable(i, newTraderIndex)
			Trading_CopyCancelAmountTable(i, newTraderIndex)
			return _multiparam.name
		end
		table.insert(tRList[i].traders, newTrader)
		Trading_CopyAmountTable(i, newTraderIndex)
		Trading_CopyCancelAmountTable(i, newTraderIndex)
		direction = direction * -1
		table.insert(traderNames, newTrader.eId)
	end
	return traderNames
end

function Trading_CopyAmountTable(_routeIndex, _traderIndex)
	local i = _routeIndex
	local o = _traderIndex
	tRList[i].traders[o].tradingAmount[tradeRess.GOLD] = tRList[i].traders[o].origTradingAmount.gold
	tRList[i].traders[o].tradingAmount[tradeRess.CLAY] = tRList[i].traders[o].origTradingAmount.clay
	tRList[i].traders[o].tradingAmount[tradeRess.WOOD] = tRList[i].traders[o].origTradingAmount.wood
	tRList[i].traders[o].tradingAmount[tradeRess.IRON] = tRList[i].traders[o].origTradingAmount.iron
	tRList[i].traders[o].tradingAmount[tradeRess.STONE] = tRList[i].traders[o].origTradingAmount.stone
  tRList[i].traders[o].tradingAmount[tradeRess.SULFUR] = tRList[i].traders[o].origTradingAmount.sulfur
end

function Trading_CopyCancelAmountTable(_routeIndex, _traderIndex)
	local i = _routeIndex
	local o = _traderIndex
	tRList[i].traders[o].cancelTradingAmount[tradeRess.GOLD] = tRList[i].traders[o].origTradingAmount.gold
	tRList[i].traders[o].cancelTradingAmount[tradeRess.CLAY] = tRList[i].traders[o].origTradingAmount.clay
	tRList[i].traders[o].cancelTradingAmount[tradeRess.WOOD] = tRList[i].traders[o].origTradingAmount.wood
	tRList[i].traders[o].cancelTradingAmount[tradeRess.IRON] = tRList[i].traders[o].origTradingAmount.iron
	tRList[i].traders[o].cancelTradingAmount[tradeRess.STONE] = tRList[i].traders[o].origTradingAmount.stone
	tRList[i].traders[o].cancelTradingAmount[tradeRess.SULFUR] = tRList[i].traders[o].origTradingAmount.sulfur
end

function Trading_CheckItemsAndRefill(_routeIndex, _traderIndex)
	for j = 1, table.getn(tRList[_routeIndex].traders[_traderIndex].defaultItems) do
		local itemAmount = GetItemAmount(tRList[_routeIndex].traders[_traderIndex].eId, tRList[_routeIndex].traders[_traderIndex].defaultItems[j].item.name) or 0
		local AmountToAdd = tRList[_routeIndex].traders[_traderIndex].defaultItems[j].amount - itemAmount
		AddItem(tRList[_routeIndex].traders[_traderIndex].eId, tRList[_routeIndex].traders[_traderIndex].defaultItems[j].item, AmountToAdd)
	end
end

function TradingControlJob()	
	for i = 1, table.getn(tRList) do
		for o = 1, table.getn(tRList[i].traders) do
			if not IsDead(tRList[i].traders[o].eId) then
				if tRList[i].traders[o].wait == 0 then	
					if not Logic.IsEntityMoving(tRList[i].traders[o].eId) then
            local nextWP = tRList[i].traders[o].curWP
            if GetDistance(tRList[i].traders[o].eId, tRList[i].positions[nextWP]) < 400 then
              nextWP = tRList[i].traders[o].curWP + tRList[i].traders[o].dir
            end
						if not tRList[i].positions[nextWP] then
							tRList[i].traders[o].dir = tRList[i].traders[o].dir * -1
							tRList[i].traders[o].wait = 2*60
							local curPos = tRList[i].traders[o].curWP
							local randomPos = GetRandomPos(tRList[i].positions[curPos], 1000)
							Logic.MoveSettler(tRList[i].traders[o].eId, randomPos.X, randomPos.Y)
							if tRList[i].traders[o].itemTrader then
								EnableNpcMarker(tRList[i].traders[o].eId)
							end	
							if tRList[i].traders[o].dir == -1 then
								Trading_CopyAmountTable(i, o)
								table.insert(activeTraders, tRList[i].traders[o])
							end
							return
						end
						Logic.MoveSettler(tRList[i].traders[o].eId, tRList[i].positions[nextWP].X, tRList[i].positions[nextWP].Y)
						tRList[i].traders[o].curWP = nextWP
					end
				else		
					if not tRList[i].traders[o].stopTrader then
						tRList[i].traders[o].wait = tRList[i].traders[o].wait - 1
					end
					if tRList[i].traders[o].itemTrader then
						if tRList[i].traders[o].wait == 0 then				
							Trading_CheckItemsAndRefill(i, o)
							for j = 1, table.getn(heroInventory) do
								if heroInventory[j].heroId == tRList[i].traders[o].eId then
									if heroInventory_lastActiveTrader == j then
										HideInventory()
									end
								end
							end
						elseif tRList[i].traders[o].wait == 10 then
							DisableNpcMarker(tRList[i].traders[o].eId)
						end
					end	
					if (tRList[i].traders[o].wait == 0) and tRList[i].tradingSystem and (tRList[i].traders[o].dir == -1) then
						for j = 1, table.getn(tRList[i].SellRess) do
							XGUIEng.ShowAllSubWidgets(tradingSellWidgets[tRList[i].SellRess[j]], 0)
						end
						for j = 1, table.getn(tRList[i].BuyRess) do
							XGUIEng.ShowAllSubWidgets(tradingBuyWidgets[tRList[i].BuyRess[j]], 0)
						end
						for j = table.getn(activeTraders), 1, -1 do
							if activeTraders[j].eId == tRList[i].traders[o].eId then
								local tradeRessAmounts = GetTradeRessAmount()
								for t = 1, 6 do
									if tradeRessAmounts[t] ~= 0 then
										if (tradeRessAmounts[t] - activeTraders[j].tradingAmount[t]) > 0 then
											subItemAmounts[t](j)
										else
											GUIAction_Market_Init()
										end
									end
								end
								table.remove(activeTraders, j)
							end
						end
					end
				end
			else
				if tRList[i].traders[o].deadCounter == 0 then
					if tRList[i].traders[o].itemTrader then
						RemoveHeroInventory(tRList[i].traders[o].eId)
						NPC[tRList[i].traders[o].eId] = nil
					end
					tRList[i].traders[o].eId = CreateEntity(tRList[i].traders[o].pId, Entities.PU_Travelling_Salesman, tRList[i].positions[1])
					tRList[i].traders[o].deadCounter = 60
					if tRList[i].traders[o].itemTrader then
						SetEntityName(tRList[i].traders[o].eId, tRList[i].traders[o].name)
						CreateItemTrader(tRList[i].traders[o].name, tRList[i].traders[o].briefing)
						DisableNpcMarker(tRList[i].traders[o].eId)
						Trading_CheckItemsAndRefill(i, o)
					end
				else
					tRList[i].traders[o].deadCounter = tRList[i].traders[o].deadCounter -1
				end
			end
		end
	end
end

function DisableSellWidgets()
  for i = 1, 6 do
    XGUIEng.ShowAllSubWidgets(tradingSellWidgets[i], 0)
  end
end

function GetTradeRessAmount()
  return {
    [1] = gvGUI.MarketMoneyToBuy,
    [2] = gvGUI.MarketClayToBuy,
    [3] = gvGUI.MarketWoodToBuy,
    [4] = gvGUI.MarketIronToBuy,
    [5] = gvGUI.MarketStoneToBuy,
    [6] = gvGUI.MarketSulfurToBuy 
  }
end