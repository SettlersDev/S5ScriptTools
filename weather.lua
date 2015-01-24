--------------------------------------------------------------------
--					                Weather       					              --
--------------------------------------------------------------------
--[[
  Dependencies: 
    regions.lua
    modifiedgui.xml
]]--
Weather = {
  LightX = 0,
  LightY = 0,
  LightZ = 0,
  LightDiffuse = 0,
  GfxSets = {}
}

function SetupGfxSet(_gfxId, _properties)
  Weather.GfxSets[_gfxId] = _properties
  local skybox = _properties.SkyBox
  Display.GfxSetSetSkyBox(_gfxId, skybox.TransitionStart, skybox.TransitionEnd, skybox.Name)
  
  local fog = _properties.Fog
	Display.GfxSetSetFogParams(_gfxId, fog.TransitionStart, fog.TransitionEnd, fog.Flag, fog.Color.R, fog.Color.G, fog.Color.B, fog.Start, fog.End)
	
	local light = _properties.Light
	Display.GfxSetSetLightParams(_gfxId, light.TransitionStart, light.TransitionEnd, light.Position.X, light.Position.Y, light.Position.Z, light.Ambient.R, light.Ambient.G, light.Ambient.B, light.Diffuse.R, light.Diffuse.G, light.Diffuse.B)
	
	local raineffectstatus = _properties.RainEffectStatus
	Display.GfxSetSetRainEffectStatus(_gfxId, raineffectstatus.TransitionStart, raineffectstatus.TransitionEnd, raineffectstatus.Flag)
	
	local snowstatus = _properties.SnowStatus
  Display.GfxSetSetSnowStatus(_gfxId, snowstatus.TransitionStart, snowstatus.TransitionEnd, snowstatus.Flag)
  
  local snoweffectstatus = _properties.SnowEffectStatus
  Display.GfxSetSetSnowEffectStatus(_gfxId, snoweffectstatus.TransitionStart, snoweffectstatus.TransitionEnd, snoweffectstatus.Flag)
  --[[
  SampleProperties = {
    SkyBox = {
      TransitionStart = 0.2,
      TransitionEnd = 1,
      Name = "YSkyBox01"
    },
    Fog = {
      TransitionStart = 0,
      TransitionEnd = 1,
      Flag = 1,
      Color = { R = 182, G = 182, B = 182 }
      Start = 6000,
      End = 20000
    },
    Light = {
      TransitionStart = 0,
      TransitionEnd = 1,
      Position = { X = 0, Y = 50, Z = 19 }
      Ambient = { R = 100, G = 100, B = 100 }
      Diffuse = { R = 255, G = 255, B = 255 }
    },
    RainEffectStatus = {
      TransitionStart = 0,
      TransitionEnd = 1,
      Flag = 0
    },
    SnowStatus = {
      TransitionStart = 0,
      TransitionEnd = 1,
      Flag = 0
    },
    SnowEffectStatus = {
      TransitionStart = 0,
      TransitionEnd = 0.8,
      Flag = 0
    },
  }
  ]]--
end

function SetupWeatherZones(_weatherZones)
  Weather.WeatherZones = _weatherZones
  for zoneName, zone in pairs(Weather.WeatherZones) do
    RegisterRegion(zone.RegionWpPrefix, function(_zone) SetActiveZone(_zone); end, function() end, zone)
  end
  SetCycTimes()
end 

function SetCycTimes()
	for zoneName, zone in pairs(Weather.WeatherZones) do
		local cycTime = 0
		for i = 1, table.getn(zone.Weathers) do
			zone.Weathers[i].cycStartTime = cycTime
			cycTime = cycTime + zone.Weathers[i].Duration
		end
		zone.cycTime = cycTime
	end
end

function SetWeathersInZone(_zone, _weathers)
  Weather.WeatherZones[_zone].Weathers = _weathers
	SetCycTimes()
	if Weather.ActiveZone == _zone then
		SetWeather(_zone)
	end
end

function SetWeather(_zone, _quickTransition)
	local timeToNext
	local curWeather
	local transDuration
	if _zone.cycTime < 0 then
		timeToNext = 5*60*60
		curWeather = _zone.Weathers[1]
	else
		local timeInCyc = math.mod(math.ceil(Logic.GetTime()), _zone.cycTime)
		for i = table.getn(_zone.Weathers), 1, -1 do
			if timeInCyc >= _zone.Weathers[i].cycStartTime then
				curWeather = _zone.Weathers[i]
				timeToNext = curWeather.Duration - (timeInCyc - curWeather.cycStartTime) + 1			
				break
			end
		end
	end
	
	if _quickTransition then
		transDuration = 1
	else
		transDuration = curWeather.TransitionLength or 1
	end
	
	Weather.CurrentGfxSet = curWeather.GfxId
	
	Logic.AddWeatherElement(curWeather.WeatherType, timeToNext, 0, curWeather.GfxId, 0, transDuration)
	RegisterTimer(timeToNext, SetWeather, { param = _zone })
end

function SetActiveZone(_zone)
	Weather.ActiveZone = _zone
	UnregisterTimer(SetWeather)
	SilenceMentor()
	SetWeather(_zone, true)
end

function SilenceMentor()
	local origvoice = OptionsSound_Menu.FeedbackVolume
	OptionsSound_Menu.FeedbackVolume = 0
	OptionsSound_Menu.FeedbackVolumeUpdate("OptionsMenu40_FeedbackVolume_Slider")
	OptionsSound_Menu.FeedbackVolume = origvoice
	UnregisterTimer(ResetVoice)
	RegisterTimer(2, ResetVoice)
end

function ResetVoice()
	OptionsSound_Menu.FeedbackVolumeUpdate("OptionsMenu40_FeedbackVolume_Slider")
end

function SetupDayCycle(_sunRiseAngle, _sunSetAngle, _dayLength)
  Weather.SunRiseAngle = _sunRiseAngle * math.pi / 180
  Weather.SunSetAngle = _sunSetAngle * math.pi / 180
  Weather.DayAngleDif = Weather.SunSetAngle - Weather.SunRiseAngle
  Weather.NightAngleDif = 2*math.pi - math.abs(Weather.DayAngleDif)
  Weather.DayLength = _dayLength * 10
  Weather.NightLength = Weather.NightAngleDif * Weather.DayLength / math.abs(Weather.DayAngleDif)
  Weather.SunStepPerTick = Weather.DayAngleDif / Weather.DayLength
  Message(Weather.DayLength)
  Message(Weather.NightLength)
  Weather.Time = 0
  Weather.SunAngle = Weather.SunRiseAngle
  Weather.SpeedUpTimeStep = (Weather.DayLength + Weather.NightLength) / 400
  Weather.TimeStopAt = 25
  Weather.DayCycleControlJob = StartSimpleHiResJob("Weather_RunTime")
end

function GetTime()
  local hoursSinceSunrise = Weather.Time * 24 / (Weather.DayLength + Weather.NightLength)
  local curTime = hoursSinceSunrise + 6
  if curTime >= 24 then
    curTime = curTime - 24
  end
  return curTime
end

function SetTime(_time)
  local hoursSinceSunrise = _time - 6
  if hoursSinceSunrise < 0 then
    hoursSinceSunrise = 18 + _time
  end
  Weather.Time  = hoursSinceSunrise * (Weather.DayLength + Weather.NightLength) / 24
  Weather.UpdateDay()
end

function StopTime()
  EndJob(Weather.DayCycleControlJob)
end

function ResumeTime()
  if JobIsRunning(Weather.DayCycleControlJob) ~= 1 then
    Weather.DayCycleControlJob = StartSimpleHiResJob("Weather_RunTime")
  end
end

function StopTimeAt(_time)
  Weather.TimeStopAt = _time
end

function RemoveTimeStop()
  Weather.TimeStopAt = 25
end

function Weather_RunTime()
  if Weather.TimeStopAt > GetTime() then
    Weather.Time = Weather.Time + 1
    Weather.SunAngle = Weather.SunRiseAngle + Weather.SunStepPerTick * Weather.Time
  end
  Weather.UpdateDay()
end

function SpeedUpTimeUntil(_until, _callback)
  Weather.SpeedUpUntil = _until
  Weather.SpeedUpLength = nil
  Weather.StartSpeedUp(_callback)
end

function SpeedUpTimeFor(_time, _until, _callback)
  Weather.SpeedUpLength = Logic.GetTime() + _time
  Weather.SpeedUpUntil = _until
  Weather.StartSpeedUp(_callback)
end

function Weather.StartSpeedUp(_callback)
  Weather.SpeedUpCallback = _callback or function() end
  StopTime()
  XGUIEng.ShowWidget("WeatherTimeSpeedUp_Controler", 1)
end

function Weather_TimeSpeedUp()
  Weather.Time = Weather.Time + Weather.SpeedUpTimeStep
  Weather.SunAngle = Weather.SunRiseAngle + Weather.SunStepPerTick * Weather.Time
  Weather.UpdateDay()
  if Weather.SpeedUpLength then
    if Weather.SpeedUpLength > Logic.GetTime() then
      return
    end
  end
  if GetTime() > Weather.SpeedUpUntil - 0.1 and GetTime() < Weather.SpeedUpUntil + 0.1 then
    XGUIEng.ShowWidget("WeatherTimeSpeedUp_Controler", 0)
    Weather.SpeedUpCallback()
    ResumeTime()
  end
end

function Weather.UpdateDay()
  Weather.LightX = math.cos(math.pi + Weather.SunAngle) * 100
  Weather.LightY = math.sin(math.pi + Weather.SunAngle) * 100
  
  local intensity = 0
  if Weather.Time <= Weather.DayLength then
    intensity = 1 + math.sin(Weather.Time * math.pi / Weather.DayLength)
    Weather.LightZ = math.abs((intensity - 1) * 200)
  elseif Weather.Time <= Weather.DayLength + Weather.NightLength then
    intensity = 1 + -math.sin((Weather.Time - Weather.DayLength) * math.pi / Weather.NightLength)
    Weather.LightZ = math.abs((1 - intensity) * 500)
  else
    intensity = 1
    Weather.Time = 0
  end
  
  local light = Weather.GfxSets[Weather.CurrentGfxSet].Light
  local ambientLight = { R = intensity / 12 * light.Ambient.R + 5 / 6 * light.Ambient.R  , G = intensity / 12 * light.Ambient.G + 5 / 6 * light.Ambient.G, B = intensity / 12 * light.Ambient.B + 5 / 6 * light.Ambient.B}
  local diffuseLight = { R = intensity / 2 * light.Diffuse.R, G = intensity / 2 * light.Diffuse.G, B = intensity / 2 * light.Diffuse.B}
  
  Display.GfxSetSetLightParams(Weather.CurrentGfxSet, light.TransitionStart, light.TransitionEnd, Weather.LightX, Weather.LightY, Weather.LightZ, ambientLight.R, ambientLight.G, ambientLight.B, diffuseLight.R, diffuseLight.G, diffuseLight.B)
end