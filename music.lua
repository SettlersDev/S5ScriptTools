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

LocalMusic.OwnSongs = {
  ["ac1.mp3"] = 180 + 57,
  ["intro1.mp3"] = 180 + 14,
  ["Failed.mp3"] = 29,
  ["15_Mediterranean_Summer1.mp3"] = 120 + 45,
  ["20_Evelance_Summer2.mp3"] = 2*60 + 33,
  ["daydream.mp3"] = 117,
  ["04_CombatMediterranean1.mp3"] = 60 + 53,
  ["nyancat.mp3"] = 3*60 + 36
}
function InitOwnMusic(_path, _musicset)
  LocalMusic.BriefingActive = false
  LocalMusic.OwnSetPath = _path
  EpicMusic = {
    ownSet = true,
    summer = {									
      { "destiny.mp3", 138 },
      { "forestofstones.mp3", 92 },
      { "propaganda.mp3", 108 },
      { "homecoming.mp3", 114 },
      { "daydream.mp3", 117 },
    },
    snow = {
      { "destiny.mp3", 138 },
      { "forestofstones.mp3", 92 },
      { "propaganda.mp3", 108 },
      { "homecoming.mp3", 114 },
      { "daydream.mp3", 117 },
    }
  }
  CelticMusic = {
    ownSet = true,
    summer = {
      { "celticmusiclegend.mp3", 3*60 + 46 },
      { "celticmusicprophecy.mp3", 5*60 + 34 }
    },
    snow = {
      { "celticmusiclegend.mp3", 3*60 + 46 },
      { "celticmusicprophecy.mp3", 5*60 + 34 }
    }
  }
  BattleSet = {
    summer = {
      { "03_CombatEurope1.mp3", 117 },
      { "04_CombatMediterranean1.mp3", 113 },
      { "05_CombatEvelance1.mp3", 117 }
    },
    snow = {
      { "03_CombatEurope1.mp3", 117 },
      { "04_CombatMediterranean1.mp3", 113 },
      { "05_CombatEvelance1.mp3", 117 }
    }
  }
  if _musicset then
    LocalMusic.UseSet = _musicset
  else
    LocalMusic.UseSet = CelticMusic
  end
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
		local UseStream
		UseStream = LocalMusic.UseSet.ownSet
		if LocalMusic.BattlesOnTheMap == 1 then
			SetToUse = LocalMusic.SetBattle
		elseif LocalMusic.BattlesOnTheMap == 2 then
			SetToUse = LocalMusic.SetEvilBattle
		elseif LocalMusic.BattlesOnTheMap == 0 then
			SetToUse = LocalMusic.UseSet[Weather]
		end
		if (IsBriefingActive ~= nil and IsBriefingActive() == true ) or (IsCutsceneActive~= nil and IsCutsceneActive() == true) then
			SetToUse = LocalMusic.SetBriefing
			UseStream = false
			LocalMusic.BriefingActive = true
		end
		local SongAmount = table.getn(SetToUse)
		local Random = 1 + XGUIEng.GetRandom(SongAmount-1)
		local path = Folders.Music 
		local SongToPlay
		if UseStream then
			SongToPlay = LocalMusic.OwnSetPath .. SetToUse[Random][1]
			Stream.Start(SongToPlay, 127)
			Music.Stop()
		else
			SongToPlay = path .. SetToUse[Random][1]
			Sound.StartMusic(SongToPlay, 127)
			Stream.Stop()
		end
		LocalMusic.SongLength =  Logic.GetTime() + SetToUse[Random][2] + 2
	else
		local SongToPlay
		if LocalMusic.OwnPath then
			SongToPlay = LocalMusic.OwnPath .. LocalMusic.OwnSong
			Stream.Start(SongToPlay, 127)
			Music.Stop()
		else
			SongToPlay = Folders.Music .. LocalMusic.OwnSong
			Stream.Stop()
			Sound.StartMusic(SongToPlay, 127)
		end
		LocalMusic.SongLength =  Logic.GetTime() + LocalMusic.OwnSongs[LocalMusic.OwnSong] + 2
	end
	LocalMusic.BattlesOnTheMap = 0
	LocalMusic.OwnMusic = false
end