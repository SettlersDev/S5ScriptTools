--------------------------------------------------------------------
--					                Speech  								              --
--------------------------------------------------------------------
--[[
  Dependencies: 
    bb_comforts.lua
    timer.lua
    cinematic.lua
]]--
function SetupSpeech(_voicePath)
	
	npcSpeech = {}
	speech_convToAdd = {}
	speech_selectedEntities = {}
	SPEECH_ROTATION = -45
	SPEECH_ZOOM = 1000
	SPEECH_ANGLE = 45
	SPEECH_VOICE_PATH = _voicePath

	XGUIEng.ShowWidget("CinematicMC_Headline", 0)
	XGUIEng.ShowWidget("CinematicMC_Text", 0)
	GameCallback_Escape_OrigSpeech = GameCallback_Escape
	GameCallback_NPCInteraction_OrigBrief = GameCallback_NPCInteraction
	GameCallback_NPCInteraction = function(heroId, npcId)
		if npcSpeech[npcId] then
      if npcSpeech[npcId].onlySpeaksTo then
        for i = 1, table.getn(npcSpeech[npcId].onlySpeaksTo) do
          if heroId == GetEntityId(npcSpeech[npcId].onlySpeaksTo[i]) then
            bb_StartSpeech(npcId)
            FaceEachOther(heroId, npcId)
            return
          end
        end
        if npcSpeech[npcId].wrongHeroMessage then
          Message(npcSpeech[npcId].wrongHeroMessage)
        end
      else
        bb_StartSpeech(npcId)
        FaceEachOther(heroId, npcId) 
      end
		else
			GameCallback_NPCInteraction_OrigBrief(heroId, npcId)
		end
	end
	BriefingMCButtonSelected = function(_index) 
    if Speech_Continue() then
      return
    end
		local count = 1
		local newConvIndex
		for text, subSpeechTable in pairs(speech_Conv[speech_curPage].mc) do
			if count == _index then
				local tableToChange = subSpeechTable
				local page = speech_curPage + 1
				while speech_Conv[page] do
					table.insert(tableToChange.default, speech_Conv[page])
					page = page + 1
				end
				speech_currentSpeaker["MultipleChoice"] = tableToChange
			end
			count = count + 1
		end
		IsWaitingForMCSelection = Speech_IsWaitingForMCSelection
		speech_active = false
		if speech_currentSpeaker.id then
      bb_StartSpeech(speech_currentSpeaker.id, "MultipleChoice")
    else
      bb_StartDialog(speech_currentSpeaker)
    end
		XGUIEng.ShowWidget("CinematicMC_Button1", 1)
		XGUIEng.ShowWidget("CinematicMC_Button2", 0)
		
	end
	InitSpeechIfNear()
end

function Speech_ASP(_title, _text, _pos, _voice, _rot, _angle, _zoom, _action, _mc, _nextPageTime)
	return { 
		title = _title,
		text = _text,
		pos = _pos,
		rot = _rot,
		angle = _angle,
		zoom = _zoom,
		action = _action,
		mc = _mc,
		nextPageTime = _nextPageTime,
		voice = _voice
	}
end

function AddConvToSpeaker(_speaker, _conv)
  assert(type(_speaker) == "table")
  table.insert(_speaker, _conv)
  EnableNpcMarker(_speaker.id)
end

function CreateSpeaker(_speaker)
	assert(type(_speaker) == "table")
	npcSpeech[_speaker.id] = _speaker
	EnableNpcMarker(_speaker.id)
end

function RemoveSpeaker(_speaker)
  local eId = GetEntityId(_speaker)
  npcSpeech[eId] = nil
  DisableNpcMarker(eId)
end

function bb_StartDirectSpeech(_speaker)
	local id = GetEntityId(_speaker)
	bb_StartSpeech(id)
end

function bb_StartDialog(_conv)
	assert(type(_conv) == "table", "Speech: invalid dialog")
	bb_StartSpeech(_conv)
end

function bb_StartSpeech(_id, _convIndex)
  local selectedEnt = { GUI.GetSelectedEntities() }
  for i = 1, table.getn(selectedEnt) do
    table.insert(speech_selectedEntities, selectedEnt[i])
  end
  if speech_active then
    table.insert(speech_convToAdd, { id = _id, convIndex = _convIndex })
    return
  else
    speech_active = true
  end
  speech_camPos = {Camera.ScrollGetLookAt()}
	speech_currConvIndex = _convIndex or 1
  local currentSpeaker = {}
  if type(_id) == "table" then
    currentSpeaker[speech_currConvIndex] = _id
  else
    currentSpeaker = npcSpeech[_id]
  end
  speech_currentSpeaker = currentSpeaker
	speech_Remove = true
	speech_finished = true
	speech_continue = currentSpeaker[speech_currConvIndex].continue
	if currentSpeaker[speech_currConvIndex].condition then
		if currentSpeaker[speech_currConvIndex].condition() then
			speech_Conv = currentSpeaker[speech_currConvIndex].fullfilled
		else
			speech_Conv = currentSpeaker[speech_currConvIndex].unfullfilled
			if not currentSpeaker[speech_currConvIndex].switchOnly then
        speech_Remove = false
        speech_finished = false
        speech_continue = false
      end
		end
	else
		speech_Conv = currentSpeaker[speech_currConvIndex].default	
	end
	if not speech_Conv then
		return
	end
	bb_InitSpeech()
end

function bb_InitSpeech()
	speech_curPage = 0
	EditCinematic()
	Speech_NextPage()
	GameCallback_Escape = GameCallback_Escape_OrigSpeech
	GameCallback_Escape_OrigSpeech = GameCallback_Escape
	GameCallback_Escape = Speech_Continue
end

function Speech_Continue()
  if (not speech_Conv[speech_curPage].mc) then
    if (not speech_Conv[speech_curPage].nextPageTime) and (not speech_Conv[speech_curPage].voice) then
      Speech_NextPage()
    end
    return true
  end
end

function EndSpeech()
	-- reselect entities
  for i = 1, table.getn(speech_selectedEntities) do
    if speech_selectedEntities[1] and (not IsDead(speech_selectedEntities[1])) then
      GUI.SelectEntity(speech_selectedEntities[1])
    end
    table.remove(speech_selectedEntities, 1)
  end
  -- get finished function
	if speech_finished then
    if speech_currentSpeaker[1].finished then
      Speech_FinishedFunction = speech_currentSpeaker[1].finished
    end
    if speech_currConvIndex == "MultipleChoice" then
      if speech_currentSpeaker[speech_currConvIndex].finished then
        Speech_FinishedFunction = speech_currentSpeaker[speech_currConvIndex].finished
      end
    end
  end
  
  -- removing and repeating
	if speech_currentSpeaker[speech_currConvIndex].repeatConv then
		speech_Remove = not speech_currentSpeaker[speech_currConvIndex].repeatConv()
	end
	if speech_Remove then
		if speech_currConvIndex == "MultipleChoice" then
			speech_currentSpeaker[speech_currConvIndex] = nil
			local removeAll = true
			if speech_currentSpeaker[1].repeatConv then
				removeAll = not speech_currentSpeaker[1].repeatConv()
			end
			if removeAll then
				table.remove(speech_currentSpeaker, 1)
			end
		else
			table.remove(speech_currentSpeaker, speech_currConvIndex)
		end
	end
	-- disable npc marker if no conv is stacked
	if not speech_currentSpeaker[1] and speech_currentSpeaker.id then
		DisableNpcMarker(speech_currentSpeaker.id)
	end
		
	-- reset
  ResetCinematicMCButtons()
	speech_Conv = nil
	GameCallback_Escape = GameCallback_Escape_OrigSpeech
	bb_SetCinematicMode(0)
	Camera.ScrollSetLookAt(speech_camPos[1], speech_camPos[2])
	speech_active = false
	
	-- check if finished func is existing
	if Speech_FinishedFunction then
    Speech_FinishedFunction()
    Speech_FinishedFunction = nil
	end
	
	-- check if should continue
	if speech_continue and speech_currentSpeaker.id then
		bb_StartSpeech(speech_currentSpeaker.id)
		return
	end
	
	-- check if convs are stacked
	if speech_convToAdd[1] then
    bb_StartSpeech(speech_convToAdd[1].id, speech_convToAdd[1].convIndex)
    table.remove(speech_convToAdd, 1)
    return
  end
end

function Speech_SetupPage()
	if speech_Conv[speech_curPage].pos then
		Camera.FollowEntity(GetEntityId(speech_Conv[speech_curPage].pos)) 
	end
	Camera.RotSetAngle(speech_Conv[speech_curPage].rot or SPEECH_ROTATION)
	Camera.ZoomSetDistance(speech_Conv[speech_curPage].zoom or SPEECH_ZOOM)
	Camera.ZoomSetAngle(speech_Conv[speech_curPage].angle or SPEECH_ANGLE)
	XGUIEng.ShowWidget("Cinematic_Text", 1)
	bb_SetCinematicMode(1)
  if speech_Conv[speech_curPage].action then
		speech_Conv[speech_curPage].action()
	end
end

function Speech_NextPage()
	speech_curPage = speech_curPage + 1
	XGUIEng.ShowWidget("CinematicMC_Button1", 1)
	XGUIEng.ShowWidget("CinematicMC_Button2", 0)
	
	if not speech_Conv[speech_curPage] then
		EndSpeech()
		return true
	else
		XGUIEng.SetText("Cinematic_Headline", Umlaute(speech_Conv[speech_curPage].title))
		XGUIEng.SetText("Cinematic_Text", Umlaute(speech_Conv[speech_curPage].text))
		XGUIEng.ShowWidget("CinematicMC_Text", 1)
		if speech_Conv[speech_curPage].mc then
			Speech_IsWaitingForMCSelection = IsWaitingForMCSelection
			IsWaitingForMCSelection = function() return true end
			Mouse.CursorShow()
			briefingState.waitingForMC = true
			ResetCinematicMCButtons()
			XGUIEng.ShowWidget("CinematicMC_Button1", 1)
			XGUIEng.ShowWidget("CinematicMC_Button2", 1)
			XGUIEng.ShowWidget("CinematicMC_Text", 0)
			local count = 1
			for k, v in pairs(speech_Conv[speech_curPage].mc) do
				XGUIEng.SetText("CinematicMC_Button"..count, Umlaute(k))
				count = count + 1
			end
		else
      XGUIEng.SetWidgetPositionAndSize("CinematicMC_Button1", 0, 0, 2000, 2000)
      XGUIEng.SetText("CinematicMC_Button1", "")
      for i = 0, 2 do
        XGUIEng.SetMaterialColor("CinematicMC_Button1", i, 255, 255, 255, 0)
      end
    end
		Speech_SetupPage()
		if speech_Conv[speech_curPage].voice then
			Stream.Start(SPEECH_VOICE_PATH .. speech_Conv[speech_curPage].voice, 127)
      XGUIEng.ShowWidget("CinematicMC_Text", 0)
			RegisterTimer(math.ceil(Stream.GetDuration() + 1), function() Speech_NextPage(); end)
    elseif speech_Conv[speech_curPage].nextPageTime then
      XGUIEng.ShowWidget("CinematicMC_Text", 0)
      RegisterTimer(speech_Conv[speech_curPage].nextPageTime, function() Speech_NextPage(); end)
    end
		return false
	end
end

function bb_SetCinematicMode(_flag)
	if _flag == 1 then
		ToggleCinematicBars(1)
		XGUIEng.ShowWidget("Cinematic", 1)
		XGUIEng.ShowWidget("Cinematic_Text", 1)
		XGUIEng.ShowWidget("Cinematic_Headline", 1)
		XGUIEng.ShowWidget("Cinematic_Headline", 1)
		XGUIEng.ShowWidget("Normal", 0)
		XGUIEng.ShowWidget("3dOnScreenDisplay", 0)		
		GUI.SetFeedbackSoundOutputState(0)
		GUIAction_GoBackFromHawkViewInNormalView()
		gvCamera.DefaultFlag = 0
		Camera.SetControlMode(1)
		Camera.InitCameraFlight()
		Camera.RotSetFlipBack(0)
		Display.SetRenderFogOfWar(0)
		GUI.ClearSelection()
		GUI.CancelState()
		GUI.ActivateCutSceneState()
		Display.SetRenderSky( 1 )
	else 
		ToggleCinematicBars(0)
		Display.SetRenderFogOfWar(1)
    Camera.StopCameraFlight()
    Camera.SetControlMode(0)
		Camera.RotSetAngle(-45)
		Camera.RotSetFlipBack(1)
		gvCamera.DefaultFlag = 1	
		Display.SetRenderSky(0)
		GUI.ActivateSelectionState()
		GUI.SetFeedbackSoundOutputState(1)
		XGUIEng.ShowWidget("Normal", 1)
		XGUIEng.ShowWidget("Cinematic", 0)
		XGUIEng.ShowWidget("3dOnScreenDisplay", 1)
	end
end
--------------------------------------------------------------------
--							    SpeechAddon_SpeechIfNear 						          --					
--------------------------------------------------------------------
function InitSpeechIfNear()
  speechIfNear = {}
  speechIfNearLastConv = {}
  speechIfNearIdCnt = 0
  --[[
  newSIF = {
    conv = conversation, -- table mit einer conversation
    pos = "watchman",    -- if near pos then conversation and return
    ent = {"fooman", "dario", "kyrill"}, -- table of entities who should return if near
    distance = 1000   -- distance in scm, which is controlled
  }
  ]]--
end

function AddSpeechIfNear(_t)
  speechIfNearIdCnt = speechIfNearIdCnt + 1
  local newSIF = {
    conv = _t.conv,
    ent = _t.ent
  }
  if type(_t.pos) == "table" then
    newSIF.pos = _t.pos
  else
    newSIF.pos = GetPosition(_t.pos)
  end
  newSIF.id = speechIfNearIdCnt
  newSIF.distance = _t.distance
  table.insert(speechIfNear, newSIF)
  
  if JobIsRunning(speechIfNear_JobId) ~= 1 then
    speechIfNear_JobId = StartSimpleJob("ControlSpeechIfNear")
  end
  return speechIfNearIdCnt
end

function RemoveSpeechIfNear(_id)
  for i = 1, table.getn(speechIfNear) do
    if speechIfNear[i].id == _id then
      table.remove(speechIfNear, i)
      return true
    end
  end
  return false
end

function ControlSpeechIfNear()
  if not speechIfNear[1] then
    return true
  end
  if not speech_active then
    for i = 1, table.getn(speechIfNear) do
      for o = 1, table.getn(speechIfNear[i].ent) do
        local ePos = GetPosition(speechIfNear[i].ent[o])
        local conv = speechIfNear[i].conv
        if GetDistance(ePos, speechIfNear[i].pos) < speechIfNear[i].distance then
          SpeechIfNear_StopAll()
          if type(conv) == "table" then
            bb_StartDialog(conv)
          else
            bb_StartDirectSpeech(conv)
          end
        end
      end
    end
  end
end

function SpeechIfNear_StopAll()
  for i = 1, table.getn(speechIfNear) do
    for o = 1, table.getn(speechIfNear[i].ent) do
      StopFig(speechIfNear[i].ent[o])
    end
  end
end