local General = {}

function General:GetServerType()
	if game.PlaceId == 7472450623 then
		return "Real"
	else
		return "Test"
	end
end

return General