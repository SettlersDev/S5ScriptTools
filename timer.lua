--------------------------------------------------------------------
--					                Timer         					              --
--------------------------------------------------------------------
--[[
  Dependencies: 
    none
]]--
function SetupTimer()
	timers = {}
	
	StartSimpleJob("TimerJob");
end

function TimerJob()
	for i = table.getn(timers), 1, -1 do
		timers[i].startIn = timers[i].startIn - 1;
		if timers[i].startIn == 0 then
			local stopLoop = timers[i].func(timers[i].param) --funktion ausführen, gibt true/false zurück
			if not stopLoop and timers[i].repeatTimes ~= 0 then
				timers[i].repeatTimes = timers[i].repeatTimes - 1
				timers[i].startIn = timers[i].loopTime --rücksetzen & neustarten
				if timers[i].show then
					MapLocal_StartCountDown(timers[i].loopTime)
				end
			else
				if timers[i].show then
					MapLocal_StopCountDown()
				end
				table.remove(timers, i)
			end
		end
	end
end

function RegisterTimer(startIn, func, options)
	options = options or {}
	local ts = table.getn(timers)
	
	local newTimer = {}
	newTimer.func = func
	newTimer.startIn = startIn
	newTimer.repeatTimes = options.repeatTimes or 0
	newTimer.param = options.param or 0
	newTimer.show = false
	
	if options.show then
		newTimer.show = true
		MapLocal_StartCountDown(startIn)
	end
	
	if newTimer.repeatTimes ~= 0 then
		newTimer.loopTime = startIn
	end
	
	table.insert(timers, newTimer)
end

function UnregisterTimer(delFunc)
	for i = table.getn(timers), 1, -1 do
		if timers[i].func == delFunc then
			if timers[i].show then
				MapLocal_StopCountDown()
			end
			table.remove(timers, i)
			return
		end
	end
end

function GetRemainingTime(func)
	for i = table.getn(timers), 1, -1 do
		if timers[i].func == func then
			return timers[i].startIn
		end
	end
end

function SetRemainingTime(func, tim)
	for i = table.getn(timers), 1, -1 do
		if timers[i].func == func then
			timers[i].startIn = tim
			return
		end
	end
end
