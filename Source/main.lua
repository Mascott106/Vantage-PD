import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"

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

-- Sound effects using playdate.sound.sampleplayer
local rollSound = nil
local flipSound = nil

-- Shape drawing functions
local function drawCircle(x, y, radius)
	gfx.drawCircleInRect(x - radius, y - radius, radius * 2, radius * 2)
end

local function drawSquare(x, y, size)
	local halfSize = size / 2
	gfx.drawRect(x - halfSize, y - halfSize, size, size)
end

local function drawTriangle(x, y, size)
	local points = {
		playdate.geometry.point.new(x, y - size/2),  -- top
		playdate.geometry.point.new(x - size/2, y + size/2),  -- bottom left
		playdate.geometry.point.new(x + size/2, y + size/2),   -- bottom right
		playdate.geometry.point.new(x, y - size/2)  -- close the triangle
	}
	local polygon = playdate.geometry.polygon.new(points)
	gfx.drawPolygon(polygon)
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
	-- Close the pentagon
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
	-- Close the octagon
	table.insert(points, points[1])
	local polygon = playdate.geometry.polygon.new(points)
	gfx.drawPolygon(polygon)
end

local function drawDodecagon(x, y, size)
	local points = {}
	for i = 0, 11 do
		local angle = (i * 2 * math.pi / 12) - math.pi/12
		table.insert(points, playdate.geometry.point.new(
			x + size * math.cos(angle),
			y + size * math.sin(angle)
		))
	end
	-- Close the dodecagon
	table.insert(points, points[1])
	local polygon = playdate.geometry.polygon.new(points)
	gfx.drawPolygon(polygon)
end

local function drawIcosahedron(x, y, size)
	-- Simplified representation as a hexagon
	local points = {}
	for i = 0, 5 do
		local angle = (i * 2 * math.pi / 6)
		table.insert(points, playdate.geometry.point.new(
			x + size * math.cos(angle),
			y + size * math.sin(angle)
		))
	end
	-- Close the hexagon
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
	-- Close the pentacontagon
	table.insert(points, points[1])
	local polygon = playdate.geometry.polygon.new(points)
	gfx.drawPolygon(polygon)
end

local function loadGame()
	playdate.display.setRefreshRate(50) -- Sets framerate to 50 fps
	math.randomseed(playdate.getSecondsSinceEpoch()) -- seed for math.random

	-- Load sound effects using playdate.sound.sampleplayer
	rollSound = playdate.sound.sampleplayer.new("sound/roll_adpcm.wav")
	flipSound = playdate.sound.sampleplayer.new("sound/flip_adpcm.wav")

	-- Load the Roobert 24 Medium font
	local font = playdate.graphics.font.new("fonts/Roobert-24-Medium")
	gfx.setFont(font) -- Set the font as active
end

local function updateGame()
	-- Check if A button was just pressed
	if playdate.buttonJustPressed(playdate.kButtonA) then
		-- Generate random number based on current dice type
		if currentDice and currentDice.sides then
			-- Get the current uptime
			local uptime = playdate.getCurrentTimeMilliseconds()
			-- Add uptime to the random number generation and ensure it stays within bounds
			currentNumber = (math.random(1, currentDice.sides) + math.floor(uptime / 1000)) % currentDice.sides + 1

			-- Play appropriate sound effect with random pitch and speed
			if currentDice.name == "Coin" then
				if flipSound then
					-- Randomly adjust the playback rate by ±10%
					local randomRate = 1.0 + (math.random() * 0.2 - 0.1) -- Random value between 0.9 and 1.1
					flipSound:setRate(randomRate)
					flipSound:play()
				end
			else
				if rollSound then
					-- Randomly adjust the playback rate by ±10%
					local randomRate = 1.0 + (math.random() * 0.2 - 0.1) -- Random value between 0.9 and 1.1
					rollSound:setRate(randomRate)
					rollSound:play()
				end
			end
		end
	end

	-- Handle D-pad navigation
	if playdate.buttonJustPressed(playdate.kButtonRight) then
		currentDiceIndex = currentDiceIndex + 1
		if currentDiceIndex > #diceTypes then
			currentDiceIndex = 1
		end
		currentDice = diceTypes[currentDiceIndex]
		currentNumber = 0  -- Reset the number when changing dice
	end

	if playdate.buttonJustPressed(playdate.kButtonLeft) then
		currentDiceIndex = currentDiceIndex - 1
		if currentDiceIndex < 1 then
			currentDiceIndex = #diceTypes
		end
		currentDice = diceTypes[currentDiceIndex]
		currentNumber = 0  -- Reset the number when changing dice
	end
end

local function drawGame()
	gfx.clear() -- Clears the screen
	
	-- Draw the current dice type
	local font = gfx.getSystemFont()
	if not font then return end
	
	local diceText = currentDice and currentDice.name or "Unknown"
	local diceTextWidth = font:getTextWidth(diceText)
	local diceTextHeight = font:getHeight()
	
	-- Center the dice type text near the top
	local diceX = (SCREEN_WIDTH - diceTextWidth) / 2
	local diceY = 80
	gfx.drawText(diceText, diceX, diceY)
	
	-- Draw the current number or coin result
	local resultText
	if currentDice and currentDice.name == "Coin" then
		if currentNumber == 0 then
			resultText = ""
		elseif currentNumber == 1 then
			resultText = "HEADS"
		else
			resultText = "TAILS"
		end
	else
		resultText = tostring(currentNumber or 0)
	end
	
	local resultTextWidth = font:getTextWidth(resultText)
	local resultTextHeight = font:getHeight()
	
	-- Center the result below the dice type
	local resultX = (SCREEN_WIDTH - resultTextWidth) / 2
	local resultY = 120
	
	-- Draw the shape first
	local shapeSize = 60  -- Base size for shapes
	if currentDice and currentDice.shape then
		if currentDice.shape == "circle" then
			drawCircle(resultX + resultTextWidth/2, resultY + resultTextHeight/2, shapeSize/2)
		elseif currentDice.shape == "square" then
			drawSquare(resultX + resultTextWidth/2, resultY + resultTextHeight/2, shapeSize)
		elseif currentDice.shape == "triangle" then
			drawTriangle(resultX + resultTextWidth/2, resultY + resultTextHeight/2, shapeSize)
		elseif currentDice.shape == "pentagon" then
			drawPentagon(resultX + resultTextWidth/2, resultY + resultTextHeight/2, shapeSize/2)
		elseif currentDice.shape == "octagon" then
			drawOctagon(resultX + resultTextWidth/2, resultY + resultTextHeight/2, shapeSize/2)
		elseif currentDice.shape == "dodecagon" then
			drawDodecagon(resultX + resultTextWidth/2, resultY + resultTextHeight/2, shapeSize/2)
		elseif currentDice.shape == "icosahedron" then
			drawIcosahedron(resultX + resultTextWidth/2, resultY + resultTextHeight/2, shapeSize/2)
		elseif currentDice.shape == "pentacontagon" then
			drawPentacontagon(resultX + resultTextWidth/2, resultY + resultTextHeight/2, shapeSize/2)
		end
	end
	
	-- Draw the text on top of the shape
	gfx.drawText(resultText, resultX, resultY)
	
	-- Draw button prompts as text
	local rollText = "A: Roll"
	local changeText = "Left/Right: Change"
	local rollTextWidth = font:getTextWidth(rollText)
	local changeTextWidth = font:getTextWidth(changeText)
	
	-- Position prompts higher up from the bottom
	gfx.drawText(rollText, (SCREEN_WIDTH - rollTextWidth) / 2, SCREEN_HEIGHT - 40)
	gfx.drawText(changeText, (SCREEN_WIDTH - changeTextWidth) / 2, SCREEN_HEIGHT - 20)
end

-- Initialize the game
loadGame()

-- Main update function
function playdate.update()
	updateGame()
	drawGame()
	playdate.drawFPS(0,0) -- FPS widget
end