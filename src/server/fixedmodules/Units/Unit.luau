local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

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
local renderFinished = remotes.RenderFinished :: RemoteEvent

local unitModelsFolder = ReplicatedStorage.Units :: Folder
local unitModels: {[string]: Model} = {}
local units: {Unit} = {}
local finishedRenders = {}
local finishedRenderCount = 0
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

    self.onTickConnection = TaskManager.OnTick:Connect(function()
        self:step()
    end)

    renderUnit:FireAllClients(profileName, self.targetIndex, self.waypoints, TaskManager.Tick)

    return setmetatable(self, UnitClass)
end

local function checkMismatch(unitIndex: number)
    local cntBefore = finishedUnits[unitIndex]
    for _, list in finishedRenders do
        if cntBefore ~= list[unitIndex] then return true end
        cntBefore = list[unitIndex]
    end

    return false
end

renderFinished.OnServerEvent:Connect(function(a0: Player, unitIndex: number, tickFinished: number)
	if finishedRenders[a0] == nil then finishedRenders[a0] = {} end
	
	finishedRenders[a0][unitIndex] = tickFinished
	
    local i = 0
    local min = finishedRenderCount
	for _, list in finishedRenders do
        if i == 0 then
            min = #list
        end

		finishedRenderCount = math.min(#list, min)
	end
end)

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
end

function UnitClass.destroy(self: Unit)
    local i = table.find(units, self)
    if i == nil then return end 

    local last = #units

    if i ~= last then
        units[i] = units[last]
    end

    self.onTickConnection:Disconnect()
    units[last] = nil
    setmetatable(self, nil)
end

function Unit.init()
    preloadUnitModels()
end

function Unit.start()
    local c
    c = TaskManager.PostTicks:Connect(function()
        if #finishedUnits < 100 then return end
        print(#finishedUnits, finishedRenderCount)
        if #finishedUnits < 2000 or finishedRenderCount < 2000 then return end 

        local mismatches = 0

        for i = 1, 200 do
            if not checkMismatch(i) then continue end 
            mismatches += 1
        end

        warn(`MISMATCHES: {mismatches}`)

        c:Disconnect()
    end)
end

return Unit