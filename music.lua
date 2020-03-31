--------------------------------------------------------------------
--					             Music									                  --
--------------------------------------------------------------------
--[[
  Dependencies: 
    none   
]]--
function StartMusic(_name, _path)
  LocalMusic.OwnMusic = true
  LocalMusic.SongLength = 0
  LocalMusic.OwnSong = _name
  LocalMusic.OwnPath = _path or nil
end

function StopMusic()
	Stream.Stop()
	Music.Stop()
	LocalMusic.SongLength = 0
end
LocalMusic.OwnSongs = {}

function InitOwnMusic(_path, _musicset)
  LocalMusic.BriefingActive = false
  LocalMusic.OwnSetPath = _path
  if _musicset then
    LocalMusic.UseSet = _musicset
  else
    LocalMusic.UseSet = EUROPEMUSIC
  end
  LocalMusic.SongLength = 0
end

function LocalMusic_UpdateMusic()
	if Logic.PlayerGetGameState(1) ~= 1 then
		Stream.Stop()
		return
	end
	if not ((IsBriefingActive ~= nil and IsBriefingActive() == true ) or (IsCutsceneActive~= nil and IsCutsceneActive() == true)) and LocalMusic.BriefingActive then
		LocalMusic.SongLength = 0
		LocalMusic.BriefingActive = false
	end
	if LocalMusic.BattlesOnTheMap == 0 then
		if  LocalMusic.SongLength  > Logic.GetTime() then	 
			return
		end	
	end
	local Weather = Logic.GetWeatherState()
	if Weather == 1 then
		Weather = "summer"
	else
		Weather = "snow"
	end
	if not LocalMusic.OwnMusic then
		local SetToUse
		local OwnSet
		if LocalMusic.BattlesOnTheMap == 1 then
			SetToUse = LocalMusic.SetBattle
		elseif LocalMusic.BattlesOnTheMap == 2 then
			SetToUse = LocalMusic.SetEvilBattle
		elseif LocalMusic.BattlesOnTheMap == 0 then
			SetToUse = LocalMusic.UseSet[Weather]
			if LocalMusic.UseSet.OwnSet then
				OwnSet = true
			end
		end
		if (IsBriefingActive ~= nil and IsBriefingActive() == true ) or (IsCutsceneActive~= nil and IsCutsceneActive() == true) then
			SetToUse = LocalMusic.SetBriefing
			LocalMusic.BriefingActive = true
		end
		local SongAmount = table.getn(SetToUse)
		local Random = 1 + XGUIEng.GetRandom(SongAmount-1)
		local SongToPlay
		local path = Folders.Music
		if OwnSet then
			path = LocalMusic.OwnSetPath
		end
		SongToPlay = path .. SetToUse[Random][1]
		Music.Start(SongToPlay, 127)
		LocalMusic.SongLength =  Logic.GetTime() + SetToUse[Random][2] + 2
	else
		local SongToPlay
		local path = Folders.Music
		if LocalMusic.OwnPath then
			path = LocalMusic.OwnPath
		end
		SongToPlay = path .. LocalMusic.OwnSong
		Music.Start(SongToPlay, 127)
		LocalMusic.SongLength =  Logic.GetTime() + LocalMusic.OwnSongs[LocalMusic.OwnSong] + 2
	end
	LocalMusic.BattlesOnTheMap = 0
	LocalMusic.OwnMusic = false
end