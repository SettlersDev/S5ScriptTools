---------------------------------------------------------------------------------------
--                                    cinematic                                      --
---------------------------------------------------------------------------------------
--[[
  Dependencies: 
    bb_comforts.lua

]]--
function SetupCinematic()
  EditCinematic()
  AddOnSaveGameLoaded(EditCinematic)
end

function EditCinematic()
	XGUIEng.ShowWidget("CinematicMiniMapOverlay", 0)
	XGUIEng.ShowWidget("CinematicMiniMap", 0)
	XGUIEng.ShowWidget("CinematicFrameBG", 0)
	XGUIEng.ShowWidget("CinematicFrame", 0)
	
	XGUIEng.ShowWidget("CinematicBar00", 1)
	XGUIEng.ShowWidget("CinematicBar01", 1)
	XGUIEng.ShowWidget("CinematicBar02", 1)
	
	XGUIEng.ShowWidget("CinematicMC_Button1", 1)
	XGUIEng.ShowWidget("CinematicMC_Button2", 1)
	
	XGUIEng.SetWidgetPositionAndSize("Cinematic", 0, 400, 2000, 2000)
	
	XGUIEng.SetWidgetPositionAndSize("CinematicMC_Container", 0, 0, 2000, 2000)
	XGUIEng.SetWidgetPositionAndSize("CinematicMC_Headline", 900, 702, 50, 20)
	XGUIEng.SetWidgetPositionAndSize("CinematicMC_Text", 100, 672, 590, 100)
	XGUIEng.SetText("CinematicMC_Text", gvCol.hellgrau.." (Weiter mit Klick oder ESC)")
	XGUIEng.ShowWidget("CinematicMC_Container", 1)
	XGUIEng.ShowWidget("CinematicMC_Text", 1)
	XGUIEng.ShowWidget("CinematicMC_Headline", 0)
	RestoreBriefWindow()
	ResetCinematicMCButtons()
	Display.SetFarClipPlaneMinAndMax(0, 30000)
	Camera.ZoomSetFOV(50)
end


function ResetCinematicMCButtons()
  XGUIEng.SetWidgetPositionAndSize("CinematicMC_Button1", 700, 572, 300, 50)
	XGUIEng.SetWidgetPositionAndSize("CinematicMC_Button2", 700, 632, 300, 50)
	for i = 0, 2 do
    XGUIEng.SetMaterialColor("CinematicMC_Button1", i, 192, 192, 192, 50)
    XGUIEng.SetMaterialColor("CinematicMC_Button2", i, 192, 192, 192, 50)
  end
  XGUIEng.ShowWidget("CinematicMC_Button1", 0)
	XGUIEng.ShowWidget("CinematicMC_Button2", 0)
end

function ToggleCinematicBars(_flag)
	XGUIEng.ShowWidget("CinematicBar00", _flag)
	XGUIEng.ShowWidget("CinematicBar01", _flag)
	XGUIEng.ShowWidget("CinematicBar02", _flag)
end

function RestoreBriefWindow()
  XGUIEng.ShowWidget("CinematicMC_Text", 1)
	XGUIEng.SetWidgetPositionAndSize("Cinematic_Headline", 150, 537, 500, 20)
	XGUIEng.SetWidgetPositionAndSize("Cinematic_Text", 100, 592, 590, 100)
	XGUIEng.SetWidgetPositionAndSize("CinematicBar00", 0, 700, 2000, 200)
	XGUIEng.SetWidgetPositionAndSize("CinematicBar01", 0, 485, 2000, 200)
	XGUIEng.SetWidgetPositionAndSize("CinematicBar02", 0, 530, 2000, 185)
	XGUIEng.SetMaterialColor("CinematicBar00", 0, 137, 87, 54, 250)
	XGUIEng.SetMaterialColor("CinematicBar01", 0, 137, 87, 54, 250)
	XGUIEng.SetMaterialColor("CinematicBar02", 0, 0, 0, 0, 150)
	
end

function StoryWindow(_text, _noCinematicBars, _fixedTitle)
	assert(type(_text) == "table", "CinematicTitle: text is no table")
	XGUIEng.ShowWidget("Cinematic", 1)
	XGUIEng.ShowWidget("CinematicMC_Text", 0)
	XGUIEng.SetText("Cinematic_Headline", "")
	XGUIEng.SetText("Cinematic_Text", "")
	XGUIEng.SetWidgetPositionAndSize("Cinematic_Headline", 190, 325, 250, 20)
	XGUIEng.SetWidgetPositionAndSize("Cinematic_Text", 350, 350, 590, 100)
  if _noCinematicBars then
    ToggleCinematicBars(0)
  else
    ToggleCinematicBars(1)
    XGUIEng.SetWidgetPositionAndSize("CinematicBar00", 0, 350, 2000, 200)
    XGUIEng.SetWidgetPositionAndSize("CinematicBar01", 0, 185, 2000, 200)
    XGUIEng.SetWidgetPositionAndSize("CinematicBar02", 0, 230, 2000, 300)
  end
	title_showCnt = 0
	title_text = _text
	title_dir = 1
	title_txtCnt = 1
	title_fixedTitle = _fixedTitle
	if title_text[title_txtCnt].voice then
		Stream.Start(Global.Paths.Voice .. title_text[title_txtCnt].voice, 127)
		title_text[title_txtCnt].delay = Stream.GetDuration() * 10 - 10
	end
	StartSimpleHiResJob("TitleControl")
end

function TitleControl()
  XGUIEng.SetWidgetPositionAndSize("CinematicBar00", 0, 350, 2000, 200)
	XGUIEng.SetWidgetPositionAndSize("CinematicBar01", 0, 185, 2000, 200)
	XGUIEng.SetWidgetPositionAndSize("CinematicBar02", 0, 230, 2000, 300)
	local step = 15 * title_dir
	if (title_text[title_txtCnt].delay > 0) and (title_showCnt == 255) then
		title_text[title_txtCnt].delay = title_text[title_txtCnt].delay - 1
		return false
	end
	title_showCnt = title_showCnt + step
	if title_fixedTitle then
		local gamma = title_showCnt
		if title_txtCnt > 1 and title_txtCnt < table.getn(title_text)
				or title_txtCnt <= 1 and title_dir == -1 
				or title_txtCnt >= table.getn(title_text) and title_dir == 1 then
			gamma = 255
		end		
		XGUIEng.SetText("Cinematic_Headline", Umlaute(" @color:255,255,255,"..gamma.." @center " .. title_fixedTitle))
	else
		XGUIEng.SetText("Cinematic_Headline", Umlaute(" @color:255,255,255,"..title_showCnt.." @center "..title_text[title_txtCnt].title or " "))
	end
	XGUIEng.SetText("Cinematic_Text", Umlaute(" @color:255,255,255,"..title_showCnt.." "..title_text[title_txtCnt].text or " "))
	if title_showCnt == 255 then
		title_dir = -1
	end
	if title_showCnt == 0 then
		title_txtCnt = title_txtCnt + 1
		title_dir = 1
		if not title_text[title_txtCnt] then
			RestoreBriefWindow()
			XGUIEng.ShowWidget("Cinematic", 0)
			if title_text.finished then
        title_text.finished()
      end
			return true
		elseif title_text[title_txtCnt].voice then
			Stream.Start(Global.Paths.Voice .. title_text[title_txtCnt].voice, 127)
			title_text[title_txtCnt].delay = Stream.GetDuration() * 10 - 10
		end
	end
end