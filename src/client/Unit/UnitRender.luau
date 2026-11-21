local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TaskManager = require(ReplicatedStorage.Shared.TaskManager)
local Types = require(ReplicatedStorage.Shared.Types)

local UNIT_STEP = 0.1

type RenderState = Types.RenderState

local UnitRender = {}

local remotes = ReplicatedStorage.Remotes :: Folder
local renderUnit = remotes.RenderUnit :: RemoteEvent
local renderFinished = remotes.RenderFinished :: RemoteEvent
local updateWaypoints = remotes.UpdateWaypoints :: RemoteEvent

local unitModelsFolder = ReplicatedStorage.Units :: Folder
local unitModels: {[string]: Model} = {}

local unitsFolder: Folder
local renderStates = {}

local function preloadUnitModel(name)
    local unitModel = unitModelsFolder:FindFirstChild(name) :: Model?
    if unitModel == nil then
        warn(`No unit model found for {name}, skipping..`)
        return
    end

    local hitbox = unitModel:FindFirstChild("Hitbox")
    if hitbox == nil then
        warn(`No hitbox part found for model {name}, skipping..`) 
        return
    end

    unitModels[name] = unitModel
end

local function getUnitModel(name): Model?
    if unitModels[name] == nil then preloadUnitModel(name) end
    return unitModels[name]
end

local function destroyRenderState(renderState: RenderState, tick: number)
    if renderStates[renderState.unitIndex] ~= renderState then return end 

    renderState.connection:Disconnect()
    renderState.model:Destroy()
    renderFinished:FireServer(renderState.unitIndex, tick)
end

local function step(unitIndex, currentTick: number)
    local renderState = renderStates[unitIndex]
    if renderState == nil then return end 

    local tickDifference = math.max(currentTick - renderState.lastTick, 0)

    local unitModel = renderState.model
    local waypoints = renderState.waypoints 

    local curr = unitModel:GetPivot()
    
    for i = 1, tickDifference do
        local currWaypoint = waypoints[renderState.waypointIndex]
        local nextWaypoint = waypoints[renderState.waypointIndex + 1]
        if nextWaypoint == nil then
            destroyRenderState(renderState, renderState.lastTick + i)
            break
        end

        local dir = nextWaypoint.Position - currWaypoint.Position
        curr = CFrame.lookAlong(curr.Position + dir.Unit * UNIT_STEP * renderState.speed, dir)

        local passed = (curr.Position - nextWaypoint.Position):Dot(dir) >= 0
        if passed then
            curr = nextWaypoint
            renderState.waypointIndex += 1
        end
    end 

    if unitModel then    
        unitModel:PivotTo(curr)
    end

    renderState.lastTick = currentTick
end

local function makeRenderState(name: string, unitIndex: number, waypoints: {CFrame}, startTick: number, speed: number)
    local unitModel = getUnitModel(name)
    if unitModel == nil then return end 

    local unitModelClone = unitModel:Clone()
    unitModelClone:PivotTo(waypoints[1])
    unitModelClone.Name = tostring(unitIndex)
    unitModelClone.Parent = unitsFolder

    local renderState = {
        model = unitModelClone,
        speed = speed,
        waypoints = waypoints,
        unitIndex = unitIndex,
        waypointIndex = 1,
        lastTick = startTick,
    } :: RenderState

    renderStates[unitIndex] = renderState
    --print(`Client Tick: {TaskManager.Tick} | Server Creation Tick: {startTick}`)

    renderState.connection = TaskManager.PostTicks:Connect(function(currTick)
        step(unitIndex, currTick)
    end)
end

local function updateRenderState(unitIndex: number, waypoints: {CFrame}, currentTick)
    local renderState = renderStates[unitIndex]
    if renderState == nil then return end 

    renderState.waypoints = waypoints
    renderState.waypointIndex = 1
    renderState.lastTick = currentTick
    renderState.model:PivotTo(renderState.waypoints[1])
end

function UnitRender.init()
    unitsFolder = workspace:FindFirstChild("Units")

    if unitsFolder == nil then
        unitsFolder = Instance.new("Folder")
        unitsFolder.Name = "Units"
        unitsFolder.Parent = workspace
    end
end

function UnitRender.start()
    renderUnit.OnClientEvent:Connect(function(...)
        makeRenderState(...)       
    end)

    updateWaypoints.OnClientEvent:Connect(function(...)
        updateRenderState(...)   
    end)
end

return UnitRender