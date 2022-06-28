local EventService = {}
EventService.Events = {}

local function createNewEvent(event)
    local newEvent = Instance.new("BindableEvent")
    EventService.Events[event] = newEvent
end

function EventService:FireEvent(event, ...)
    if not self.Events[event] then createNewEvent(event) end
    self.Events[event]:Fire(...)
end

function EventService:GetEvent(event)
    if not self.Events[event] then createNewEvent(event) end
    return self.Events[event]
end

return EventService