local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GridBuilder = require(ServerScriptService.Server.fixedmodules.Grid.GridBuilder)
local GridManager = require(ServerScriptService.Server.fixedmodules.Grid.GridManager)
local TaskManager = require(ReplicatedStorage.Shared.TaskManager)
local Types = require(ReplicatedStorage.Shared.Types)
local UnitManager = require(script.Parent.UnitManager)
local DijkstraSolver = require(ServerScriptService.Server.fixedmodules.Pathfinding.DijkstraSolver)
local UnitProfiles = require(script.Parent.UnitProfiles)

type Unit = Types.Unit
type Pathfinder = Types.Pathfinder

local UNIT_STEP = 0.1

local Unit = {}
local UnitClass = {}
UnitClass.__index = UnitClass

local remotes = ReplicatedStorage.Remotes :: Folder
local renderUnit = remotes.RenderUnit :: RemoteEvent
local updateWaypoints = remotes.UpdateWaypoints :: RemoteEvent

local unitModelsFolder = ReplicatedStorage.Units :: Folder
local unitModels: {[string]: Model} = {}
local units: {Unit} = {}
local finishedUnits = {}

local totalUnits = 0

local function preloadUnitModels()
    for name, profile in UnitProfiles do
        if typeof(profile) ~= "table" then continue end
        
        local unitModel = unitModelsFolder:FindFirstChild(name) :: Model?
        if unitModel == nil then
            warn(`No unit model found for {name}, skipping..`)
            continue
        end

        local hitbox = unitModel:FindFirstChild("Hitbox")
        if hitbox == nil then
            warn(`No hitbox part found for model {name}, skipping..`) 
            continue
        end

        unitModels[name] = unitModel
    end
end

function Unit.new(profileName, spawnPos: Vector2): Unit?
    local profile = UnitProfiles[profileName]
    
    local model = unitModels[profileName]
    assert(model, `Couldn't make unit object for {profileName} without an available unit model`)

    local pathfinder = UnitManager.Pathfinders[profileName]
    assert(pathfinder, `Couldn't make unit object for {profileName} without an initialized pathfinder object`)    

    local grid = pathfinder.grid
    assert(grid:isValid(spawnPos.X, spawnPos.Y), `Couldn't make unit object for {profileName} with an invalid position`)

    local path = DijkstraSolver.tracePath(grid, spawnPos)
    if #path < 2 then
        warn(`Couldn't make unit object for {profileName} with an invalid position`)
        return
    end

    local waypoints = pathfinder:getWaypoints(path)
    
    local self = {} :: Unit
    self.name = profileName
    self.position = spawnPos
    self.health = profile.Health
    self.maxHealth = profile.Health
    self.speed = profile.Speed
    self.waypoints = waypoints
    self.targetIndex = -1
    self.waypointIndex = 1   
    self.cframe = waypoints[1]

    table.insert(units, self)
    self.unitIndex = #units

    totalUnits += 1
    self.targetIndex = totalUnits 

    local anchor = GridBuilder.getMapCellAnchor(GridManager.Map, GridManager.CellSize)

    self.onTickConnection = TaskManager.OnTick:Connect(function()
        self:step()
        self.position = GridBuilder.worldCfToPoint(anchor, GridManager.CellSize, self.cframe)

        workspace.Enemy:PivotTo(self.cframe)
    end)

    self.gridSolvedConnection = UnitManager.gridSolved:Connect(function(name: string)
        if name ~= profileName then return end 

        local path = DijkstraSolver.tracePath(grid, self.position)
        local newWaypoints = pathfinder:getWaypoints(path)

        self.waypoints = {self.cframe}

        for i = 1, #newWaypoints do
            -- we dont need to add first new waypoint if it's the same as self.cframe
            -- this'll cause issues with the step function
            if i == 1 and newWaypoints[i].Position == self.cframe.Position then continue end 
            table.insert(self.waypoints, newWaypoints[i])
        end

        self.waypointIndex = 1
        self.cframe = self.waypoints[1]

        updateWaypoints:FireAllClients(self.targetIndex, self.waypoints, TaskManager.Tick)
    end)

    renderUnit:FireAllClients(profileName, self.targetIndex, self.waypoints, TaskManager.Tick, self.speed)

    return setmetatable(self, UnitClass)
end

function UnitClass.step(self: Unit)
    local waypoints = self.waypoints 
    local currWaypoint = waypoints[self.waypointIndex]
    local nextWaypoint = waypoints[self.waypointIndex + 1]
    
    if nextWaypoint == nil then
        finishedUnits[self.targetIndex] = TaskManager.Tick
        self:destroy()
        return
    end 

    local currCFrame = self.cframe
    local dir = nextWaypoint.Position - currWaypoint.Position
    currCFrame = CFrame.lookAlong(currCFrame.Position + dir.Unit * self.speed * UNIT_STEP, dir)

    local passed = (currCFrame.Position - nextWaypoint.Position):Dot(dir) >= 0
    if passed then
        currCFrame = nextWaypoint
        self.waypointIndex += 1
    end

    self.cframe = currCFrame

    print(currWaypoint.Position, nextWaypoint.Position, currCFrame.Position)
end

function UnitClass.destroy(self: Unit)
    local i = table.find(units, self)
    if i == nil then return end 

    local last = #units

    if i ~= last then
        units[i] = units[last]
    end

    self.onTickConnection:Disconnect()
    self.gridSolvedConnection:Disconnect()
    units[last] = nil
    setmetatable(self, nil)
end

function Unit.init()
    preloadUnitModels()
end

function Unit.start()

end

return Unit