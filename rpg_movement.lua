--------------------------------------------------------------------
--					                RPG Movement  								        --
--------------------------------------------------------------------
--[[
  Dependencies: 
    none
]]--
function InitRpgMovement(_entity, _startRot)
  rpgMove = {
    entity = GetEntityId(_entity),
    oldEntityPos = GetPosition(_entity),
    camPos = GetPosition(_entity),
    pressedCnt = 0,
    rotation = _startRot,
    step = 1,
    moveCnt = 0,
    curAngle = 13,
    angle = 13,
    turnAround = 0,
    move = false,
    UpdateRessourceAmountOrig = GUIUpdate_ResourceAmount,
    UpdateCommandGroupOrig = GUIUpdate_CommandGroup,
    lastTime = GUI.GetTimeMS(),
    avgFTime = 0
  }
  GUI.SelectEntity(rpgMove.entity)
  rpgMove.JobId = StartSimpleHiResJob("ControlMovement")
  Input.KeyBindDown(Keys.W, "RPGM_Move(1)", 15)
  Input.KeyBindUp(Keys.W, "RPGM_Move(2)", 15)
  
  Input.KeyBindDown(Keys.A, "RPGM_TurnLeft(1)", 15)
  Input.KeyBindUp(Keys.A, "RPGM_TurnLeft(2)", 15)
  
  Input.KeyBindDown(Keys.D, "RPGM_TurnRight(1)", 15)
  Input.KeyBindUp(Keys.D, "RPGM_TurnRight(2)", 15)
  
  Input.KeyBindDown(Keys.S, "RPGM_StopFig(false)", 15)
  Input.KeyBindUp(Keys.S, "RPGM_StopFig(true)", 15)
  
  GUIUpdate_ResourceAmount = function(_ressType, _amount)
    local curTime = GUI.GetTimeMS()
    local lastFrameRenderTime = curTime - rpgMove.lastTime
    if(lastFrameRenderTime > 1) then
      rpgMove.avgFTime = rpgMove.avgFTime + 0.1 * (lastFrameRenderTime - rpgMove.avgFTime)
    end
    rpgMove.lastTime = curTime
    local xMouse, yMouse = GUI.GetMousePosition()
    local xScreen, yScreen = GUI.GetScreenSize()
    local xRatio = xMouse / xScreen
    if xRatio < 0.05 or rpgMove.turnAround == 1 then
      rpgMove.rotation = rpgMove.rotation + 0.015 * rpgMove.avgFTime
      Camera.RotSetAngle(rpgMove.rotation)
    elseif xRatio > 0.95 or rpgMove.turnAround == 2 then
      rpgMove.rotation = rpgMove.rotation - 0.015 * rpgMove.avgFTime
      Camera.RotSetAngle(rpgMove.rotation)
    end
    
    
    local x, y, eZ = Logic.EntityGetPos(rpgMove.entity)
    local target = GetPosInFrontOfEntity({X = x, Y = y}, rpgMove.rotation, 300) 
  
    local diX = target.X - rpgMove.camPos.X
    local diY = target.Y - rpgMove.camPos.Y

    rpgMove.camPos.X = rpgMove.camPos.X + diX * 0.001 * rpgMove.avgFTime
    rpgMove.camPos.Y = rpgMove.camPos.Y + diY * 0.001 * rpgMove.avgFTime
    
    local qpos = GetPosInFrontOfEntity(rpgMove.camPos, rpgMove.rotation, 800)
    local dummy = Logic.CreateEntity(Entities.XD_ScriptEntity, qpos.X, qpos.Y, 0, 1)
    local _, _, lZ = Logic.EntityGetPos(dummy)
    local dZ = lZ - eZ
    Logic.DestroyEntity(dummy)
    if math.abs(dZ) < 1000 then
      local curZoomAngle = math.atan2(254 - dZ, 1100) * 57
      local deltaAngle = curZoomAngle - rpgMove.curAngle
      rpgMove.curAngle = rpgMove.curAngle + deltaAngle * 0.001 * rpgMove.avgFTime
      Camera.ZoomSetAngle(rpgMove.curAngle)
    end
    Camera.ScrollSetLookAt(qpos.X, qpos.Y)
    
    return rpgMove.UpdateRessourceAmountOrig(_ressType, _amount)
  end
  GUIUpdate_CommandGroup = function() end
  XGUIEng.DisableButton("Command_Attack", 1)
  XGUIEng.DisableButton("Command_Stand", 1)
  XGUIEng.DisableButton("Command_Defend", 1)
  XGUIEng.DisableButton("Command_Patrol", 1)
  XGUIEng.DisableButton("Command_Guard", 1)
  SetToRpgView()
  
end

function DisableRpgMovement()
  EndJob(rpgMove.JobId)
  GUIUpdate_ResourceAmount = rpgMove.UpdateRessourceAmountOrig
  GUIUpdate_CommandGroup = rpgMove.UpdateCommandGroupOrig
  XGUIEng.DisableButton("Command_Attack", 0)
  XGUIEng.DisableButton("Command_Stand", 0)
  XGUIEng.DisableButton("Command_Defend", 0)
  XGUIEng.DisableButton("Command_Patrol", 0)
  XGUIEng.DisableButton("Command_Guard", 0)
  Display.SetRenderFogOfWar(1) 
  GUI.MiniMap_SetRenderFogOfWar(1)
  gvCamera.DefaultFlag = 1
  Camera.RotSetFlipBack(1)
  rpgMove = nil
end

function SetToRpgView()
  gvCamera.DefaultFlag = 0
  Camera.RotSetFlipBack(0)
  Camera.RotSetAngle(rpgMove.rotation)
  GUI.SelectEntity(rpgMove.entity)
  Camera.ZoomSetDistance(1800)
  Camera.ZoomSetAngle(rpgMove.curAngle)
  Camera.ZoomSetFOV(50)
  Display.SetFarClipPlaneMinAndMax(0, 30000) 
  Display.SetRenderSky(1)
  Display.SetRenderFogOfWar(0) 
  GUI.MiniMap_SetRenderFogOfWar(0)

end

function RPGM_StopFig(_releasedButton)
  if rpgMove then
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
  if rpgMove then
    if _flag == 1 then
      rpgMove.turnAround = 1
    else
      rpgMove.turnAround = 0
    end
  end
end

function RPGM_TurnRight(_flag)
  if rpgMove then
    if _flag == 1 then
      rpgMove.turnAround = 2
    else
      rpgMove.turnAround = 0
    end
  end
end

function RPGM_Move(_flag)
  if rpgMove then
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
  -- control move cmd
  if rpgMove.moveCnt ~= 0 then
    rpgMove.moveCnt = rpgMove.moveCnt - 1
  elseif rpgMove.move then
    local x, y, oldZ = Logic.EntityGetPos(rpgMove.entity)
    local pos = {X = x, Y = y}
    local newPos = GetPosInFrontOfEntity(pos, rpgMove.rotation, 400) 
    Move(rpgMove.entity, newPos)
    rpgMove.moveCnt = 3
  end
  if rpgMove.turnAround > 0 then
    if rpgMove.pressedCnt < 8 then
      rpgMove.pressedCnt = rpgMove.pressedCnt + 1
    end
  else
    rpgMove.pressedCnt = 0
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