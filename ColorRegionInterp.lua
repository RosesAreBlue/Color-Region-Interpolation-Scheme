--XZ, xi and zi represent pixel coordinates, x and z represent world coordinates.
local pixelSize, xiMax, ziMax = 4, 128, 128
local startingPoint = game.Workspace.Origin.Position
local grid = {} --grid[xi][zi].ColorDistanceData = {{biomeN, dist1}, ...} ; grid[xi][zi].Properties = {IsSource = ... , InfluenceTable = {} }

function pixelPosToWorldPos(xi, zi)
	return startingPoint + pixelSize*Vector3.new(xi - 0.5, 0, zi - 0.5)
end

function worldPosToNearestPixelPos(vector) --i.e. The pixel which contains vector
	local vector = vector - startingPoint
	local x, z = vector.X, vector.Z
	
	return math.floor(x/pixelSize + 1), math.floor(z/pixelSize + 1) --xi, zi (should both be an integer of 1 or greater)
end

local biomeBorders = {} --{ {biome1 border coords}, {biome2 border coords}, etc. }

function AppendColorDistance(xi, zi, color, dist, biomeN)
	if (xi < 1 or xi > xiMax) or (zi < 1 or zi > ziMax) then
		error('xi, zi are out of grid bounds')
	end
	
	if grid[xi] == nil then
		grid[xi] = {}
	end
	if grid[xi][zi] == nil then
		grid[xi][zi] = { ColorDistanceData = {}, Properties = {IsSource = false, InfluenceTable = {}} }
	elseif dist ~= 0 and grid[xi][zi].Properties.IsSource == true then --non-sources cannot overwrite a source
		error('Attempt to overwrite biome border pixel')
	end
	if dist == 0 and grid[xi][zi].Properties.IsSource == false then
		table.insert(biomeBorders[biomeN], {xi, zi})
		grid[xi][zi].Properties.IsSource = true
		--grid[xi][zi].Properties.Color = color
	end
	table.insert(grid[xi][zi].ColorDistanceData, {biomeN, dist}) --May contain duplicates of same color if dist == 0 due to line drawing algor (shouldn't matter)
	--Ensure non-sources DO NOT contain duplicates of same color!!!
end

function CreatePixelLine(p1, p2, color, biomeN) --Better alternative is bresenham algorithm
	local interpVec, dist = (p2 - p1).Unit, (p2 - p1).Magnitude; if dist == 0 then error('Cannot define line when p1==p2') end
	local interpMaxDist = pixelSize/2 --should be safe (interpMaxDist < pixelSize)
	local interpDistDivisor = math.ceil(dist/interpMaxDist) --closest integer which divides dist into a value less than (or equal to) interpMaxDist
	local interpDist = dist/interpDistDivisor

	for i = 0, interpDistDivisor do
		local nextPos = p1 + i*interpVec*interpDist
		local xi, zi = worldPosToNearestPixelPos(nextPos)
		
		AppendColorDistance(xi, zi, color, 0, biomeN)
	end
end

function ExpandBiomeAlongGrid(biomeN) --Append color distance data across entire grid for said biome
	if biomeBorders[biomeN] == nil then error('Attempt to expand non-existing biome') end
	
	local previousLayer = biomeBorders[biomeN] -- = { {xi1, zi1}, {xi2, zi2}, etc.}
	--local biomeColor = grid[previousLayer[1][1]][previousLayer[1][2]].Properties.Color
	-- Conditions for NOT adding pixel to next layer:
	--  1. Pixel is ALREADY in next layer or pixel is in previous layer
	--  2. Pixel is a source
	--  3. Pixel is beyond bounds (1 <= xi,zi <= xiMax, ziMax)
	
	local preventDuplicatePixels = {} --after adding pixel to nextLayer, define preventDuplicatePixels[xi][zi] = true to indicate that this pixel has already been defined
	local currentIter = 0
	
	while #previousLayer ~= 0 do --*
		currentIter = currentIter + 1 --represents pseudo-distance
		local nextLayer = {} --goal is to iteratively acquire next layer from previous
		
		for _, pixelV in pairs(previousLayer) do
			
			for horOrVert = 1, 2 do
				for minusOrPositive = -1, 1, 2 do
					local testPixel = {pixelV[1], pixelV[2]}
					testPixel[horOrVert] = testPixel[horOrVert] + minusOrPositive
					
					local safeToAdd = true
					local xi, zi = testPixel[1], testPixel[2]
					
					--Criterion check--
					
					if preventDuplicatePixels[xi] ~= nil then --Condition 1
						if preventDuplicatePixels[xi][zi] ~= nil then
							safeToAdd = false
						end
					end
					
					if grid[xi] then --Condition 2
						if grid[xi][zi] then
							if grid[xi][zi].Properties.IsSource == true then
								safeToAdd = false
							end
						end
					end
					
					if (xi < 1 or xi > xiMax) or (zi < 1 or zi > ziMax) then --Condition 3
						safeToAdd = false
					end
					
					-------------------
					
					if safeToAdd == true then --Good to go!
						if preventDuplicatePixels[xi] == nil then preventDuplicatePixels[xi] = {} end
						preventDuplicatePixels[xi][zi] = true
						
						table.insert(nextLayer, {xi, zi})
						
						AppendColorDistance(xi, zi, Color3.new(), currentIter, biomeN)
					end
					
				end
			end
			
		end
		
		previousLayer = nextLayer
	end
	
end

function GenerateBlendedData(theBiomes)

for BiomeI, Biome in pairs(theBiomes) do --Map biome border pixels onto grid

	
	biomeBorders[BiomeI] = {} --represents biomeI border pixel coords
	
	for i, p in pairs(Biome:GetChildren()) do --find border pixel coords
		local p1, p2 = p.CFrame:pointToWorldSpace(Vector3.new(0, 0, -1)*p.Size/2, Vector3.new(0, 0, 1)*p.Size/2)
		CreatePixelLine(p1, p2, p.Color, BiomeI)
	end
	

end

for BiomeI, Biome in pairs(theBiomes) do --Acquire pseudo-distance from border for every pixel
	
	ExpandBiomeAlongGrid(BiomeI) --Do this for every biome
end

for xi = 1, xiMax do --Blend colors using Inverse Distance Weighting
	for zi = 1, ziMax do
		local influenceTable = {}
		for iter = 1, #theBiomes do
			influenceTable[iter] = 0
		end
		if grid[xi][zi].Properties.IsSource == false then
			local sum = 0
			for _, v in ipairs(grid[xi][zi].ColorDistanceData) do
				sum = sum + 1/v[2]
			end
			
			for _, v in ipairs(grid[xi][zi].ColorDistanceData) do
				--r, g, b = r + v[1].r/v[2], g + v[1].g/v[2], b + v[1].b/v[2]
				influenceTable[v[1]] = 1/(v[2]*sum)
			end
			
			--r, g, b = r/sum, g/sum, b/sum
			grid[xi][zi].Properties.InfluenceTable = influenceTable
		else
			influenceTable[grid[xi][zi].ColorDistanceData[1][1]] = 1
			grid[xi][zi].Properties.InfluenceTable = influenceTable
		end
	end
end

end

GenerateBlendedData({game.Workspace.Biomes.Biome1, game.Workspace.Biomes.Biome2, game.Workspace.Biomes.Biome3, game.Workspace.Biomes.Biome4})
--grid[xi][zi].Properties.InfluenceData will be a table containing the influence of every biome given in the order above

local colors = {game.Workspace.Biomes.Biome1.Part.Color, game.Workspace.Biomes.Biome2.Part.Color, game.Workspace.Biomes.Biome3.Part.Color, game.Workspace.Biomes.Biome4.Part.Color}

function AddColorsWithScalars(colors, scalars)
	local r, g, b = 0, 0, 0
	for i, v in pairs(colors) do
		r, g, b = r + v.r*scalars[i], g + v.g*scalars[i], b + v.b*scalars[i]
	end
	return Color3.new(r, g, b)
end

for xi = 1, xiMax do --Display pixels
	for zi = 1, ziMax do
		local pixelColor = AddColorsWithScalars(colors, grid[xi][zi].Properties.InfluenceTable)
		local actualPixelPos = pixelPosToWorldPos(xi, zi)
		local part = Instance.new("Part", game.Workspace)
		part.Anchored, part.Color = true, pixelColor
		part.TopSurface, part.BottomSurface = 0, 0
		part.Material = Enum.Material.Neon
		part.Size = Vector3.new(1, 1, 1)*pixelSize
		part.CFrame = CFrame.new(actualPixelPos + Vector3.new(0, 2, 0))
	end
end