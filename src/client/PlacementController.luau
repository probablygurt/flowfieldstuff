local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local map = workspace.Map :: Model
local camera = workspace.CurrentCamera :: Camera

local remotes = ReplicatedStorage.Remotes :: Folder
local requestGridSize = remotes.RequestGridSize :: RemoteFunction

local PlacementController = {
    Mode = {
        None = 0,
        Build = 1,
        Destroy = 2
    },

    MouseRaycastParams = RaycastParams.new(),
    GridCoords = Vector2.zero
}

local renderSteppedConnection: RBXScriptConnection?

PlacementController.MouseRaycastParams.FilterType = Enum.RaycastFilterType.Include
PlacementController.MouseRaycastParams:AddToFilter(map)

local topLeft: CFrame
local cellSize: Vector2
local gridSize: Vector2 = requestGridSize:InvokeServer()

local function initializeMapTopLeft()
    local base = map.PrimaryPart
    local baseSize = base.Size
    local baseCFrame = base.CFrame

    cellSize = map:GetAttribute("CellSize")
    
    if cellSize == nil then
        local gridParts = base:FindFirstChild("GridParts") :: Folder?
  
        if gridParts ~= nil then
            local v = gridParts:GetChildren()[1] :: BasePart
            cellSize = Vector2.new(v.Size.X, v.Size.Z)
        end
    end
    
    topLeft = baseCFrame * CFrame.new(
        -baseSize.X * 0.5,
        baseSize.Y * 0.5,
        -baseSize.Z * 0.5
    )
end

local function castMouseRay(rayDist: number?): Vector3
    rayDist = rayDist or 200

    local mousePosition = UIS:GetMouseLocation()
    local unitRay = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
    local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * rayDist, PlacementController.MouseRaycastParams)
    
    if raycastResult ~= nil then
        return raycastResult.Position
    else
        return unitRay.Origin + unitRay.Direction * rayDist
    end
end

local function getLocalMousePosition(): Vector2
    local mousePos = castMouseRay()

    workspace.MousePos.Position = mousePos

    local localPos = topLeft:PointToObjectSpace(mousePos)
    local x = math.clamp(math.ceil(localPos.X / cellSize.X), 1, gridSize.X)
    local y = math.clamp(math.ceil(localPos.Z / cellSize.Y), 1, gridSize.Y)

    return Vector2.new(x, y)
end

local function onRenderStepped(delta: number)
    local gridCoords = getLocalMousePosition()

    if PlacementController.GridCoords ~= gridCoords then
        PlacementController.GridCoords = gridCoords
    end
end

function PlacementController.Start()
   if renderSteppedConnection ~= nil then return end 
   
   initializeMapTopLeft()
   renderSteppedConnection = RunService.RenderStepped:Connect(onRenderStepped)
end

function PlacementController.Stop()
    if renderSteppedConnection == nil then return end 

    renderSteppedConnection:Disconnect()
    renderSteppedConnection = nil
end

return PlacementController