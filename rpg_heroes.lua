--------------------------------------------------------------------
--					                RPG Heroes     								        --
--------------------------------------------------------------------
--[[
  Dependencies: 
    community_comforts.lua
    bb_comforts.lua   
]]--
function InitRpgHeroes(_heroTable)
  rpgMove = {
    heroes = {},
    rotation = 0,
    moveCnt = 0,
    curAngle = 15,
    angle = 15,
    turnAround = 0,
    move = false,
    activeHero = 1,
    UpdateRessourceAmountOrig = GUIUpdate_ResourceAmount,
    UpdateCommandGroupOrig = GUIUpdate_CommandGroup,
    SelectionChangedOrig = GameCallback_GUI_SelectionChanged,
    bb_StartSpeechOrig = bb_StartSpeech
  }
  bb_StartSpeech = function(_id, _convIndex)
    DisableRpgMovement()
    rpgMove.bb_StartSpeechOrig(_id, _convIndex)
  end
  for i = 1, table.getn(_heroTable) do
    AddRpgHero(_heroTable[i])
  end
  Input.KeyBindDown(Keys.Q, "JumpToNextHero()", 15)
  
  Input.KeyBindDown(Keys.W, "RPGM_Move(1)", 15)
  Input.KeyBindUp(Keys.W, "RPGM_Move(2)", 15)
  
  Input.KeyBindDown(Keys.A, "RPGM_TurnLeft(1)", 15)
  Input.KeyBindUp(Keys.A, "RPGM_TurnLeft(2)", 15)
  
  Input.KeyBindDown(Keys.D, "RPGM_TurnRight(1)", 15)
  Input.KeyBindUp(Keys.D, "RPGM_TurnRight(2)", 15)
  
  Input.KeyBindDown(Keys.S, "RPGM_StopFig(false)", 15)
  Input.KeyBindUp(Keys.S, "RPGM_StopFig(true)", 15)
  rpgMove.heroes[1].active = true
  rpgMove.activeHero = 1
end

function RemoveRpgHero(_name)
  if table.getn(rpgMove.heroes) <= 1 then
    return
  end
  for heroIndex = 1, table.getn(rpgMove.heroes) do
    if rpgMove.heroes[heroIndex].name == _name then
      if rpgMove.heroes[heroIndex].active then
        JumpToNextHero()
      end
      table.remove(rpgMove.heroes, heroIndex)
      for newHeroIndex = 1, table.getn(rpgMove.heroes) do
        if rpgMove.heroes[newHeroIndex].active then
          rpgMove.activeHero = newHeroIndex
        end
      end
      return
    end
  end
end

function AddRpgHero(_name)
  if table.getn(rpgMove.heroes) >= 3 then
    return
  end
  table.insert(rpgMove.heroes, { name = _name, active = false })
end

function JumpToNextHero()
  if rpgMove.active then
    rpgMove.heroes[rpgMove.activeHero].active = false
    GUI.DeselectEntity(GetEntityId(rpgMove.heroes[rpgMove.activeHero].name))
    rpgMove.activeHero = rpgMove.activeHero + 1
    local nextHero = rpgMove.heroes[rpgMove.activeHero]
    if not nextHero then
      nextHero = rpgMove.heroes[1]
      rpgMove.activeHero = 1
    end
    nextHero.active = true
    GUI.SelectEntity(GetEntityId(nextHero.name))
    SetToRpgView(nextHero.name)
  end
end

Camera.RotSetAngleOrig = Camera.RotSetAngle
Camera.RotSetAngle = function(value)
  Camera.RotSetAngleOrig(value)
end
function SetToRpgView(_entity)
  if not _entity then
    _entity = rpgMove.heroes[rpgMove.activeHero].name
  end
  rpgMove.entity = GetEntityId(_entity)
  if not rpgMove.active then
    gvCamera.DefaultFlag = 0
    Camera.InitCameraFlight()
    GUI.SelectEntity(rpgMove.entity)
    Camera.RotSetFlipBack(0)
    Camera.RotSetAngle(rpgMove.rotation)
    Camera.ZoomSetDistance(1000)
    Camera.ZoomSetAngle(rpgMove.curAngle)
    Camera.ZoomSetFOV(70)
    Camera.InitCameraFlight()
    Display.SetFarClipPlaneMinAndMax(0, 30000) 
    Display.SetRenderSky(1)
    Display.SetRenderFogOfWar(0)
    
    GUIUpdate_ResourceAmount = function(_ressType, _amount)
      local xMouse, yMouse = GUI.GetMousePosition()
      local xScreen, yScreen = GUI.GetScreenSize()
      local xRatio = xMouse / xScreen
      if rpgMove.turnAround > 0 then
        if rpgMove.turnAround < 3 then
          rpgMove.rotation = rpgMove.rotation + 0.1
          Camera.RotSetAngle(rpgMove.rotation)
        else 
          rpgMove.rotation = rpgMove.rotation - 0.1
          Camera.RotSetAngle(rpgMove.rotation)
        end
      end
      if xRatio < 0.05 then
        rpgMove.turnAround = 2
      elseif xRatio > 0.95 then
        rpgMove.turnAround = 4
      elseif math.mod(rpgMove.turnAround, 2) == 0 then
        rpgMove.turnAround = 0
      end
      local angleDiff = rpgMove.angle - rpgMove.curAngle
      rpgMove.curAngle = rpgMove.curAngle + 0.002 * angleDiff
      if rpgMove.curAngle < 0 then
        rpgMove.curAngle = 0
      end
      Camera.ZoomSetAngle(rpgMove.curAngle)
      rpgMove.UpdateRessourceAmountOrig(_ressType, _amount)
    end
    GameCallback_GUI_SelectionChanged = function()
      if rpgMove.preventFromCalling then
        return
      end
      ent = GUI.GetSelectedEntities()
      if not ent or ent > 1 then
        rpgMove.preventFromCalling = true
        GUI.ClearSelection()
        GUI.SetSelectedEntity(GetEntityId(rpgMove.heroes[rpgMove.activeHero].name))
        rpgMove.preventFromCalling = false
      end
      rpgMove.SelectionChangedOrig()
    end
    XGUIEng.DisableButton("Command_Attack", 1)
    XGUIEng.DisableButton("Command_Stand", 1)
    XGUIEng.DisableButton("Command_Defend", 1)
    XGUIEng.DisableButton("Command_Patrol", 1)
    XGUIEng.DisableButton("Command_Guard", 1)
    rpgMove.JobId1 = StartSimpleHiResJob("ControlMovement")
    rpgMove.JobId2 = StartSimpleJob("ControlHeroesMovement")
    rpgMove.active = true
  end 
end

function RPGM_StopFig(_releasedButton)
  if rpgMove.active then
    if not rpgMove.alreadyStopped then
      Move(rpgMove.entity, GetPosition(rpgMove.entity))
      rpgMove.alreadyStopped = true
    end
    if _releasedButton then
      rpgMove.alreadyStopped = false
    end
  end
end

function RPGM_TurnLeft(_flag)
  if rpgMove.active then
    if _flag == 1 then
      rpgMove.turnAround = 1
    else
      rpgMove.turnAround = 0
    end
  end
end

function RPGM_TurnRight(_flag)
  if rpgMove.active then
    if _flag == 1 then
      rpgMove.turnAround = 3
    else
      rpgMove.turnAround = 0
    end
  end
end

function RPGM_Move(_flag)
  if rpgMove.active then
    if _flag == 1 then
      rpgMove.move = true
    else
      rpgMove.move = false
    end
  end
end

function ToRadian(_value)
  return _value * (math.pi/180)
end
function ToDegree(_value)
  return _value * (180/ math.pi)
end

function ControlMovement()
  Camera.FollowEntity(rpgMove.entity) 
  -- control move cmd 
  if rpgMove.moveCnt ~= 0 then
    rpgMove.moveCnt = rpgMove.moveCnt - 1
  elseif rpgMove.move then
    local x, y, oldZ = Logic.EntityGetPos(rpgMove.entity)
    local pos = {X = x, Y = y}
    local newPos = GetPosInFrontOfEntity(pos, rpgMove.rotation, 400) 
    local entity = Logic.CreateEntity(Entities.XD_ScriptEntity, newPos.X, newPos.Y, 0, 1)
    local _, _, newZ = Logic.EntityGetPos(entity)
    
    local slopeAngle = 15 - ToDegree(math.atan2(newZ - oldZ, 400))
    rpgMove.angle = slopeAngle
    Move(rpgMove.entity, newPos)
    rpgMove.moveCnt = 3
  end
end

function ControlHeroesMovement()
  local leaderHero = rpgMove.heroes[rpgMove.activeHero].name
  local leaderOrient = Logic.GetEntityOrientation(GetEntityId(leaderHero))
  local leaderPos = GetPosition(leaderHero)
  local posLeftAngle = -ToRadian(leaderOrient + 45)
  local posLeftBehind = { X = leaderPos.X + math.sin(posLeftAngle) * 300, Y = leaderPos.Y + math.cos(posLeftAngle) * 300 }
  local posRightAngle = -ToRadian(leaderOrient + 135)
  local posRightBehind = { X = leaderPos.X + math.sin(posRightAngle) * 300, Y = leaderPos.Y + math.cos(posRightAngle) * 300 }
  local positionsBehind = { posLeftBehind, posRightBehind }
  local posIndex = 1
  for heroIndex = 1, table.getn(rpgMove.heroes) do
    if not rpgMove.heroes[heroIndex].active then
      local sideHero = rpgMove.heroes[heroIndex].name
      if not AreEnemiesInArea(1, GetPosition(sideHero), 1000) then
        if GetDistance(sideHero, positionsBehind[posIndex]) > 300 then
          MoveDirectly(GetEntityId(sideHero), positionsBehind[posIndex])
        end
      end
      posIndex = 2
    end
  end
end

function GetPosInFrontOfEntity(_curPos, _rotation, _distance)
  local angle = -ToRadian(_rotation)
  local pos = _curPos
  local newPos = {}
  local sinus = math.sin(angle)
  local cosinus = math.cos(angle)
  newPos.X = pos.X + sinus * _distance
  newPos.Y = pos.Y + cosinus * _distance
  return newPos
end

function DisableRpgMovement()
  EndJob(rpgMove.JobId1)
  EndJob(rpgMove.JobId2)
  GUIUpdate_ResourceAmount = rpgMove.UpdateRessourceAmountOrig
  GUIUpdate_CommandGroup = rpgMove.UpdateCommandGroupOrig
  GameCallback_GUI_SelectionChanged = rpgMove.SelectionChangedOrig
  XGUIEng.DisableButton("Command_Attack", 0)
  XGUIEng.DisableButton("Command_Stand", 0)
  XGUIEng.DisableButton("Command_Defend", 0)
  XGUIEng.DisableButton("Command_Patrol", 0)
  XGUIEng.DisableButton("Command_Guard", 0)
  Display.SetRenderFogOfWar(1) 
  GUI.MiniMap_SetRenderFogOfWar(1)
  gvCamera.DefaultFlag = 1
  Camera.RotSetFlipBack(1)
  Display.SetRenderSky(0)
  rpgMove.active = false
end