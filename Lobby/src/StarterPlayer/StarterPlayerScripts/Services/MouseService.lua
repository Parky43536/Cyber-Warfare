local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local MouseService = {}

function MouseService:Whitelist(whitelist, args)
    local camera = workspace.CurrentCamera

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = whitelist or {}
    raycastParams.FilterType = Enum.RaycastFilterType.Whitelist

    -- trying to be very efficient here so we don't need to create a new empty args table to avoid error
    local position
    if args then
        position = args.customPosition or Mouse.Hit.Position
    else
        position = Mouse.Hit.Position
    end

    local raycastResult = workspace:Raycast(camera.CFrame.Position, (position - camera.CFrame.Position).Unit * 500, raycastParams)
    if raycastResult then
        return raycastResult.Position
    else
        return camera.CFrame.Position + (Mouse.Hit.Position - camera.CFrame.Position).Unit * 1000
    end
end

function MouseService:Blacklist(blacklist)
    local camera = workspace.CurrentCamera

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = blacklist or {}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult = workspace:Raycast(camera.CFrame.Position, (Mouse.Hit.Position - camera.CFrame.Position).Unit * 500, raycastParams)
    if raycastResult then
        return raycastResult.Position
    else
        return camera.CFrame.Position + (Mouse.Hit.Position - camera.CFrame.Position).Unit * 1000
    end
end

return MouseService