import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"

-- =============================
-- Dice Visual & Game Config  --
-- =============================
local SHAPE_SIZE = 100 -- Default base size for shapes
local diceVisuals = {
	Coin = {size = SHAPE_SIZE, spacing = 1.0},
	d4 = {size = SHAPE_SIZE, spacing = .8},
	d6 = {size = SHAPE_SIZE, spacing = 1.0},
	d8 = {size = SHAPE_SIZE, spacing = 1.1},
	d10 = {size = SHAPE_SIZE, spacing = 1.1},
	d12 = {size = SHAPE_SIZE, spacing = 1.1},
	d20 = {size = SHAPE_SIZE, spacing = 1.1},
	d100 = {size = SHAPE_SIZE, spacing = 1.1},
}

local gfx <const> = playdate.graphics
local ui <const> = playdate.ui
local SCREEN_WIDTH <const> = 400
local SCREEN_HEIGHT <const> = 240

-- Define our dice types
local diceTypes = {
	{name = "Coin", sides = 2, shape = "circle"},
	{name = "d4", sides = 4, shape = "triangle"},
	{name = "d6", sides = 6, shape = "square"},
	{name = "d8", sides = 8, shape = "octagon"},
	{name = "d10", sides = 10, shape = "pentagon"},
	{name = "d12", sides = 12, shape = "dodecagon"},
	{name = "d20", sides = 20, shape = "icosahedron"},
	{name = "d100", sides = 100, shape = "pentacontagon"}
}

-- Variables to store our current state
local currentNumber = 0
local currentDiceIndex = 2  -- Start with d6
local currentDice = diceTypes[currentDiceIndex]
local rollPrompt = nil
local changePrompt = nil

-- Sound effect deviation values
local MIN_DEVIATION = 0.7 -- Minimum playback rate (increased variation)
local MAX_DEVIATION = 1.3 -- Maximum playback rate (increased variation)

-- Sound file paths
local ROLL_SOUND_PATH = "sound/roll_adpcm.wav"
local FLIP_SOUND_PATH = "sound/flip_adpcm.wav"

-- Roll/flip animation durations (ms)
local COIN_FLIP_DELAY = 750
local DICE_ROLL_DELAY = 750

-- Font file paths
local FONT_UI_PATH = "fonts/Roobert-20-Medium"
local FONT_RESULT_PATH = "fonts/Roobert-24-Medium"

-- Prompt text
local ROLL_PROMPT = "A: Roll"
local CHANGE_PROMPT = "Left/Right: Change"

-- Font variables
local fontUI = nil
local fontResult = nil

-- Advantage/disadvantage state
local advantageMode = nil -- nil, "advantage", or "disadvantage"
local advantageNumber = 0

-- Timer for random number generation
local randomNumberTimer = nil

-- Shape drawing functions
local function drawCircle(x, y, radius)
	gfx.drawCircleInRect(x - radius, y - radius, radius * 2, radius * 2)
end

local function drawSquare(x, y, size)
	-- Scale up so the diagonal matches the diameter of polygons
	local scale = math.sqrt(2)
	local halfSize = (size * scale) / 2
	gfx.drawRect(x - halfSize, y - halfSize, size * scale, size * scale)
end

local function drawTriangle(x, y, size)
	-- Scale up so the height matches the diameter of polygons
	local scale = 1.15
	local s = size * scale
	local p1 = playdate.geometry.point.new(x, y - s/2)  -- top
	local p2 = playdate.geometry.point.new(x - s/2, y + s/2)  -- bottom left
	local p3 = playdate.geometry.point.new(x + s/2, y + s/2)   -- bottom right
	
	if p1 and p2 and p3 then
		local points = {p1, p2, p3}
		table.insert(points, playdate.geometry.point.new(p1.x, p1.y))
		local polygon = playdate.geometry.polygon.new(points)
		if polygon then
			gfx.drawPolygon(polygon)
		end
	end
end

local function drawPentagon(x, y, size)
	local points = {}
	for i = 0, 4 do
		local angle = (i * 2 * math.pi / 5) - math.pi/2
		table.insert(points, playdate.geometry.point.new(
			x + size * math.cos(angle),
			y + size * math.sin(angle)
		))
	end
	table.insert(points, points[1])
	local polygon = playdate.geometry.polygon.new(points)
	gfx.drawPolygon(polygon)
end

local function drawOctagon(x, y, size)
	local points = {}
	for i = 0, 7 do
		local angle = (i * 2 * math.pi / 8) - math.pi/8
		table.insert(points, playdate.geometry.point.new(
			x + size * math.cos(angle),
			y + size * math.sin(angle)
		))
	end
	table.insert(points, points[1])
	local polygon = playdate.geometry.polygon.new(points)
	gfx.drawPolygon(polygon)
end

local function drawDodecagon(x, y, size)
	-- Draw a hexagon for a more visually distinct d12
	local points = {}
	for i = 0, 5 do
		local angle = (i * 2 * math.pi / 6)
		table.insert(points, playdate.geometry.point.new(
			x + size * math.cos(angle),
			y + size * math.sin(angle)
		))
	end
	table.insert(points, points[1])
	local polygon = playdate.geometry.polygon.new(points)
	gfx.drawPolygon(polygon)
end

local function drawIcosahedron(x, y, size)
	-- Draw a decagon (10-sided polygon) for the d20
	local points = {}
	for i = 0, 9 do
		local angle = (i * 2 * math.pi / 10)
		table.insert(points, playdate.geometry.point.new(
			x + size * math.cos(angle),
			y + size * math.sin(angle)
		))
	end
	table.insert(points, points[1])
	local polygon = playdate.geometry.polygon.new(points)
	gfx.drawPolygon(polygon)
end

local function drawPentacontagon(x, y, size)
	local points = {}
	for i = 0, 49 do
		local angle = (i * 2 * math.pi / 50)
		table.insert(points, playdate.geometry.point.new(
			x + size * math.cos(angle),
			y + size * math.sin(angle)
		))
	end
	table.insert(points, points[1])
	local polygon = playdate.geometry.polygon.new(points)
	gfx.drawPolygon(polygon)
end

-- Map shape names to draw functions
local shapeDrawFunctions = {
	circle = drawCircle,
	square = drawSquare,
	triangle = drawTriangle,
	pentagon = drawPentagon,
	octagon = drawOctagon,
	dodecagon = drawDodecagon,
	icosahedron = drawIcosahedron,
	pentacontagon = drawPentacontagon
}

local function loadGame()
	playdate.display.setRefreshRate(50) -- Sets framerate to 50 fps
	math.randomseed(playdate.getSecondsSinceEpoch()) -- seed for math.random

	-- Load sounds
	rollSound = playdate.sound.sampleplayer.new(ROLL_SOUND_PATH)
	flipSound = playdate.sound.sampleplayer.new(FLIP_SOUND_PATH)
	if not rollSound or not flipSound then
		print("Error: Failed to load sound files.")
	end

	-- Load fonts
	fontUI = playdate.graphics.font.new(FONT_UI_PATH)
	fontResult = playdate.graphics.font.new(FONT_RESULT_PATH)
	if not fontUI or not fontResult then
		print("Error: Failed to load font files.")
	end

	-- Set up initial game state
	currentShape = "Coin"
	shapeCount = 1
	results = {}
	lastRollTime = 0
	lastChangeTime = 0
	changeCooldown = 200 -- ms between changes
	rollCooldown = 500 -- ms between rolls

	-- Initialize currentNumber to 0
	currentNumber = 0

	-- Start the timer for random number generation
	randomNumberTimer = playdate.timer.new(100, function()
		if currentDice and currentDice.sides then
			currentNumber = math.random(1, currentDice.sides)
		end
	end)
	randomNumberTimer.repeats = true
end

local function updateGame()
	-- Toggle advantage/disadvantage
	if currentDice and currentDice.name ~= "Coin" then
		if playdate.buttonJustPressed(playdate.kButtonUp) then
			if advantageMode == "advantage" then
				advantageMode = nil
				advantageNumber = 0
			else
				advantageMode = "advantage"
				advantageNumber = 0
			end
		elseif playdate.buttonJustPressed(playdate.kButtonDown) then
			if advantageMode == "disadvantage" then
				advantageMode = nil
				advantageNumber = 0
			else
				advantageMode = "disadvantage"
				advantageNumber = 0
			end
		end
	else
		advantageMode = nil
		advantageNumber = 0
	end

	-- Check if A button was just pressed
	if playdate.buttonJustPressed(playdate.kButtonA) then
		if currentDice and currentDice.sides then
			local uptime = playdate.getCurrentTimeMilliseconds()
			currentNumber = (math.random(1, currentDice.sides) + math.floor(uptime / 1000)) % currentDice.sides + 1
			if advantageMode then
				advantageNumber = (math.random(1, currentDice.sides) + math.floor(uptime / 500)) % currentDice.sides + 1
			else
				advantageNumber = 0
			end
			-- Play sound
			local randomRate = MIN_DEVIATION + (math.random() * (MAX_DEVIATION - MIN_DEVIATION))
			if currentDice.name == "Coin" then
				if flipSound then
					flipSound:setRate(randomRate)
					flipSound:play()
				end
			else
				if rollSound then
					rollSound:setRate(randomRate)
					rollSound:play()
				end
			end
			local delayTime = currentDice.name == "Coin" and COIN_FLIP_DELAY or DICE_ROLL_DELAY
			delayTime = delayTime * randomRate
			playdate.timer.new(delayTime, function()
				currentNumber = currentNumber
			end)
		end
	end

	-- Handle D-pad navigation (left/right)
	if playdate.buttonJustPressed(playdate.kButtonRight) then
		currentDiceIndex = currentDiceIndex + 1
		if currentDiceIndex > #diceTypes then
			currentDiceIndex = 1
		end
		currentDice = diceTypes[currentDiceIndex]
		currentNumber = 0
		advantageNumber = 0
		advantageMode = nil
		if randomNumberTimer then
			randomNumberTimer:remove()
			randomNumberTimer = nil
		end
	end

	if playdate.buttonJustPressed(playdate.kButtonLeft) then
		currentDiceIndex = currentDiceIndex - 1
		if currentDiceIndex < 1 then
			currentDiceIndex = #diceTypes
		end
		currentDice = diceTypes[currentDiceIndex]
		currentNumber = 0
		advantageNumber = 0
		advantageMode = nil
		if randomNumberTimer then
			randomNumberTimer:remove()
			randomNumberTimer = nil
		end
	end
end

local function drawGame()
	gfx.clear()
	
	if not fontUI then return end
	gfx.setFont(fontUI)
	
	local diceText = currentDice and currentDice.name or "Unknown"
	local diceTextWidth = fontUI:getTextWidth(diceText)
	local diceTextHeight = fontUI:getHeight()
	local diceX = (SCREEN_WIDTH - diceTextWidth) / 2
	local diceY = 24
	gfx.drawText(diceText, diceX, diceY)

	-- Exclamation mark for advantage/disadvantage
	if advantageMode then
		gfx.drawText("!", SCREEN_WIDTH - fontUI:getTextWidth("!") - 8, 8)
	end

	-- Result text
	local resultText, advText = "", ""
	local shapeCenterY = SCREEN_HEIGHT / 2 - 10
	local shapeCenterX = SCREEN_WIDTH / 2

	-- Get per-dice visuals
	local visuals = diceVisuals[currentDice and currentDice.name or "d6"] or {size = SHAPE_SIZE, spacing = 1.0}
	local shapeSize = visuals.size
	local spacing = shapeSize * visuals.spacing

	if currentDice and currentDice.name == "Coin" then
		-- Handle coin display
		if currentNumber == 0 then
			resultText = ""
		elseif currentNumber == 1 then
			resultText = "HEADS"
		else
			resultText = "TAILS"
		end
		-- Use fontUI for coin result
		gfx.setFont(fontUI)
		local resultTextWidth = fontUI:getTextWidth(resultText)
		local resultTextHeight = fontUI:getHeight()
		if currentDice and currentDice.shape then
			local drawShape = shapeDrawFunctions[currentDice.shape]
			if drawShape then
				drawShape(shapeCenterX, shapeCenterY, shapeSize/2)
			end
		end
		gfx.drawText(resultText, shapeCenterX - resultTextWidth/2, shapeCenterY - resultTextHeight/2)
	else
		resultText = currentNumber > 0 and tostring(currentNumber) or ""
		advText = advantageNumber > 0 and tostring(advantageNumber) or ""
		
		if not fontResult then return end
		gfx.setFont(fontResult)
		
		local resultTextWidth = fontResult:getTextWidth(resultText)
		local resultTextHeight = fontResult:getHeight()
		
		if advantageMode and advText ~= "" then
			-- Draw two dice side by side
			local leftX = shapeCenterX - spacing/2
			local rightX = shapeCenterX + spacing/2
			if currentDice and currentDice.shape then
				local drawShape = shapeDrawFunctions[currentDice.shape]
				if drawShape then
					drawShape(leftX, shapeCenterY, shapeSize/2)
					drawShape(rightX, shapeCenterY, shapeSize/2)
				end
			end
			local leftText, rightText = resultText, advText
			if advantageMode == "advantage" and tonumber(advText) > tonumber(resultText) then
				leftText, rightText = advText, resultText
			elseif advantageMode == "disadvantage" and tonumber(advText) < tonumber(resultText) then
				leftText, rightText = advText, resultText
			end
			local yOffset = 0
			if currentDice and currentDice.shape == "triangle" then yOffset = shapeSize * 0.15 end
			gfx.drawText(leftText, leftX - fontResult:getTextWidth(leftText)/2, shapeCenterY - resultTextHeight/2 + yOffset)
			gfx.drawText(rightText, rightX - fontResult:getTextWidth(rightText)/2, shapeCenterY - resultTextHeight/2 + yOffset)
		else
			if currentDice and currentDice.shape then
				local drawShape = shapeDrawFunctions[currentDice.shape]
				if drawShape then
					drawShape(shapeCenterX, shapeCenterY, shapeSize/2)
				end
			end
			local yOffset = 0
			if currentDice and currentDice.shape == "triangle" then yOffset = shapeSize * 0.15 end
			gfx.drawText(resultText, shapeCenterX - resultTextWidth/2, shapeCenterY - resultTextHeight/2 + yOffset)
		end
	end

	if not fontUI then return end
	gfx.setFont(fontUI)
	local rollTextWidth = fontUI:getTextWidth(ROLL_PROMPT)
	local changeTextWidth = fontUI:getTextWidth(CHANGE_PROMPT)
	gfx.drawText(ROLL_PROMPT, (SCREEN_WIDTH - rollTextWidth) / 2, SCREEN_HEIGHT - 60)
	gfx.drawText(CHANGE_PROMPT, (SCREEN_WIDTH - changeTextWidth) / 2, SCREEN_HEIGHT - 35)
end

-- Initialize the game
loadGame()

-- Main update function
function playdate.update()
	updateGame()
	drawGame()
end