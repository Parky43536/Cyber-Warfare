local SharedFunctions = {}

------ MATH ------

function SharedFunctions:ArrivalTime(originPos, desiredPos)
	local arrivalTime = (originPos - desiredPos).Magnitude / 100
	arrivalTime = math.clamp(arrivalTime, 0.1, 3)
	return arrivalTime
end

------ DATA ------

function SharedFunctions:ShallowCopy(list)
	local newList = {}
	for i,v in pairs(list) do
		newList[i] = v
	end

	return newList
end

function SharedFunctions:CountDictionary(dictionary)
	local count = 0

	for index,value in pairs(dictionary) do
		count += 1
	end

	return count
end

------ MISC ------

function SharedFunctions:GetTime(convertToUTC)
	if convertToUTC then
		return os.time(os.date("!*t"))
	else
		return workspace:GetServerTimeNow()
	end
end

return SharedFunctions
