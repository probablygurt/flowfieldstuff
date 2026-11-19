local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Signal = require(ServerScriptService.Server.fixedmodules.Signal)
local Types = require(ServerScriptService.Server.fixedmodules.Types)

local TICKS_PER_SECOND = 30

type TaskLink = Types.TaskLink
type TaskList = Types.TaskList
type TaskManager = {
    StartTime: number?,
    Tick: number,
    OnTick: Types.Signal,
    PostTicks: Types.Signal,

    init: () -> (),
    start: () -> (),
    delay: (amount: number, fn: () -> () | thread, ...any) -> (),
    wait: (amount: number) -> (any)
}

local TaskLink = {}

function TaskLink.new(fn: () -> () | thread, fromLink, args): TaskLink
    local link = {
        task = fn,
        previous = fromLink,
        next = nil,
        args = args
    }

    if fromLink ~= nil then
        fromLink.next = link
    end

    return link
end

local TaskList = {}
TaskList.__index = TaskList

function TaskList.new(): TaskList
    local self = {
        head = nil
    } :: TaskList

    return setmetatable(self, TaskList)
end

function TaskList.add(self, fn: () -> () | thread, ...)
    local newHead = TaskLink.new(fn, self.head, ...)
    self.head = newHead

    return newHead
end

local TaskManager = {} :: TaskManager

local tasks: {TaskList} = {}
local heartbeatConnection = nil 

local function heartbeat(deltaTime: number)
    local startTime = TaskManager.StartTime
    if startTime == nil then return end 

    local currentTime = workspace:GetServerTimeNow()
    local currentTick = math.floor((currentTime - startTime) * TICKS_PER_SECOND)

    while TaskManager.Tick < currentTick do
        TaskManager.Tick += 1
        TaskManager.OnTick:Fire(TaskManager.Tick)

        local taskList = tasks[TaskManager.Tick]
        if taskList == nil then continue end 

        tasks[TaskManager.Tick] = nil
        local link = taskList.head

        while link ~= nil do
            task.spawn(link.task, TaskManager.Tick, link.args)
            link = link.previous
        end
    end

    TaskManager.PostTicks:Fire(currentTick)
end

local function startHeartbeat(startTime: number)
    if heartbeatConnection ~= nil then return end 

    TaskManager.StartTime = startTime
    heartbeatConnection = RunService.Heartbeat:Connect(heartbeat)
end

function TaskManager.init()
    TaskManager.Tick = 0
    TaskManager.OnTick = Signal.new()
    TaskManager.PostTicks = Signal.new()
end

function TaskManager.start()
    startHeartbeat(workspace:GetServerTimeNow())
end

function TaskManager:delay(amount: number, fn: () -> () | thread, ...)
    local targetTick = TaskManager.Tick + math.max(amount, 1)

    local taskList = tasks[targetTick]
    if taskList == nil then
        taskList = TaskList.new()
        tasks[targetTick] = taskList
    end

    taskList:add(fn, ...)
    print(targetTick)
end

function TaskManager:wait(amount: number): ...any
    local targetTick = TaskManager.Tick + math.max(amount, 1)

    local taskList = tasks[targetTick]
    if taskList == nil then
        taskList = TaskList.new()
        tasks[targetTick] = taskList
    end

    taskList:add(coroutine.running())

    return coroutine.yield()
end

return TaskManager