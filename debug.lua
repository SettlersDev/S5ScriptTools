---------------------------------------------------------------------------------------
--                                    Debugger                                       --
---------------------------------------------------------------------------------------
--[[
  Dependencies: 
    bb_comforts.lua

]]--
function SetupDebugger()
  InitDebugger()
  AddOnSaveGameLoaded(InitDebugger)
end

function InitDebugger()
	SetCallbacks()
	debug_testModeActive = false
  SetKeyBindings()
end

function SetCallbacks()
  GameCallback_GUI_ChatStringInputDone = function (command)
    local cmd = loadstring(command)
    cmd()
  end
end

function SetKeyBindings()
	Input.KeyBindDown(Keys.ModifierControl + Keys.ModifierShift + Keys.ModifierAlt + Keys.Multiply, "ToggleTestMode()", 15)
	Input.KeyBindDown(Keys.U, "TestMode_SpeedUp()", 15)
  Input.KeyBindDown(Keys.R, "TestMode_ResetSpeed()", 15)
  Input.KeyBindDown(Keys.C, "TestMode_ResetCinematicMode()", 15)
  Input.KeyBindDown(Keys.T, "TestMode_CreateTroops()", 15)
  Input.KeyBindDown(Keys.P, "TestMode_ShowChatInput()", 15)
end

function TestMode_ShowChatInput()
  if debug_testModeActive then
    XGUIEng.ShowWidget("ChatInput", 1)
  end
end

function ToggleTestMode()
  debug_testModeActive = not debug_testModeActive
  if debug_testModeActive then
    Message("debug mode active")
  else
    Message("debug mode inactive")
  end 
end
function TestMode_SpeedUp()
  if debug_testModeActive then
    Game.GameTimeSpeedUp()
  end
end
function TestMode_ResetSpeed()
  if debug_testModeActive then
    Game.GameTimeReset()
  end
end
function TestMode_ResetCinematicMode()
  if debug_testModeActive then
    Interface_SetCinematicMode(0)
  end
end
function TestMode_CreateTroops()
  if debug_testModeActive then
    assert(global.mainHero, "Debug: A Hero has to be defined")
    CreateMilitaryGroup(1, Entities.PU_LeaderBow4, 8, GetPosition(global.mainHero))
  end
end