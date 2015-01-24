---------------------------------------------------------------------------------------
--                        ATTRIBUTE MODIFICATIONS                                    --
---------------------------------------------------------------------------------------
--[[
  Dependencies: 
    community_comforts.lua

]]--
function SetupAttMods()
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_HURT_ENTITY,"","AttributeModifications",1)
	-- global table for all modded entities
	modifiedEnt = {}
	-- table for killing entities savely
	killThemAll = {}
	-- table for hurting entities by defined damage
	hurtThem = {}
	-- table of all soldiers and their leaders
	LeaderOfSoldiers = {
		[Entities.CU_BanditSoldierBow1] = Entities.CU_BanditLeaderBow1,
		[Entities.CU_BanditSoldierSword1] = Entities.CU_BanditLeaderSword1,
		[Entities.CU_BanditSoldierSword2] = Entities.CU_BanditLeaderSword2,
		[Entities.CU_Barbarian_SoldierClub1] = Entities.CU_Barbarian_LeaderClub1,
		[Entities.CU_Barbarian_SoldierClub2] = Entities.CU_Barbarian_LeaderClub2,
		[Entities.CU_BlackKnight_SoldierMace1] = Entities.CU_BlackKnight_LeaderMace1,
		[Entities.CU_BlackKnight_SoldierMace2] = Entities.CU_BlackKnight_LeaderMace2,
		[Entities.CU_Evil_SoldierBearman1] = Entities.CU_Evil_LeaderBearman1,
		[Entities.CU_Evil_SoldierSkirmisher1] = Entities.CU_Evil_LeaderSkirmisher1,
		[Entities.PU_SoldierBow1] = Entities.PU_LeaderBow1,
		[Entities.PU_SoldierBow2] = Entities.PU_LeaderBow2,
		[Entities.PU_SoldierBow3] = Entities.PU_LeaderBow3,
		[Entities.PU_SoldierBow4] = Entities.PU_LeaderBow4,
		[Entities.PU_SoldierCavalry1] = Entities.PU_LeaderCavalry1,
		[Entities.PU_SoldierCavalry2] = Entities.PU_LeaderCavalry2,
		[Entities.PU_SoldierHeavyCavalry1] = Entities.PU_LeaderHeavyCavalry1,
		[Entities.PU_SoldierHeavyCavalry2] = Entities.PU_LeaderHeavyCavalry2,
		[Entities.PU_SoldierPoleArm1] = Entities.PU_LeaderPoleArm1,
		[Entities.PU_SoldierPoleArm2] = Entities.PU_LeaderPoleArm2,
		[Entities.PU_SoldierPoleArm3] = Entities.PU_LeaderPoleArm3,
		[Entities.PU_SoldierPoleArm4] = Entities.PU_LeaderPoleArm4,
		[Entities.PU_SoldierRifle1] = Entities.PU_LeaderRifle1,
		[Entities.PU_SoldierRifle2] = Entities.PU_LeaderRifle2,
		[Entities.PU_SoldierSword1] = Entities.PU_LeaderSword1,
		[Entities.PU_SoldierSword2] = Entities.PU_LeaderSword2,
		[Entities.PU_SoldierSword3] = Entities.PU_LeaderSword3,
		[Entities.PU_SoldierSword4] = Entities.PU_LeaderSword4,
	}
	attMods_heroTypes = {	
								[Entities.PU_Hero1c] = false, 
								[Entities.PU_Hero5] = false, 
								[Entities.PU_Hero4] = AttMods_Hero4, 
								[Entities.PU_Hero3] = AttMods_Hero3, 
								[Entities.PU_Hero2] = false, 
								[Entities.PU_Hero6] = false, 
								[Entities.CU_Mary_de_Mortfichet] = false, 
								[Entities.CU_BlackKnight] = false, 
								[Entities.CU_Barbarian_Hero] = false, 
								[Entities.PU_Hero10] = false, 
								[Entities.PU_Hero11] = false, 
								[Entities.CU_Evil_Queen] = false,
								[Entities.PU_Hero1a] = false, 
								[Entities.PU_Hero1b] = false
							   }
	-- edit all the display widgets
	GUIUpdate_Armor = function()
		local CurrentWidgetID = XGUIEng.GetCurrentWidgetID()
		local EntityID = GUI.GetSelectedEntity()
		local Armor = Logic.GetEntityArmor(EntityID)
		local eName = GetEntityName(EntityID)
		if modifiedEnt[eName] then
			Armor = modifiedEnt[eName].armor
		end
		XGUIEng.SetText(CurrentWidgetID, Armor)
	end
	
	GUIUpdate_Damage = function()
		local CurrentWidgetID = XGUIEng.GetCurrentWidgetID()
		local LeaderID = GUI.GetSelectedEntity()
		local Damage = Logic.GetEntityDamage(LeaderID)
		local eName = GetEntityName(LeaderID)
		if modifiedEnt[eName] then
			Damage = modifiedEnt[eName].damage
		end
		XGUIEng.SetText(CurrentWidgetID, Damage)
	end
	
	GUIUpate_DetailsHealthBar = function()
		local CurrentWidgetID = XGUIEng.GetCurrentWidgetID()
		local EntityID = GUI.GetSelectedEntity()
		if EntityID == nil then
			return
		end
		local PlayerID = GUI.GetPlayerID()	
		local ColorR, ColorG, ColorB = GUI.GetPlayerColor( PlayerID )
		XGUIEng.SetMaterialColor(CurrentWidgetID,0,ColorR, ColorG, ColorB,170)	
		local CurrentHealth, Maxhealth
		local eName = GetEntityName(EntityID)
		if modifiedEnt[eName] then
			CurrentHealth = math.floor(modifiedEnt[eName].health.curH)
			Maxhealth = modifiedEnt[eName].health.maxH
		else
			CurrentHealth = Logic.GetEntityHealth( EntityID )
			Maxhealth = Logic.GetEntityMaxHealth( EntityID )
		end
		XGUIEng.SetProgressBarValues(CurrentWidgetID,CurrentHealth, Maxhealth)
	end
	
	GUIUpdate_DetailsHealthPoints = function()
		local CurrentWidgetID = XGUIEng.GetCurrentWidgetID()
		local EntityID = GUI.GetSelectedEntity()
		if EntityID == nil then
			return
		end
		local PlayerID = GUI.GetPlayerID()
		local CurrentHealth, Maxhealth
		local eName = GetEntityName(EntityID)
		if modifiedEnt[eName] then
			CurrentHealth = math.floor(modifiedEnt[eName].health.curH)
			Maxhealth = modifiedEnt[eName].health.maxH
			Regeneration = " + "..modifiedEnt[eName].health.regen
		else
			CurrentHealth = Logic.GetEntityHealth(EntityID)
			Maxhealth = Logic.GetEntityMaxHealth(EntityID)
			Regeneration = " "
		end
		local String = "@center ".. CurrentHealth .. "/" .. Maxhealth .. Regeneration
		XGUIEng.SetText(CurrentWidgetID, String)	
	end
	
	GetEntityHealth = function(_eId)
    local eName = GetEntityName(_eId)
    if modifiedEnt[eName] then 
      return modifiedEnt[eName].health.curH
    else
      return Logic.GetEntityHealth(GetEntityId(_eId))
    end
  end
  
  GetEntityMaxHealth = function(_eId)
    local eName = GetEntityName(_eId)
    if modifiedEnt[eName] then 
      return modifiedEnt[eName].health.maxH
    else
      return Logic.GetEntityMaxHealth(GetEntityId(_eId))
    end
  end
  
  HealEntity = function(_eId, _amount)
    local eName = GetEntityName(_eId)
    if modifiedEnt[eName] then 
      modifiedEnt[eName].health.curH = modifiedEnt[eName].health.curH + _amount
      if modifiedEnt[eName].health.curH > modifiedEnt[eName].health.maxH then
        modifiedEnt[eName].health.curH = modifiedEnt[eName].health.maxH
      end
      HealthRegenSpeedControl()
    else
      Logic.HealEntity(GetEntityId(_eId), _amount)
    end
  end
  
  SetModdedHealth = function(_entity, _health)
    local health
    local eName = GetEntityName(_entity)
    if modifiedEnt[eName] then
      if _health > modifiedEnt[eName].health.maxH then
        health = modifiedEnt[eName].health.maxH
      elseif _health < 0 then
        health = 0
      else
        health = _health
      end
      modifiedEnt[eName].health.curH = health
      HealthRegenSpeedControl()
    else
      SetHealth(_entity, _health)
    end
  end
end

-- SimpleJob for all modded entities
-- control of regeneration health and speed
function HealthRegenSpeedControl()
	for k, v in pairs(modifiedEnt) do
    AttMods_CheckHero(k)
		if not IsDead(k) then
      local eId = GetEntityId(k)
      if modifiedEnt[k].eId ~= eId then
        Logic.SetSpeedFactor(eId, modifiedEnt[k].speed)
        modifiedEnt[k].eId = eId
      end
      MakeVulnerable(k)
      if modifiedEnt[k].health.curH < 1 then
        SetHealth(eId, 0)
        modifiedEnt[k].health.curH = 0
      else
        if (modifiedEnt[k].health.curH + modifiedEnt[k].health.regen) > modifiedEnt[k].health.maxH then
          modifiedEnt[k].health.curH = modifiedEnt[k].health.maxH
        else
          modifiedEnt[k].health.curH = modifiedEnt[k].health.curH + modifiedEnt[k].health.regen
        end
        AttMods_SetHealthBar(eId)
      end
      MakeInvulnerable(k)
		end
	end
end

function DestroyModdedEntity(_name)
  if modifiedEnt[_name] then
    local eId = GetEntityId(_name)
    MakeVulnerable(_name)
    SetHealth(eId, 0)
    modifiedEnt[_name].health.curH = 0
    MakeInvulnerable(_name)
  end
end
-- function for modificated entities
function ModAttOfEntity(_name, _attributes)
  local eName = GetEntityName(_name)
  local eId = GetEntityId(eName)
  if eId == 0 then
    return false
  end 
	assert(type(_attributes) == "table", "AttributeMods: attribute table is not valid")
	local eTyp = Logic.GetEntityType(eId)
	if attMods_heroTypes[eTyp] then
    attMods_heroTypes[eTyp]()
  end
	if modifiedEnt[eName] then
		modifiedEnt[eName].damage = modifiedEnt[eName].damage + (_attributes.damage or 0) * modifiedEnt[eName].damageMultiplier
		modifiedEnt[eName].armor = modifiedEnt[eName].armor + (_attributes.armor or 0) * modifiedEnt[eName].armorMultiplier
		modifiedEnt[eName].speed = modifiedEnt[eName].speed + (_attributes.speed or 0) * modifiedEnt[eName].speedMultiplier
		if _attributes.health then
			modifiedEnt[eName].health.maxH = modifiedEnt[eName].health.maxH + (_attributes.health.maxH or 0) * modifiedEnt[eName].health.maxHMultiplier
			modifiedEnt[eName].health.regen = modifiedEnt[eName].health.regen + (_attributes.health.regen or 0) * modifiedEnt[eName].health.regenMultiplier
		end
		Logic.SetSpeedFactor(eId, modifiedEnt[eName].speed)
		return true
	end
	modifiedEnt[eName] = {
    eId = eId,
    damage = _attributes.damage or assert(false, "AttributeMods: no damage given"),
    damageMultiplier = 1,
    armor = _attributes.armor or assert(false, "AttributeMods: no armor given"),
    armorMultiplier = 1,
    speed = _attributes.speed or 1,
    speedMultiplier = 1,
    health = {
      maxH = _attributes.health.maxH,
      maxHMultiplier = 1,
      curH = _attributes.health.maxH,
      regen = _attributes.health.regen,
      regenMultiplier = 1,
    }
  }
  Logic.SetSpeedFactor(eId, modifiedEnt[eName].speed)
	MakeInvulnerable(eId)
	if not (JobIsRunning(healthRegenControlJobId) == 1) then
		healthRegenControlJobId = StartSimpleJob("HealthRegenSpeedControl")
	end
	return true
end

function AttMods_SetMultiplierOfEntity(_eName, _attributes)
  if modifiedEnt[_eName] then
    modifiedEnt[_eName].damageMultiplier = (_attributes.damage or 1)
		modifiedEnt[_eName].armorMultiplier = (_attributes.armor or 1)
		modifiedEnt[_eName].speedMultiplier = (_attributes.speed or 1)
    if _attributes.health then
      modifiedEnt[_eName].health.maxHMultiplier = (_attributes.health.maxH or 1)
      modifiedEnt[_eName].health.regenMultiplier = (_attributes.health.regen or 1)
    end
    return true
  end
end
	
-- event called on entity hurt entity
function AttributeModifications()
	local attId = Event.GetEntityID1()
	local defId = Event.GetEntityID2()
	local attName = GetEntityName(attId)
	local defName = GetEntityName(defId)
	MakeVulnerable(defId)
	if modifiedEnt[attName] then
    AttMods_DealDamage(defId, modifiedEnt[attName].damage)
	elseif modifiedEnt[defName] then
		HurtModdedEntity(defName, Logic.GetEntityDamage(attId))
	end
end

function AttMods_CheckHero(_name)
  if Logic.IsHero(GetEntityId(_name)) == 1 then
    if modifiedEnt[_name].health.curH < 1 then
      if not IsDead(_name) then
        modifiedEnt[_name].health.curH = modifiedEnt[_name].health.maxH / 2
      end
    end
  end   
end

-- they have their own health so they must be wounded differently
function HurtModdedEntity(_index, _dmg) -- index is name
  local eId = GetEntityId(_index)
	local dmg = _dmg - modifiedEnt[_index].armor
	if dmg <= 0 then
		dmg = 1
	end
	AttMods_CheckHero(_index)
	modifiedEnt[_index].health.curH = modifiedEnt[_index].health.curH - dmg
	MakeVulnerable(_index)
	if modifiedEnt[_index].health.curH < 1 then
		SetHealth(eId, 0)
		modifiedEnt[_index].health.curH = 0
	else
    AttMods_SetHealthBar(eId)
	end
	MakeInvulnerable(_index)
	if not (Logic.IsHero(eId) == 1) and (IsDead(_index)) then
		modifiedEnt[_index] = nil
	end
end

function AttMods_SetHealthBar(_eId)
  local eName = GetEntityName(_eId)
  local curHealth = Logic.GetEntityHealth(_eId)
  local maxHealth = Logic.GetEntityMaxHealth(_eId)
  if curHealth > (0.15 * maxHealth) then
    local factor = maxHealth / modifiedEnt[eName].health.maxH
    local newHealth = math.floor(modifiedEnt[eName].health.curH * factor)
    Logic.HealEntity(_eId, newHealth - curHealth)
  end
end

function AttMods_DealDamage(_target, _dmg)
	if modifiedEnt[GetEntityName(_target)] then
		HurtModdedEntity(GetEntityName(_target), _dmg)
  else
    local target = GetLeader(_target)
    local armor = Logic.GetEntityArmor(target) or 0
    local dmg = _dmg - armor
    if dmg <= 0 then
      dmg = 1
    end
    if Logic.IsLeader(target) == 1 then
      local soldiers = {Logic.GetSoldiersAttachedToLeader(target)}
      local restDamage = dmg
      for i = soldiers[1] + 1, 2, -1 do
        if (Logic.GetEntityHealth(soldiers[i]) - restDamage) <= 0 then
          restDamage = restDamage - Logic.GetEntityHealth(soldiers[i])
          table.insert(hurtThem, {id = soldiers[i], dmg = 100000, leader = target})
          MakeInvulnerable(target)
        else
          table.insert(hurtThem, {id = soldiers[i], dmg = restDamage, leader = target})
          MakeInvulnerable(target)
          restDamage = 0
        end
      end
      if restDamage ~= 0 then
        if restDamage - Logic.GetEntityHealth(target) > 0 then
          table.insert(hurtThem, {id = target, dmg = 100000, leader = target})
          MakeInvulnerable(target)
        else
          table.insert(hurtThem, {id = target, dmg = restDamage, leader = target})
          MakeInvulnerable(target)
        end
      end
    else
      table.insert(hurtThem, {id = target, dmg = dmg, leader = target})
      MakeInvulnerable(target)
    end
  end
	if not (JobIsRunning(attModsKillJob) == 1) then
		attModsKillJob = StartSimpleHiResJob("AttModsKillJob")
	end
end

function AttModsKillJob()
	while hurtThem[1] do
    if not IsDead(hurtThem[1].id) then
      MakeVulnerable(hurtThem[1].leader)
      Logic.HurtEntity(hurtThem[1].id, hurtThem[1].dmg)
    end
    table.remove(hurtThem, 1)
	end
	return true
end

function GetLeader(_soldier)
  return Logic.GetEntityScriptingValue(_soldier, 69)
end

----------------------------------------------------------------------
--                  Special Functions for Heroes                    --
----------------------------------------------------------------------
-- Hero3
-- Salim
function AttMods_Hero3()
  if not attMods_Hero3 then
     attMods_Hero3 = {
      OrigHeal = GUIAction_Hero3Heal
     }
     GUIAction_Hero3Heal = function()
      local eId = GUI.GetSelectedEntity()
      local ent = SucheAufDerWelt(1, 0, 1500, GetPosition(eId))
      for i = 1, table.getn(ent) do
        local eName = GetEntityName(ent[i])
        if modifiedEnt[eName] then
          HealEntity(eName, 0.33 * modifiedEnt[eName].health.maxH)
        end
      end
      attMods_Hero3.OrigHeal()
     end
  end
end
-- Hero3 end

-- Hero4
-- Erec
function AttMods_Hero4()
  if not attMods_Hero4 then
    attMods_Hero4 = {
      OrigAuraOfWar = GUIAction_Hero4AuraOfWar,
      OrigCircularAttack = GUIAction_Hero4CircularAttack,
      heroes = {},
    }
    GUIAction_Hero4AuraOfWar = function()
      local eId = GUI.GetSelectedEntity()
      local eName = GetEntityName(eId)
      if not attMods_Hero4.jobId then
        attMods_Hero4.jobId = StartSimpleJob("AttMods_Hero4_ControlAuraOfWar")
      end
      attMods_Hero4.heroes[eName] = { cooldown = 60, influenced = {}}
      attMods_Hero4.OrigAuraOfWar()
    end
    GUIAction_Hero4CircularAttack = function()
      local eId = GUI.GetSelectedEntity()
      for pId = 1, 6 do 
        if Logic.GetDiplomacyState(1, pId) == Diplomacy.Hostile then
          local ent = SucheAufDerWelt(pId, 0, 1000, GetPosition(eId))
          for i = 1, table.getn(ent) do
            local eName = GetEntityName(ent[i])
            if modifiedEnt[eName] then
              HealEntity(eName, -(0.33 * modifiedEnt[eName].health.maxH))
            end
          end
        end
      end
      GUI.SettlerCircularAttack(GUI.GetSelectedEntity())
    end
  end
end

function AttMods_Hero4_ResetAllModdifications(_heroName)
  for eName, state in pairs(attMods_Hero4.heroes[_heroName].influenced) do
    AttMods_SetMultiplierOfEntity(eName, {damage = 1})
    ModAttOfEntity(eName, {damage = -(modifiedEnt[eName].damage / 2)})
  end
  attMods_Hero4.heroes[_heroName] = nil
  
  local activeHeroCount = 0
  for heroName, infoTable in pairs(attMods_Hero4.heroes) do
    activeHeroCount = activeHeroCount + 1
  end
  if activeHeroCount == 0 then
    EndJob(attMods_Hero4.jobId)
    attMods_Hero4.jobId = nil
  end
end

function AttMods_Hero4_ControlAuraOfWar()
  for heroName, infoTable in pairs(attMods_Hero4.heroes) do
    for pId = 1, 6 do 
      if Logic.GetDiplomacyState(1, pId) < 2 then
        local ent = SucheAufDerWelt(pId, 0, 1500, GetPosition(heroName))
        for i = 1, table.getn(ent) do
          local eName = GetEntityName(ent[i])
          if modifiedEnt[eName] then
            if not infoTable.influenced[eName] then
              ModAttOfEntity(eName, {damage = modifiedEnt[eName].damage})
              AttMods_SetMultiplierOfEntity(eName, {damage = 2})
              infoTable.influenced[eName] = true
            end
          end
        end
        for eName, state in pairs(infoTable.influenced) do
          local inArea = false
          for i = 1, table.getn(ent) do
            if GetEntityName(ent[i]) == eName then
              inArea = true
            end
          end
          if not inArea then
            AttMods_SetMultiplierOfEntity(eName, {damage = 1})
            ModAttOfEntity(eName, {damage = -(modifiedEnt[eName].damage / 2)})
            infoTable.influenced[eName] = nil
          end
        end
      end
    end
    infoTable.cooldown = infoTable.cooldown - 1
    if infoTable.cooldown == 0 then
      AttMods_Hero4_ResetAllModdifications(heroName)
    end
  end
end
-- Hero4 end