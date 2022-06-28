local Players = game:GetService("Players")

local ActionMapping = {
	["use"] = 1,
	["hitEffect"] = 2,
	["equip"] = 3,
}

local PlayerRemoteService = {}

function PlayerRemoteService:FireClient(remote, client, ...)
	remote:FireClient(client, ...)
end

function PlayerRemoteService:FireAllClients(remote, ...)
	remote:FireAllClients(...)
end

function PlayerRemoteService:FireAllClientsExclude(remote, exclude, ...)
	local clients = Players:GetChildren()
	for _,client in pairs(clients) do
		if client ~= exclude then
			remote:FireClient(client, ...)
		end
	end
end

function PlayerRemoteService:FireClientWithAction(remote, client, action, ...)
	local actionMapping = ActionMapping[action]
	remote:FireClient(client, actionMapping, ...)
end

function PlayerRemoteService:FireAllClientsWithAction(remote, action, ...)
	local actionMapping = ActionMapping[action]
	remote:FireAllClients(actionMapping, ...)
end

function PlayerRemoteService:FireAllClientsExcludeWithAction(remote, action, exclude, ...)
	local actionMapping = ActionMapping[action]

	local clients = Players:GetChildren()
	for _,client in pairs(clients) do
		if client ~= exclude then
			remote:FireClient(client, actionMapping, ...)
		end
	end
end

-----------------------------------------

function PlayerRemoteService:GetActionFromId(actionId)
	for action,id in pairs(ActionMapping) do
		if actionId == id then
			return action
		end
	end
	
	return actionId
end

return PlayerRemoteService