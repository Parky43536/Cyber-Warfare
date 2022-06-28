local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local IsServer = RunService:IsServer()

local Helpers = ReplicatedStorage:WaitForChild("Helpers")
local RigHelper = require(Helpers:WaitForChild("RigHelper"))
local ErrorCodeHelper = require(Helpers:WaitForChild("ErrorCodeHelper"))

local Utility = ReplicatedStorage:WaitForChild("Utility")
local SharedFunctions = require(Utility:WaitForChild("SharedFunctions"))
local AudioService = require(Utility:WaitForChild("AudioService"))
local PlayerRemoteService = require(Utility:WaitForChild("PlayerRemoteService"))
local PlayerTargetFunctions = require(Utility:WaitForChild("PlayerTargetFunctions"))
local TweenService = require(Utility:WaitForChild("TweenService"))
local EventService = require(Utility:WaitForChild("EventService"))
local PlayerValues = require(Utility:WaitForChild("PlayerValues"))

local FastCastFolder = Utility:WaitForChild("FastCast")
local FastCast = require(FastCastFolder:WaitForChild("FastCast"))
local General = require(Utility:WaitForChild("General"))
local PlayerChecks = require(Utility:WaitForChild("PlayerChecks"))

local RepServices = ReplicatedStorage:WaitForChild("Services")
local AnimationService = require(RepServices:WaitForChild("AnimationService"))
local TrailService = require(RepServices:WaitForChild("TrailService"))
local PartCache = require(RepServices:WaitForChild("PartCache"))
local GunService = require(RepServices:WaitForChild("GunService"))

print'tjyrhte'

local Database = ReplicatedStorage:WaitForChild("Database")
local GunData = require(Database:WaitForChild("GunData"))
local MouseIconData = require(Database:WaitForChild("MouseIconData"))
local AnimationData = require(Database:WaitForChild("AnimationData"))

local GunInjections = {
    RigHelper = RigHelper,
    ErrorCodeHelper =ErrorCodeHelper,
    SharedFunctions = SharedFunctions,
    AudioService = AudioService,
    PlayerRemoteService = PlayerRemoteService,
    PlayerTargetFunctions = PlayerTargetFunctions,
    FastCast = FastCast,
    General = General,
    PlayerChecks = PlayerChecks,
    AnimationService = AnimationService,
    PlayerValues = PlayerValues,
    TrailService = TrailService,
    PartCache = PartCache,
    GunService = GunService,
    GunData = GunData,
    MouseIconData = MouseIconData,
    AnimationData = AnimationData,
    TweenService = TweenService,
    EventService = EventService,
}

if IsServer then
    local SerServices = ServerScriptService:WaitForChild("Services")
    GunInjections["BanService"] = require(SerServices:WaitForChild("BanService"))
end

return GunInjections