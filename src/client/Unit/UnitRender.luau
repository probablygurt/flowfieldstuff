local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TaskManager = require(ReplicatedStorage.Shared.TaskManager)
local Types = require(ReplicatedStorage.Shared.Types)

local UnitRender = {}

local remotes = ReplicatedStorage.Remotes :: Folder
local renderUnit = remotes.RenderUnit :: RemoteEvent
local renderFinished = remotes.RenderFinished :: RemoteEvent

local unitModelsFolder = ReplicatedStorage.Units :: Folder
local unitModels: {[string]: Model} = {}

local unitsFolder: Folder

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

local function step()

end

local UNIT_STEP = 0.1

local function makeUnitModel(name: string, unitIndex: number, waypoints: {CFrame}, startTick: number)
    local unitModel = getUnitModel(name)
    if unitModel == nil then return end 

    local unitModelClone = unitModel:Clone()
    unitModelClone:PivotTo(waypoints[1])
    unitModelClone.Parent = unitsFolder

    --print(`Client Tick: {TaskManager.Tick} | Server Creation Tick: {startTick}`)

    local waypointIndex = 1
    local lastTick = startTick

    local postTickConnection: Types.Connection
    postTickConnection = TaskManager.OnTick:Connect(function(currTick)
        local tickDifference = math.max(currTick - lastTick, 0)

        local curr = unitModelClone:GetPivot()

        for i = 1, tickDifference do
            local currWaypoint = waypoints[waypointIndex]
            local nextWaypoint = waypoints[waypointIndex + 1]
            if nextWaypoint == nil then
                renderFinished:FireServer(unitIndex, TaskManager.Tick)
                unitModelClone:Destroy()
                postTickConnection:Disconnect()
                break
            end

            local dir = nextWaypoint.Position - currWaypoint.Position

            curr = CFrame.lookAlong(curr.Position + dir.Unit * UNIT_STEP * 5, dir)

            local passed = (curr.Position - nextWaypoint.Position):Dot(dir) >= 0

            if passed then
                curr = nextWaypoint
                waypointIndex += 1
            end
        end

        if unitModelClone then    
            unitModelClone:PivotTo(curr)
        end
        lastTick = currTick
    end)
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
        makeUnitModel(...)       
    end)
end

return UnitRender