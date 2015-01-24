--------------------------------------------------------------------
--					             On Screen Info									          --
--------------------------------------------------------------------
--[[
  Dependencies: 
    s5hook.lua   
]]--
function SetupOnScreenInfo(_defaultPath, _imageTable)
  if not OnScreenInfo then
    OnScreenInfo = {
      Images = {},
      DefaultPath = _defaultPath,
      Entities = {},
    }
    
   
    
    OnScreenInfo.ReloadImages = function()
      for fileName, imageInfo in pairs(OnScreenInfo.Images) do
        imageInfo.Image = S5Hook.OSILoadImage(imageInfo.Path)
      end
    end

    OnScreenInfo.Redraw = function(eID, active, x, y)
      local entityOSI = OnScreenInfo.Entities[eID];
      if entityOSI then
        for index, drawingInfo in pairs(entityOSI.Images) do
          local imageData = drawingInfo.Image
          local activeMode = drawingInfo.ActiveMode;
          if(activeMode == nil or active == activeMode) then
              S5Hook.OSIDrawImage(imageData.Image, x + drawingInfo.XOffset, y + drawingInfo.YOffset, imageData.ImageWidth, imageData.ImageHeight)
          end
        end
        for index, drawingInfo in pairs(entityOSI.Texts) do
          local activeMode = drawingInfo.ActiveMode;
          if(activeMode == nil or active == activeMode) then
            local callback = drawingInfo.Callback
            local kill = false
            if callback then
              kill = callback(drawingInfo)
            end
            if kill then
              entityOSI.Texts[index] = nil
            else
              local fontColor = drawingInfo.FontColor
              S5Hook.OSIDrawText(drawingInfo.Text, drawingInfo.Font, x + drawingInfo.XOffset, y + drawingInfo.YOffset, fontColor.R, fontColor.G, fontColor.B, fontColor.A)
            end
          end
        end
      end 
    end
    S5Hook.OSISetDrawTrigger(OnScreenInfo.Redraw)
    
    OnScreenInfo.LoadImage = function(_fileName, _useInternPath)
      local path = OnScreenInfo.DefaultPath .. _fileName .. ".png"
      if _useInternPath then
        path = "graphics/textures/gui/" .. _fileName .. ".png"
      end
      local newImg = S5Hook.OSILoadImage(path)
      if OnScreenInfo.Images[_fileName] then
        return
      else
        OnScreenInfo.Images[_fileName] = {}
      end
      OnScreenInfo.Images[_fileName].Image = newImg
      local newImgW, newImgH = S5Hook.OSIGetImageSize(newImg)
      OnScreenInfo.Images[_fileName].ImageWidth = newImgW
      OnScreenInfo.Images[_fileName].ImageHeight = newImgH
      OnScreenInfo.Images[_fileName].Path = path
    end
    
    for i = 1, table.getn(_imageTable) do
      OnScreenInfo.LoadImage(_imageTable[i].Path, _imageTable[i].UseInternPath)
    end
    
    OnScreenInfo.AddImageToEntity = function(_entity, _fileName, _activeMode, _xOffset, _yOffset)
        local eID = GetEntityId(_entity)
        if not OnScreenInfo.Entities[eID] then
          OnScreenInfo.Entities[eID] = { Images = {}, Texts = {} }
        end
        local image = OnScreenInfo.Images[_fileName]
        if not image then
          return
        end
        table.insert(OnScreenInfo.Entities[eID].Images, { 
          Image = image,
          XOffset = _xOffset or -(image.ImageWidth / 2), 
          YOffset = _yOffset or -(30 + image.ImageHeight / 2) ,
          ActiveMode = _activeMode,
        })
        return table.getn(OnScreenInfo.Entities[eID].Images)
    end

    OnScreenInfo.AddTextToEntity = function(_entity, _text, _font, _activeMode, _xOffset, _yOffset, _fontColor, _callback)
        local eID = GetEntityId(_entity)
        if not OnScreenInfo.Entities[eID] then
          OnScreenInfo.Entities[eID] = { Images = {}, Texts = {} }
        end
        if not _fontColor then
          _fontColor = {    
            R = 255,
            G = 255,
            B = 255,
            A = 255,
          };
        end
        table.insert(OnScreenInfo.Entities[eID].Texts, {
          Text = _text or "Yolo!",
          XOffset = _xOffset or 25, 
          YOffset = _yOffset or 0,
          Font = _font or 10,
          FontColor = _fontColor,
          ActiveMode = _activeMode,
          Callback = _callback
        })
        return table.getn(OnScreenInfo.Entities[eID].Texts)
    end
  else
    OnScreenInfo.ReloadImages()
    S5Hook.OSISetDrawTrigger(OnScreenInfo.Redraw)
  end
end