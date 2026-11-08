local DEF_TOP_LEFT_ANCHOR = Vector3.yAxis * 0.5
local DEF_CELL_PART_SIZE = Vector3.new(4, 1, 4)

local Grid = {}
Grid.__index = Grid

type GridData = {
	width: number,
	length: number,
	_data: {any},
	_parts: {any},
	_partsFolder: Folder
}

export type Grid = typeof(setmetatable({} :: GridData, Grid))

function Grid.new(width, length): Grid
	local self = {}
	self.width = width
	self.length = length
	self._data = {}
	self._parts = {}
	self._partsFolder = Instance.new("Folder")
	
	return setmetatable(self, Grid)	
end

function Grid.createParts(self: Grid, topLeftAnchor: Vector3, cellSize: Vector3)
	topLeftAnchor = topLeftAnchor or DEF_TOP_LEFT_ANCHOR
	cellSize = cellSize or DEF_CELL_PART_SIZE

	self._partsFolder.Parent = workspace
	
	for y = 0, self.width - 1 do
		for x = 1, self.length do
			local cell = Instance.new("Part")
			cell.Anchored, cell.CanCollide, cell.CanTouch = true, false, true
			cell.TopSurface = Enum.SurfaceType.Smooth
			cell.Size = cellSize
			cell.Position = Vector3.new(cellSize.X * (x - 1), topLeftAnchor.Y, cellSize.Z * y) 
			cell.Parent = self._partsFolder
			
			self._parts[self.length * y + x] = cell 
		end
	end
end

function Grid.index(self: Grid, x: number, y: number): number
	return self.length * (y - 1) + x
end

function Grid.getPart(self: Grid, x: number, y: number): Part
	return self._parts[self.length * (y - 1) + x]
end

return Grid;
