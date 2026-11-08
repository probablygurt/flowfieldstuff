--!strict
local DEF_TOP_LEFT_ANCHOR = Vector3.yAxis * 0.5
local DEF_CELL_PART_SIZE = Vector3.new(4, 1, 4)
local DEFAULT_WEIGHT = 1
local Grid = {}
Grid.__index = Grid

type GridData = {
	width: number,
	height: number,
	weight: buffer,
	cost: buffer,
	_parts: {BasePart},
	_partsFolder: Folder
}

export type Grid = typeof(setmetatable({} :: GridData, Grid))

local function getDataDisplay(part: BasePart): TextLabel?
	local displaySurface = part:FindFirstChild("DisplaySurface") :: SurfaceGui?
	if displaySurface == nil then return end
	
	local displayData = displaySurface:FindFirstChild("DataDisplay") :: TextLabel?
	return displayData
end

function Grid.new(width: number, height: number): Grid
	local n = width * height
	
	local self = {}
	self.width = width
	self.height = height
	self.weight = buffer.create(n * 4)
	self.cost = buffer.create(n * 4)

	for i = 0, n - 1 do
		buffer.writef32(self.weight, i * 4, 1)
	end

	self._parts = {}
	self._partsFolder = Instance.new("Folder")

	return setmetatable(self, Grid)	
end

function Grid.createParts(self: Grid, topLeftAnchor: Vector3, cellSize: Vector3)
	topLeftAnchor = topLeftAnchor or DEF_TOP_LEFT_ANCHOR
	cellSize = cellSize or DEF_CELL_PART_SIZE

	self._partsFolder.Parent = workspace
	
	for y = 1, self.width do
		for x = 1, self.height do
			local index = self:index(x, y) + 1

			local cell = Instance.new("Part")
			cell.Anchored, cell.CanCollide, cell.CanTouch = true, false, true
			cell.TopSurface = Enum.SurfaceType.Smooth
			cell.Size = cellSize
			cell.Position = Vector3.new(cellSize.X * (x - 1), topLeftAnchor.Y, cellSize.Z * (y - 1)) 
			cell.Name = `Cell{index}`
			cell.Parent = self._partsFolder

			local surfaceGui = Instance.new("SurfaceGui")
			surfaceGui.Name = "DisplaySurface"
			surfaceGui.Face = Enum.NormalId.Top
			surfaceGui.Adornee = cell
			surfaceGui.Parent = cell

			local dataDisplay = Instance.new("TextLabel")
			dataDisplay.Name = "DataDisplay"
			dataDisplay.BackgroundTransparency = 1
			dataDisplay.Size = UDim2.fromScale(1, 1)
			dataDisplay.TextScaled = true
			dataDisplay.Text = tostring(self:getCost(index - 1))
			dataDisplay.Parent = surfaceGui

			self._parts[index] = cell 
		end
	end
end

function Grid.isValid(self: Grid, x: number, y: number): boolean
	return x > 0 and x <= self.width and y > 0 and y <= self.height
end

function Grid.index(self: Grid, x: number, y: number): number
	return (y - 1) * self.width + x - 1
end

function Grid.getPart(self: Grid, i: number): BasePart?
	-- is it good practice to assume that i is zero-cell based?
	return self._parts[i + 1]
end

function Grid.getWeight(self: Grid, i: number): number
    return buffer.readf32(self.weight, i * 4)
end

function Grid.setWeight(self: Grid, i: number, w: number)
    buffer.writef32(self.weight, i * 4, w)
end

function Grid.getCost(self: Grid, i: number): number
    return buffer.readf32(self.cost, i * 4)
end

function Grid.setCost(self: Grid, i: number, w: number)
    buffer.writef32(self.cost, i * 4, w)

	local part = self:getPart(i)
	if part == nil then return end

	local label = getDataDisplay(part)
	if label == nil then return end

	label.Text = tostring(self:getCost(i));
end

return Grid;
