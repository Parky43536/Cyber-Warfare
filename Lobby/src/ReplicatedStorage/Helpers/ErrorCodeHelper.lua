local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Database = ReplicatedStorage.Database
local ErrorCodeData = require(Database:WaitForChild("ErrorCodeData"))

local ErrorCodeHelper = {}

function ErrorCodeHelper.FormatCode(id, extra)
	return "Code: "..id.."\n"..ErrorCodeData[id].."\n"..(extra or "")
end
return ErrorCodeHelper