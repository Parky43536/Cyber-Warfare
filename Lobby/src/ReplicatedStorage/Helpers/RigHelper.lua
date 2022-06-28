local Players = game:GetService("Players")
local CLASSIC_HEIGHT = 5

local LimbMapping = {
    {R15 = "RightHand", R6 = "RightArm"},
	{R15 = "RightUpperArm", R6 = "RightArm"},
	{R15 = "RightLowerArm", R6 = "RightArm"},
    {R15 = "LeftHand", R6 = "LeftArm"},
    {R15 = "UpperTorso", R6 = "Torso"},
    {R15 = "LowerTorso", R6 = "Torso"},
}

local function getLimb(limb, rigType)
    for _,mapping in pairs(LimbMapping) do
        if rigType == "R15" then
            if mapping.R6 == limb then
                return mapping.R15
            end
        elseif rigType == "R6" then
            if mapping.R15 == limb then
                return mapping.R6
            end
        end
    end

    return limb
end

local function getObjectValue(parent, name, default)
	local found = parent:FindFirstChild(name)
	if found then
		return found.Value
	end
	return default
end

local function matchHeadToMesh(head, headMesh)
	for _, child in pairs(head:GetChildren()) do
		if child:IsA("Attachment") and not headMesh:FindFirstChild(child.Name) then
			local vec3Copy = Instance.new("Vector3Value")
			vec3Copy.Name = child.Name
			vec3Copy.Value = child.Position
			vec3Copy.Parent = headMesh
		end
	end

	local partScaleType = head:FindFirstChild("AvatarPartScaleType")
	if partScaleType and not headMesh:FindFirstChild("AvatarPartScaleType") then
		partScaleType:Clone().Parent = headMesh
	end
end

local function getMaxHeight(humanoid)
	local hrp = humanoid.RootPart
	local character = humanoid.Parent

	local upperTorso = character.UpperTorso
	local head = character.Head

	local root = character.LowerTorso.Root
	local waist = upperTorso.Waist
	local neck = head.Neck

	-- part0 * c0 == part1 * c1
	local lowerTorsoCF = root.C0 * root.C1:Inverse()
	local upperTorsoCF = lowerTorsoCF * waist.C0 * waist.C1:Inverse()
	local headCF = upperTorsoCF * neck.C0 * neck.C1:Inverse()

	local upperTorsoTop = upperTorsoCF.Y + upperTorso.Size.Y/2
	local headTop = headCF.Y + head.Size.Y/2

	-- Sometimes the upper torso is higher than the head.
	-- For example: https://www.roblox.com/bundles/429/Magma-Fiend
	return math.max(upperTorsoTop, headTop) + hrp.Size.Y/2 + humanoid.HipHeight
end

local RigHelper = {}

function RigHelper.GetLimb(character, limb)
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then

            assert(humanoid:IsA("Humanoid"), "needs a humanoid")

            if humanoid.RigType == Enum.HumanoidRigType.R6 then
                local limbFind = character:FindFirstChild(getLimb(limb, "R6"))
                if limbFind then
                    return limbFind
                end
            else
                local limbFind = character:FindFirstChild(getLimb(limb, "R15"))
                if limbFind then
                    return limbFind
                end
            end

            return false
        end
    end
end

function RigHelper.ConvertScale(character)
    local humanoid = character.Humanoid
	local hrp = character.HumanoidRootPart

	local floorCF = hrp.CFrame * CFrame.new(0, -(hrp.Size.Y/2 + humanoid.HipHeight), 0)

	local height = getMaxHeight(humanoid)
	local scale = (CLASSIC_HEIGHT / height) * getObjectValue(humanoid, "BodyHeightScale", 1)
    local hrpScale = 2 / hrp.Size.Y

    if scale <= 0 then
        scale = math.max(scale, hrpScale)
    else
        scale = math.min(scale, hrpScale)
    end

	local head = character.Head
	local headMesh = head:FindFirstChildWhichIsA("SpecialMesh")
	local isFileMesh = false
	
	if headMesh then
		isFileMesh = (headMesh.MeshType == Enum.MeshType.FileMesh)
	end

	local accessories = {}
	for _, accessory in pairs(character:GetChildren()) do
		if accessory:IsA("Accessory") then
			local handle = accessory:FindFirstChildWhichIsA("BasePart")
			local weld = handle:FindFirstChild("AccessoryWeld")
			if weld then
				weld:Destroy()
			end
			accessory.Parent = nil
			accessories[accessory] = true
		end
	end
	
	if headMesh then
		matchHeadToMesh(head, headMesh)
	end

	for _, child in pairs(character:GetDescendants()) do
		if child:IsA("Motor6D") then
			local p0 = child.C0.Position
			local p1 = child.C1.Position
			child.C0 = (child.C0 - p0) + p0 * scale
			child.C1 = (child.C1 - p1) + p1 * scale
		elseif child:IsA("Attachment") then
			child.Position = child.Position * scale
			child.OriginalPosition.Value = child.OriginalPosition.Value * scale
		elseif child.Name == "OriginalSize" then
			local parent = child.Parent

			if parent:IsA("BasePart") then
				parent.Size = parent.Size * scale
				child.Value = child.Value * scale
			elseif headMesh and parent == headMesh then
				for _, v3 in pairs(parent:GetChildren()) do
					if v3:IsA("Vector3Value") and v3 ~= child then
						v3.Value = v3.Value * scale
					end
				end

				if isFileMesh then
					parent.Scale = parent.Scale * scale
					child.Value = child.Value * scale
				end
			end
		end
	end

	for accessory, _ in pairs(accessories) do
		local handle = accessory:FindFirstChildWhichIsA("BasePart")
		handle.OriginalSize.Value = handle.OriginalSize.Value * scale
		humanoid:AddAccessory(accessory)
	end

	humanoid.HipHeight = humanoid.HipHeight * scale
	hrp.CFrame = floorCF * CFrame.new(0, hrp.Size.Y/2 + humanoid.HipHeight, 0)
end

return RigHelper