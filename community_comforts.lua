--------------------------------------------------------------------
--------------------------------------------------------------------
--         					Comfortscripte						  --
--------------------------------------------------------------------
--------------------------------------------------------------------
 --------------------------------------------------------------------
--						Color Table by Noigi						
--------------------------------------------------------------------
gvCol = {
  beige = "@color:190,190,150",
  blau = "@color:0,0,255",
  dunkelbraun = "@color:100,80,25",
  dunkelgrau = "@color:120,120,120",
  dunkelgruen = "@color:0,100,0",
  gelb = "@color:255,232,0",
  gruen = "@color:0,255,0",
  hellblau1 = "@color:160,220,255",
  hellblau2 = "@color:140,190,245",
  hellbraun = "@color:130,110,55",
  hellgrau = "@color:170,170,170",
  lila = "@color:200,0,200",
  orange = "@color:255,130,0",
  rot = "@color:255,0,0",
  schwarz = "@color:0,0,0",
  space = "@color:0,0,0,0",
  tuerkis = "@color:0,180,180",
  TUTgruen = "@color:90,190,20",
  TTgelb = "@color:255,200,0",
  TTrot = "@color:200,60,0",
  weiss = "@color:255,255,255",
  ----------------------------------------------
  p1 = "@color:15,64,255",
  p2 = "@color:226,0,0",
  p3 = "@color:235,255,53",
  p4 = "@color:0,235,209",
  p5 = "@color:252,164,39",
  p6 = "@color:178,2,255",
  p7 = "@color:255,79,200",
  p8 = "@color:115,209,65",
  p9 = "@color:0,140,2",
  p10 = "@color:184,184,184",
  p11 = "@color:184,182,90",
  p12 = "@color:136,136,136",
  p13 = "@color:230,230,230",
  p14 = "@color:57,57,57",
  p15 = "@color:139,232,255",
  p16 = "@color:255,150,214",
}
--------------------------------------------------------------------
function round(x)
  if math.mod(x, 2) ~= 0.5 then
    return math.floor(x+0.5)
  end
  return x-0.5
end
--------------------------------------------------------------------
function SucheAufDerWelt(_player, _entity, _groesse, _punkt)
	local punktX1, punktX2, punktY1, punktY2, data
	local gefunden = {}
	local rueck
	if not _groesse then
		_groesse = Logic.WorldGetSize() 
	end
	if not _punkt then
		_punkt = {X = _groesse/2, Y = _groesse/2}
	end
	if _player == 0 then
		data ={Logic.GetEntitiesInArea(_entity, _punkt.X, _punkt.Y, math.floor(_groesse * 0.71), 16)}
		
	else
		data ={Logic.GetPlayerEntitiesInArea(_player,_entity, _punkt.X, _punkt.Y, math.floor(_groesse * 0.71), 16)}
	end
	if data[1] >= 16 then -- Aufteilen angesagt
		local _klgroesse = _groesse / 2 
		-- Ausgangspunkt ist _punkt
		-- _punkt verteilen
		local punktX1 = _punkt.X - _groesse / 4
		local punktX2 = _punkt.X + _groesse / 4
		local punktY1 = _punkt.Y - _groesse / 4
		local punktY2 = _punkt.Y + _groesse / 4
		rueck = SucheAufDerWelt(_player, _entity, _klgroesse, {X=punktX1,Y=punktY1})
		for i = 1, table.getn(rueck) do
			if not IstDrin(rueck[i], gefunden) then
				table.insert(gefunden, rueck[i])
			end
		end
		rueck = SucheAufDerWelt(_player, _entity, _klgroesse, {X=punktX1,Y=punktY2})
		for i = 1, table.getn(rueck) do
			if not IstDrin(rueck[i], gefunden) then
				table.insert(gefunden, rueck[i])
			end
		end
		rueck = SucheAufDerWelt(_player, _entity, _klgroesse, {X=punktX2,Y=punktY1})
		for i = 1, table.getn(rueck) do
			if not IstDrin(rueck[i], gefunden) then
				table.insert(gefunden, rueck[i])
			end
		end
		rueck = SucheAufDerWelt(_player, _entity, _klgroesse, {X=punktX2,Y=punktY2})
		for i = 1, table.getn(rueck) do
			if not IstDrin(rueck[i], gefunden) then
				table.insert(gefunden, rueck[i])
			end
		end
	else
		table.remove(data,1)
		for i = 1, table.getn(data) do
			if not IstDrin(data[i], gefunden) then
				table.insert(gefunden, data[i])
			end
		end
	end
	return gefunden
end
function IstDrin(_wert, _table)
	for i = 1, table.getn(_table) do
		if _table[i] == _wert then 
			return true 
		end 
	end
	return false
end

--------------------------------------------------------------------
--					Tribut Funktion							
--------------------------------------------------------------------
function AddTribute( _tribute )
    assert( type( _tribute ) == "table", "Tribut muß ein Table sein" );
    assert( type( _tribute.text ) == "string", "Tribut.text muß ein String sein" );
    assert( type( _tribute.cost ) == "table", "Tribut.cost muß ein Table sein" );
    assert( type( _tribute.playerId ) == "number", "Tribut.playerId muß eine Nummer sein" );
    assert( not _tribute.Tribute , "Tribut.Tribute darf nicht vorbelegt sein");
    
    uniqueTributeCounter = uniqueTributeCounter or 1;
    _tribute.Tribute = uniqueTributeCounter;
    uniqueTributeCounter = uniqueTributeCounter + 1;
    
    local tResCost = {};
    for k, v in pairs( _tribute.cost ) do
        assert( ResourceType[k] );
        assert( type( v ) == "number" );
        table.insert( tResCost, ResourceType[k] );
        table.insert( tResCost, v );
    end
	Logic.AddTribute( _tribute.playerId, _tribute.Tribute, 0, 0, _tribute.text, unpack( tResCost ) );
    SetupTributePaid( _tribute );
    
    return _tribute.Tribute;
end

--------------------------------------------------------------------
----------------------Umlaut Zusatz Funktion------------------------
--------------------------------------------------------------------
function Umlaute( _text )
  local texttype = type( _text );
  if texttype == "string" then
      _text = string.gsub( _text, "ä", "\195\164" );
      _text = string.gsub( _text, "ö", "\195\182" );
      _text = string.gsub( _text, "ü", "\195\188" );
      _text = string.gsub( _text, "ß", "\195\159" );
      _text = string.gsub( _text, "Ä", "\195\132" );
      _text = string.gsub( _text, "Ö", "\195\150" );
      _text = string.gsub( _text, "Ü", "\195\156" );
      return _text;
  elseif texttype == "table" then
      for k,v in _text do
          _text[k] = Umlaute( v );
      end
      return _text;
  else
      return _text;
  end 
end

--------------------------------------------------------------------
--         					Effects
--------------------------------------------------------------------
function CreateEffect( _player, _type, _position )
    assert(type(_player) == "number" and _player >= 1 and _player <= 8 and type(_type) == "number", "fatal error: wrong input: _player or _type (function CreateEffect())");
    assert((type(_position) == "table" and type(_position.X) == "number" and type(_position.Y) == "number") or type(_position) == "number" or type(_position) == "string", "fatal error: wrong input: _position (function CreateEffect())");
 
    if type(_position) == "table" then
        assert(_position.X >= 0 and _position.Y >= 0 and _position.X < Logic.WorldGetSize() and _position.Y < Logic.WorldGetSize(), "error: wrong position-statement (function CreateEffect())" );
        local effect = Logic.CreateEffect(_type, _position.X, _position.Y, _player);
        return effect;
    elseif type(_position) == "string" then
        local id = GetEntityId(_position);
        assert(IsExisting(id), "error: entity is dead or not existing (function CreateEffect())");
        local position = GetPosition(id);
        local effect = Logic.CreateEffect(_type, position.X, position.Y, _player);
        return effect;
    else
        assert(IsExisting(_position), "error: entity is dead or not existing (function CreateEffect())");
        local position = GetPosition(_position);
        local effect = Logic.CreateEffect(_type, position.X, position.Y, _player);
        return effect;
    end
end
function DestroyEffect( _effect )
    assert(type(_effect) == "number", "fatal error: wrong input: _effect (function DestroyEffect()");
    Logic.DestroyEffect( _effect );
end
--------------------------------------------------------------------
--         			Ist Feind/Freund in der Nähe
--------------------------------------------------------------------
function AreEnemiesInArea( _player, _position, _range)
    return AreEntitiesOfDiplomacyStateInArea( _player, _position, _range, Diplomacy.Hostile )
end
function AreAlliesInArea( _player, _position, _range)
    return AreEntitiesOfDiplomacyStateInArea( _player, _position, _range, Diplomacy.Friendly )
end
function AreEntitiesOfDiplomacyStateInArea( _player, _position, _range, _state )
    for i = 1,8 do
        if Logic.GetDiplomacyState( _player, i) == _state then
            if AreEntitiesInArea( i, 0, _position, _range, 1) then
                return true
            end
        end
    end
    return false
end
--------------------------------------------------------------------
--         					Zufallszahl
--------------------------------------------------------------------

function SetSeed(_seed)
	gvRandomseed = true
	math.randomseed(_seed)
end

function GetRandom(_min,_max,_seed)
	if not _max then
		_max = _min;
		_min = 1;
	end
	assert( (type(_min) == "number" and type(_max) == "number"), "GetRandom: Invalid Input!" )
	_min = round(_min);
	_max = round(_max);
	if not gvRandomseed then
		local seed = "";
		gvRandomseed = true;
		if XNetwork and XNetwork.Manager_DoesExist() == 1 then
			local humanPlayer = XNetwork.GameInformation_GetMapMaximumNumberOfHumanPlayer();
			for i = 1, humanPlayer do
				if XNetwork.GameInformation_IsHumanPlayerAttachedToPlayerID( i ) == 1 then
					seed = seed .. tostring(XNetwork.GameInformation_GetLogicPlayerUserName( i ));
				end
			end
		else
			seed = XGUIEng.GetSystemTime();
		end
		theSeed = seed
		math.randomseed(seed);
	end
	if _min >= _max then
		return _min;
	else
		return math.random(_min, _max);
	end
end