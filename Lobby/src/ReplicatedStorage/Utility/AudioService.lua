local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local Utility = ReplicatedStorage:WaitForChild("Utility")
local TweenService = require(Utility:WaitForChild("TweenService"))

local IsServer = RunService:IsServer()
local IsClient = RunService:IsClient()

local LocalPlayer

local Signal
if IsServer then
	Signal = Instance.new("RemoteEvent")
	Signal.Name = "Signal"
	Signal.Parent = script
elseif IsClient then
	Signal = script:WaitForChild("Signal")
	LocalPlayer = Players.LocalPlayer
end

local function createSoundContainer(cframe)
	local newContainer = Instance.new("Part")
	newContainer.Transparency = 1
	newContainer.CastShadow = false
	newContainer.Anchored = true
	newContainer.CanCollide = false
	newContainer.CanTouch = false
	newContainer.CanQuery = false
	newContainer.Locked = true
	newContainer.CFrame = cframe
	newContainer.Size = Vector3.new(1, 1, 1)
	newContainer.Parent = workspace.Sound

	return newContainer
end

local AudioService = {}
AudioService.SavedAudios = {}
AudioService.CurrentMusic = nil
AudioService.CurrentVoiceLine = nil
AudioService.VoiceLineQueue = {}

-- id: int of numbers, string of numbers, or entire id link		ex. 4069771750, rbxassetid://4069771750
-- target: instance, vector3, cframe							ex. workspace.Sound, Vector3.new(0,0,0), CFrame.new(0,0,0)
-- properties: list of sound properties and values				ex. {Looped = true, MaxDistance = 5}
-- effects: list of effect instance names and their properties	ex. {PitchShiftSoundEffect = {Octave = 0.5}}

-- full example usage: AudioService:Create(4069771750, tower,PrimaryPart, {Looped = true}, {PitchShiftSoundEffect = {Octave = 0.5})

-- all sounds/containers are automatically destroyed after the sound has ended unless the sound is looped
-- if the container was given, only the sound object will be destroyed
function AudioService:Create(id, target, properties, effects, saveId)
	if not saveId or not self.SavedAudios[saveId] then
		if IsServer then
			Signal:FireAllClients("Create", id, target, properties, effects, saveId)
			return
		end

		--local playerSoundVolume = SettingsService:GetSetting(LocalPlayer, "Sound")

		id = tostring(id)
		properties = properties or {}

		if not id:match("%d+") then
			error("SoundId must be a string of all number characters")
		end

		local newSoundObject = Instance.new("Sound")
		newSoundObject.Name = (properties or {}).Name or id
		newSoundObject.SoundId = "rbxassetid://"..id:match("%d+")

		for effect, properties in pairs(effects or {}) do
			local newEffect = Instance.new(effect)
			for property, value in pairs(properties or {}) do
				newEffect[property] = value
			end

			newEffect.Parent = newSoundObject
		end

		newSoundObject["Volume"] = 0.2
		for property, value in pairs(properties or {}) do
			if property ~= "Delay" and property ~= "NoAutoPlay" and property ~= "LoopDuration" and property ~= "Duration" and property ~= "DontDelete" then
				newSoundObject[property] = value
			elseif property == "LoopDuration" then
				newSoundObject["Looped"] = true
			end
		end

		newSoundObject:SetAttribute("OriginalVolume", newSoundObject["Volume"])
		--newSoundObject["Volume"] *= playerSoundVolume

		local container
		local createdContainer = false

		if typeof(target) == "Instance" then
			container = target
		elseif typeof(target) == "Vector3" then
			container = createSoundContainer(CFrame.new(target))
			createdContainer = true
		elseif typeof(target) == "CFrame" then
			container = createSoundContainer(target)
			createdContainer = true
		end

		newSoundObject.Parent = container

		task.spawn(function()
			if saveId then
				if createdContainer then
					self.SavedAudios[saveId] = container
				else
					self.SavedAudios[saveId] = newSoundObject
				end
			end

			if not properties.NoAutoPlay then
				if newSoundObject.TimeLength <= 0 then
					repeat
						task.wait()
					until newSoundObject.TimeLength > 0
				end

				if properties and properties.Duration then
					local speed = newSoundObject.TimeLength / properties.Duration
					newSoundObject.PlaybackSpeed = speed
				end

				task.wait((properties or {}).Delay or 0.01)
				newSoundObject:Play()
			end

			if not properties.DontDelete then
				if not newSoundObject.Looped  then
					newSoundObject.Ended:Connect(function()
						if createdContainer then
							container:Destroy()
						else
							newSoundObject:Destroy()
						end
					end)
				elseif properties and properties.LoopDuration then
					task.wait((properties or {}).LoopDuration or 0)
					if createdContainer then
						container:Destroy()
					else
						newSoundObject:Destroy()
					end
				end
			end
		end)

		return newSoundObject, container
	end
	return false, false
end

function AudioService:PlayMusic(id, properties)
	if IsServer then
		Signal:FireAllClients("PlayMusic", id, properties)
		return
	end

	local fadeTime = 0
	if AudioService.CurrentMusic then
		if string.find(AudioService.CurrentMusic.SoundId, id) then
			return -- don't want to play the same track twice
		end

		fadeTime = 1
		AudioService:Fade(AudioService.CurrentMusic, fadeTime, 0)
	end

	properties = properties or {}
	properties.Looped = properties.Looped or true
	properties.NoAutoPlay = properties.NoAutoPlay or true
	properties.Volume = properties.Volume or 0.2

	--local playerMusicVolume = SettingsService:GetSetting(LocalPlayer, "Music")
	local musicObject = AudioService:Create(id, SoundService:WaitForChild("Music"), properties)
	--musicObject.Volume *= playerMusicVolume

	task.delay(fadeTime, function()
		if AudioService.CurrentMusic then AudioService.CurrentMusic:Destroy() end

		AudioService.CurrentMusic = musicObject
		AudioService.CurrentMusic:Play()
	end)

	return musicObject
end

function AudioService:GetCurrentMusic()
	return AudioService.CurrentMusic
end

function AudioService:Fade(object, fadeTime, fadeValue)
	if object then
		local goal = {Volume = fadeValue}
		local properties = {Time = fadeTime}
		TweenService.tween(object, goal, properties)
	end
end

function AudioService:Destroy(saveId)
	if self.SavedAudios[saveId] then
		self.SavedAudios[saveId]:Destroy()
		self.SavedAudios[saveId] = nil
	end
end

------------------------------
if IsClient then
	Signal.OnClientEvent:Connect(function(func, ...)
		if AudioService[func] then
			AudioService[func](nil, ...)
		end
	end)

	--[[SettingsService:SetCallback("Music", function(player, value)
		if player == LocalPlayer then
			local currentMusic = AudioService:GetCurrentMusic()
			if currentMusic then
				currentMusic.Volume = currentMusic:GetAttribute("OriginalVolume") * value
			end
		end
	end)]]
end

return AudioService