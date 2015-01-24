--------------------------------------------------------------------
--					                RPG Movement  								        --
--------------------------------------------------------------------
--[[
  Dependencies: 
    community_comforts.lua
]]--
function AddRPG(_entity)
  if not RPG_Trigger then
    RPG_Trigger =	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_HURT_ENTITY,"","RPG_Impact",1)
    RPG_Attacker = {}
  end
  RPG_Attacker[GetEntityName(_entity)] = GGL_Effects.FXExplosionPilgrim
end

function RemoveRPG(_entity)
  RPG_Attacker[GetEntityName(_entity)] = nil
end

function RPG_Impact()
  local attId = Event.GetEntityID1()
  if RPG_Attacker[GetEntityName(attId)] then
    local defId = Event.GetEntityID2()
    CreateEffect(1, RPG_Attacker[GetEntityName(attId)], GetPosition(defId))
  end
end
--[[
GGL_Effects.FXBalistaTowerArrow
GGL_Effects.FXBuildingSmoke
GGL_Effects.FXBuildingSmokeLarge
GGL_Effects.FXBuildingSmokeMedium
GGL_Effects.FXBulletRifleman
GGL_Effects.FXCannonBall
GGL_Effects.FXCannonBallShrapnel
GGL_Effects.FXCannonFire
GGL_Effects.FXCannonTowerBall
GGL_Effects.FXCavalryArrow
GGL_Effects.FXChopTree
GGL_Effects.FXChopTreeDead
GGL_Effects.FXChopTreeInWinter
GGL_Effects.FXCrossBowArrow
GGL_Effects.FXCrossBowCavalryArrow
GGL_Effects.FXCrushBuilding
GGL_Effects.FXDarioFear
GGL_Effects.FXDestroyTree
GGL_Effects.FXDie
GGL_Effects.FXDieHero
GGL_Effects.FXExplosion
GGL_Effects.FXExplosionPilgrim
GGL_Effects.FXExplosionShrapnel
GGL_Effects.FXExtractStone
GGL_Effects.FXFire
GGL_Effects.FXFireLo
GGL_Effects.FXFireMedium
GGL_Effects.FXFireSmall
GGL_Effects.FXKalaArrow
GGL_Effects.FXKalaPoison
GGL_Effects.FXKerberosFear
GGL_Effects.FXLightning
GGL_Effects.FXMaryDemoralize
GGL_Effects.FXMaryPoison
GGL_Effects.FXRain
GGL_Effects.FXSalimHeal
GGL_Effects.FXShotRifleman
GGL_Effects.FXSnow
GGL_Effects.FXTerrainPointer
GGL_Effects.FXWeathermachineFakeFX
GGL_Effects.FXYukiFireworksFear
GGL_Effects.FXYukiFireworksJoy
GGL_Effects.FXYukiShuriken
]]--