--------------------------------------------------------------------
--					                  Regions									            --
--------------------------------------------------------------------
--[[
  Dependencies: 
    none 
]]--
function SetupRegions()
	regions = {}
	StartSimpleHiResJob("Regions_ControlJob")
	lastX = 0
	lastY = 0
end
function RegisterRegion(_firstPos, _onEnter, _onLeave, _parameter)
	local pos
	local posCounter = 1
	local eID
	newRegion = {}
	newRegion.positions = {}
	newRegion.paremeter = _parameter
	assert(type(_firstPos) == "string", "Regions: firstPos has to be a string!")
	
	pos = GetPosition(_firstPos .. posCounter)
	while pos.X ~= 0 do
		table.insert(newRegion.positions, pos)
		posCounter = posCounter + 1
		pos = GetPosition(_firstPos .. posCounter)
	end
	
	newRegion.onEnter = _onEnter or nil
	newRegion.onLeave = _onLeave or nil
	if not _onEnter and not _onLeave then
		assert(false, "Regions: at least one callback must be given")
	end
	newRegion.isin = false
	table.insert(regions, newRegion)
	return table.getn(regions)
end

function UnregisterRegion(_id)
  table.remove(regions, _id)
end

function Regions_ControlJob()
	local curX, curY = Camera.ScrollGetLookAt()
	local distance =  math.sqrt((curX - lastX)^2 + (curY - lastY)^2)
	if distance > 2000 then
		for i = table.getn(regions), 1, -1 do
			local ePos = { X = curX, Y = curY }
			if Regions_IsPointInPolygon(ePos, regions[i].positions) then
				if not regions[i].isin then --first time entering
					if regions[i].onEnter then
						if regions[i].onEnter(regions[i].paremeter) then
							table.remove(regions, i)
						end
					end
					regions[i].isin = true
				end
			elseif regions[i].isin then
				regions[i].isin = false
				if regions[i].onLeave then
					if regions[i].onLeave(regions[i].paremeter) then
						table.remove(regions, i)
					end
				end
			end
		end
		lastX = curX
		lastY = curY
	end
end
-- Regions is based on a optimized polygon function
-- This isn't my work :D
function Regions_IsPointInPolygon(point, polygon)
	local nvert = table.getn(polygon)
	local c = false
	
	local i = 1
	local j = nvert
	
	while (i - 1) < nvert do
		if ((polygon[i].Y >= point.Y) ~= (polygon[j].Y >= point.Y)) and
		(point.X <= (polygon[j].X - polygon[i].X) * (point.Y - polygon[i].Y) / (polygon[j].Y - polygon[i].Y) + polygon[i].X) then
			c = not c
		end
		
		j = i
		i = i + 1
	end
	return c
end