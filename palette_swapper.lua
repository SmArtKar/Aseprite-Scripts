if app.apiVersion < 1 then
	return app.alert("This script requires Aseprite v1.2.10-beta3")
end

--
-- Replaces a palette with another one from the selection, assumning that they're aligned next to each other (with or without a break between them)
--

HORIZONTAL = "horizontal"
VERTICAL = "vertical"

local cel = app.activeCel
if not cel then
  return app.alert("There is no active image")
end

local pc = app.pixelColor
local image = app.activeImage

local bounds = cel.sprite.selection.bounds
local layers = app.range.layers
-- Prefer the longer direction
local paletteDirection = ((bounds.width > bounds.height) and HORIZONTAL or VERTICAL)
local foundVerticalColorIndex = -1
local foundColorY = -1
local verticalCutIndex = -1
local secondPaletteVerticalCoord = -1
local secondPaletteY = -1
for xCoord = bounds.x, bounds.x + bounds.width - 1 do
	local validCut = true
	for yCoord = bounds.y - 3, bounds.y + bounds.height - 4 do
		local pixel = image:getPixel(xCoord, yCoord)
		if pc.rgbaA(pixel) > 0 then
			if verticalCutIndex > -1 then
				-- Look for the furthest one out in case palette is made with a circular brush
				if secondPaletteVerticalCoord == -1 or yCoord < secondPaletteY then
					secondPaletteVerticalCoord = xCoord
					secondPaletteY = yCoord
				end
				break
			end

			validCut = false
			-- Look for the furthest one out in case palette is made with a circular brush
			if foundVerticalColorIndex == -1 or yCoord < foundColorY then
				foundVerticalColorIndex = xCoord
				foundColorY = yCoord
			end
			break
		end
	end

	if foundVerticalColorIndex > -1 and validCut and verticalCutIndex == -1 then
		verticalCutIndex = xCoord
	end
end

local foundHorizontalColorIndex = -1
local foundColorX = -1
local horizontalCutIndex = -1
local secondPaletteHorizontalCoord = -1
local secondPaletteX = -1
for yCoord = bounds.y - 3, bounds.y + bounds.height - 4 do
	local validCut = true
	for xCoord = bounds.x, bounds.x + bounds.width - 1 do
		local pixel = image:getPixel(xCoord, yCoord)
		if pc.rgbaA(pixel) > 0 then
			if horizontalCutIndex > -1 then
				-- Look for the furthest one out in case palette is made with a circular brush
				if secondPaletteHorizontalCoord == -1 or xCoord < secondPaletteX then
					secondPaletteHorizontalCoord = yCoord
					secondPaletteX = xCoord
				end
				break
			end
			validCut = false
			-- Look for the furthest one out in case palette is made with a circular brush
			if foundHorizontalColorIndex == -1 or xCoord < foundColorX then
				foundHorizontalColorIndex = yCoord
				foundColorX = xCoord
			end
			break
		end
	end

	if foundHorizontalColorIndex > -1 and validCut and horizontalCutIndex == -1 then
		horizontalCutIndex = yCoord
	end
end

cel.sprite.selection:deselect()

-- Unless the other direction has a clean cut between the rows and the longer direction doesn't
if paletteDirection == HORIZONTAL and horizontalCutIndex > -1 and verticalCutIndex == -1 then
	paletteDirection = VERTICAL
end

if paletteDirection == VERTICAL and verticalCutIndex > -1 and horizontalCutIndex == -1 then
	paletteDirection = HORIZONTAL
end

if paletteDirection == VERTICAL then
	for yCoord = bounds.y - 3, bounds.y + bounds.height - 4 do
		local firstPixel = image:getPixel(foundVerticalColorIndex, yCoord)
		local secondPixel = image:getPixel(secondPaletteVerticalCoord, yCoord)
		app.command.ReplaceColor {ui = false, from = Color {r = pc.rgbaR(firstPixel), g = pc.rgbaG(firstPixel), b = pc.rgbaB(firstPixel), a = pc.rgbaA(firstPixel)}, to = Color {r = pc.rgbaR(secondPixel), g = pc.rgbaG(secondPixel), b = pc.rgbaB(secondPixel), a = pc.rgbaA(secondPixel)}}
	end
end

if paletteDirection == HORIZONTAL then
	for xCoord = bounds.x, bounds.x + bounds.width - 1 do
		local firstPixel = image:getPixel(xCoord, foundHorizontalColorIndex)
		local secondPixel = image:getPixel(xCoord, secondPaletteHorizontalCoord)
		app.command.ReplaceColor {ui = false, from = Color {r = pc.rgbaR(firstPixel), g = pc.rgbaG(firstPixel), b = pc.rgbaB(firstPixel), a = pc.rgbaA(firstPixel)}, to = Color {r = pc.rgbaR(secondPixel), g = pc.rgbaG(secondPixel), b = pc.rgbaB(secondPixel), a = pc.rgbaA(secondPixel)}}
	end
end

