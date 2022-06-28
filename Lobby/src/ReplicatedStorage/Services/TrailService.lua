local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Utility = ReplicatedStorage:WaitForChild("Utility")
local TweenService = require(Utility:WaitForChild("TweenService"))

local RepServices = ReplicatedStorage:WaitForChild("Services")
local PartCache = require(RepServices:WaitForChild("PartCache"))

local IsServer = RunService:IsServer()

local TrailFolder
if IsServer then
    TrailFolder = Instance.new("Folder")
    TrailFolder.Name = "Trails"
    TrailFolder.Parent = workspace.Projectiles
else
    TrailFolder = workspace.Projectiles:WaitForChild("Trails")
end

local TrailPartTemplate = Instance.new("Part")
TrailPartTemplate.CastShadow = false
TrailPartTemplate.Anchored = true
TrailPartTemplate.CanCollide = false
TrailPartTemplate.CanTouch = false
TrailPartTemplate.CanQuery = false
TrailPartTemplate.Size = Vector3.new(0.25,0.25,0.25)
TrailPartTemplate.Material = "Neon"

local TrailService = {}
TrailService.Trails = {}
TrailService.MockMapping = {}

if not TrailService.TrailPartCache then
    TrailService.TrailPartCache = PartCache.new(TrailPartTemplate, 150, TrailFolder)
end

local function createNewTrailPart(position, direction, length, properties, trailTable)
    local width = properties.width or 0.25
    local fadeOutTime = properties.fadeOutTime or 0.25
    local fadeInTime = properties.fadeInTime or 0.25

    local trailPart = TrailService.TrailPartCache:GetPart()
    trailPart.Material = properties.material or "Neon"
    trailPart.Size = Vector3.new(width,width,length)
    trailPart.CFrame = CFrame.new(position + direction * (length/2), position + direction*100)
    trailPart.Color = properties.color or Color3.fromRGB(255,255,255)
    trailPart.Transparency = 1

    local goal = {Transparency = properties.transparency or 0}
    local properties = {Time = fadeInTime}
    local tween = TweenService.tween(trailPart, goal, properties)

    local tweenConnection
    tweenConnection = tween.Completed:Connect(function()
        tweenConnection:Disconnect()

        local goal = {Size = Vector3.new(0,0,length), Transparency = 1}
        local properties = {Delay = 0.1, Time = fadeOutTime}
        TweenService.tween(trailPart, goal, properties)

        task.delay(properties.Time + properties.Delay + 0.1, function()
            if trailTable then
                local index = table.find(trailTable, trailPart)
                table.remove(trailTable, index)
            end

            TrailService.TrailPartCache:ReturnPart(trailPart, true)
        end)
    end)

    return trailPart
end

local function getTrailPart(properties)
    local width = properties.width or 0.25

    local trailPart = TrailService.TrailPartCache:GetPart()
    trailPart.Material = properties.material or "Neon"
    trailPart.Size = Vector3.new(width, width, width)
    trailPart.Color = properties.color or Color3.fromRGB(255,255,255)
    trailPart.Transparency = 0

    return trailPart
end

-- properties: color, duration
function TrailService.attachTrail(object, properties)
    if not properties then properties = {} end

    if not TrailService.Trails[object] then
        TrailService.Trails[object] = {}

        task.spawn(function()
            local stopTime = tick() + (properties.duration or 500)
            local stamp = tick()

            local lastObjectCFrame = object:GetPivot()

            while tick() < stopTime and (object and object.Parent) and TrailService.Trails[object] do
                local objectCFrame = object:GetPivot()

                if objectCFrame ~= lastObjectCFrame then
                    local dt = tick() - stamp
                    stamp = tick()

                    local difference = (objectCFrame.Position - lastObjectCFrame.Position)
                    local direction = difference.Unit
                    local magnitude = difference.Magnitude

                    table.insert(TrailService.Trails[object], createNewTrailPart(objectCFrame.Position, direction, 35*magnitude*dt, properties, TrailService.Trails[object]))

                    if properties.maxParts and #TrailService.Trails[object] > properties.maxParts then
                        local oldestTrailpart = TrailService.Trails[object][1]
                        table.remove(TrailService.Trails[object], 1)

                        if oldestTrailpart then
                            TrailService.TrailPartCache:ReturnPart(oldestTrailpart)
                        end
                    end
                end

                task.wait(0.01)
            end
        end)
    end
end

function TrailService.attachTrailToCFrameObject(cframeObject, properties)
    local mockObject = {
        Parent = workspace.Dynamic,
        Object = cframeObject
    }
    
    function mockObject:GetPivot()
        return self.Object.Value
    end

    TrailService.MockMapping[cframeObject] = mockObject
    TrailService.attachTrail(mockObject, properties)
end

function TrailService.createTrailPart(reference, position, direction, length, properties)
    if not properties then properties = {} end
    if not TrailService.Trails[reference] then TrailService.Trails[reference] = {} end

    table.insert(TrailService.Trails[reference], createNewTrailPart(position, direction, length, properties, TrailService.Trails[reference]))

    if properties.maxParts and #TrailService.Trails[reference] > properties.maxParts then
        local oldestTrailpart = TrailService.Trails[reference][1]
        table.remove(TrailService.Trails[reference], 1)

        if oldestTrailpart then
            TrailService.TrailPartCache:ReturnPart(oldestTrailpart)
        end
    end
end

function TrailService.getTrailPart(properties)
    if not properties then properties = {} end

    return getTrailPart(properties)
end

function TrailService.removeTrailPart(object)
    TrailService.TrailPartCache:ReturnPart(object)
end

function TrailService.removeTrail(object)
    if TrailService.Trails[object] then
        TrailService.Trails[object] = nil
    else
        local mockObject = TrailService.MockMapping[object]
        if mockObject then
            TrailService.Trails[mockObject] = nil
            TrailService.MockMapping[object] = nil
        end
    end
end

return TrailService