------------------------------------------
----- =======[ Load WindUI ]
-------------------------------------------

local Version = "1.6.53"
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Madindun/cukimaw/refs/heads/main/ui.lua"))()

-------------------------------------------
----- =======[ GLOBAL FUNCTION ]
-------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local net = ReplicatedStorage:WaitForChild("Packages")
	:WaitForChild("_Index")
	:WaitForChild("sleitnick_net@0.2.0")
	:WaitForChild("net")

local rodRemote = net:WaitForChild("RF/ChargeFishingRod")
local miniGameRemote = net:WaitForChild("RF/RequestFishingMinigameStarted")
local finishRemote = net:WaitForChild("RE/FishingCompleted")
local Constants = require(ReplicatedStorage:WaitForChild("Shared", 20):WaitForChild("Constants"))

local Player = Players.LocalPlayer
local XPBar = Player:WaitForChild("PlayerGui"):WaitForChild("XP")

LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

local VirtualUser = game:GetService("VirtualUser")

if Player and VirtualUser then
    Player.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
end

task.spawn(function()
    if XPBar then
        XPBar.Enabled = true
    end
end)

local TeleportService = game:GetService("TeleportService")
local PlaceId = game.PlaceId

local function AutoReconnect()
    while task.wait(5) do
        if not Players.LocalPlayer or not Players.LocalPlayer:IsDescendantOf(game) then
            TeleportService:Teleport(PlaceId)
        end
    end
end

Players.LocalPlayer.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Failed then
        TeleportService:Teleport(PlaceId)
    end
end)

task.spawn(AutoReconnect)

local ijump = false

local RodIdle = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("ReelingIdle")

local RodShake = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("RodThrow")

local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")


local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

local RodShake = animator:LoadAnimation(RodShake)
local RodIdle = animator:LoadAnimation(RodIdle)

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared", 5)
local Modules = ReplicatedStorage:WaitForChild("Modules", 5)

if Shared then
    if not _G.ItemUtility then
        local success, utility = pcall(require, Shared:WaitForChild("ItemUtility", 5))
        if success and utility then
            _G.ItemUtility = utility
        else
            warn("ItemUtility module not found or failed to load.")
        end
    end
    if not _G.ItemStringUtility and Modules then
        local success, stringUtility = pcall(require, Modules:WaitForChild("ItemStringUtility", 5))
        if success and stringUtility then
            _G.ItemStringUtility = stringUtility
        else
            warn("ItemStringUtility module not found or failed to load.")
        end
    end
    -- Memuat Replion, Promise, PromptController untuk Auto Accept Trade
    if not _G.Replion then pcall(function() _G.Replion = require(ReplicatedStorage.Packages.Replion) end) end
    if not _G.Promise then pcall(function() _G.Promise = require(ReplicatedStorage.Packages.Promise) end) end
    if not _G.PromptController then pcall(function() _G.PromptController = require(ReplicatedStorage.Controllers.PromptController) end) end
end

if getgenv().AutoRejoinConnection then
    getgenv().AutoRejoinConnection:Disconnect()
    getgenv().AutoRejoinConnection = nil
end

getgenv().AutoRejoinConnection = game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(
    child)
    task.wait()
    if child.Name == "ErrorPrompt" and child:FindFirstChild("MessageArea") and child.MessageArea:FindFirstChild("ErrorFrame") then
        local TeleportService = game:GetService("TeleportService")
        local Player = game.Players.LocalPlayer
        task.wait(2)
        TeleportService:Teleport(game.PlaceId, Player)
    end
end)

-- =======================================================
-- == QUIETX PERFECTION SYSTEM (AUTO REGISTER, HIDE CHAT)
-- =======================================================

_G.AUTO_MESSAGE = "!p"
_G.NEWBIE_MESSAGE = "!n"
_G.HideLocalChat = true
_G.Players = game:GetService("Players")
_G.LocalPlayer = _G.Players.LocalPlayer
_G.TextChatService = game:GetService("TextChatService")
_G.ReplicatedStorage = game:GetService("ReplicatedStorage")


if _G.HideLocalChat and not _G.ChatHiddenHooked then
    _G.ChatHiddenHooked = true

    if _G.TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        _G.TextChatService.MessageReceived:Connect(function(msg)
            if msg.TextSource and msg.TextSource.UserId == _G.LocalPlayer.UserId then
                msg:Cancel()
            end
        end)

    else
        local chatEvents = _G.ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvents and chatEvents:FindFirstChild("OnMessageDoneFiltering") then
            chatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(data)
                if data.FromSpeaker == _G.LocalPlayer.Name then
                    return nil
                end
            end)
        end
    end
end


function _G.SendChat(msg)
    task.spawn(function()

        local successNew = pcall(function()
            if _G.TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                local channel = _G.TextChatService.TextChannels.RBXGeneral
                if channel then channel:SendAsync(msg) return end
            end
        end)

        if not successNew then
            pcall(function()
                local chatEvents = _G.ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                if chatEvents and chatEvents:FindFirstChild("SayMessageRequest") then
                    chatEvents.SayMessageRequest:FireServer(msg, "All")
                end
            end)
        end
    end)
end


-- Disabled by default to prevent rate limiting
-- Uncomment below to enable auto-perfection chat messages
--[[
task.delay(1, function()
    _G.SendChat(_G.NEWBIE_MESSAGE)
    task.wait(0.4)
    _G.SendChat(_G.AUTO_MESSAGE)
end)
--]]


-- =======================================================
-- == PERFECTION SETTINGS
-- =======================================================

_G.PerfText = "PERFECTION!"
_G.PerfColor = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(64, 255, 118)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(64, 255, 118))
})

_G.TargetTexts = {
    ["ok"] = true, ["good"] = true, ["great"] = true,
    ["amazing"] = true, ["perfect!"] = true
}

_G.Rep = _G.ReplicatedStorage
_G.Effects = require(_G.Rep.Shared.Effects)
_G.VFX = require(_G.Rep.Controllers.VFXController)
_G.Sounds = require(_G.Rep.Shared.Soundbook)

_G.PerfPlayers = _G.PerfPlayers or {}

if not _G.OriginalTextEffect then
    _G.OriginalTextEffect = _G.Effects.TextEffect
end



function _G.ListenToPlayer(player)
    if player == _G.LocalPlayer then return end

    player.Chatted:Connect(function(msg)
        msg = msg:lower()

        if msg == _G.NEWBIE_MESSAGE then
            task.delay(0.3, function()
                _G.SendChat(_G.AUTO_MESSAGE)
            end)
            return
        end


        if msg == "!p" then
            _G.PerfPlayers[player.Name] = true
            print("[PERFECTION] Enabled for:", player.Name)
        end

        if msg == "!unp" then
            _G.PerfPlayers[player.Name] = nil
            print("[PERFECTION] Disabled for:", player.Name)
        end
    end)
end


-- Disabled to prevent HTTP 429 rate limiting
-- Uncomment below to enable player chat monitoring for perfection system
--[[
for _, p in ipairs(_G.Players:GetPlayers()) do
    _G.ListenToPlayer(p)
end

_G.Players.PlayerAdded:Connect(function(player)
    _G.ListenToPlayer(player)
end)
--]]


_G.Effects.TextEffect = function(self, data, ...)
    if data and data.Container and data.TextData and data.TextData.Text then

        local character = data.Container.Parent
        local owner = game.Players:GetPlayerFromCharacter(character)

        local isLocal = owner == _G.LocalPlayer
        local forced = owner and _G.PerfPlayers[owner.Name]

        if (isLocal or forced) then
            local text = string.lower(data.TextData.Text)

            if _G.TargetTexts[text] or text == string.lower(_G.PerfText) then
                data.TextData.Text = _G.PerfText
                data.TextData.TextColor = _G.PerfColor

                task.spawn(function()
                    pcall(function()
                        _G.VFX.Handle(_G.PerfText, data.Container)
                    end)
                end)

                task.spawn(function()
                    pcall(function()
                        if _G.Sounds.Sounds.Perfect then
                            _G.Sounds.Sounds.Perfect:Play()
                        elseif _G.Sounds.Sounds.PerfectCast then
                            _G.Sounds.Sounds.PerfectCast:Play()
                        end
                    end)
                end)
            end
        end
    end

    return _G.OriginalTextEffect(self, data, ...)
end


-------------------------------------------
----- =======[ NOTIFY FUNCTION ]
-------------------------------------------

local function NotifySuccess(title, message, duration)
    WindUI:Notify({
        Title = title,
        Content = message,
        Duration = duration,
        Icon = "circle-check"
    })
end

local function NotifyError(title, message, duration)
    WindUI:Notify({
        Title = title,
        Content = message,
        Duration = duration,
        Icon = "ban"
    })
end

local function NotifyInfo(title, message, duration)
    WindUI:Notify({
        Title = title,
        Content = message,
        Duration = duration,
        Icon = "info"
    })
end

local function NotifyWarning(title, message, duration)
    WindUI:Notify({
        Title = title,
        Content = message,
        Duration = duration,
        Icon = "triangle-alert"
    })
end


-------------------------------------------
----- =======[ LOAD WINDOW ]
-------------------------------------------

WindUI.TransparencyValue = 0.3

local Window = WindUI:CreateWindow({
    Title = "Fish It",
    Icon = "hop",
    Author = "by SooyFish",
    Folder = "SooyFish",
    Size = UDim2.fromOffset(600, 400),
    Transparent = true,
    Theme = "Dark",
    KeySystem = false,
    ScrollBarEnabled = true,
    HideSearchBar = true,
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
        end,
    }
})

Window:EditOpenButton({
    Title = "SooyFish",
    Icon = "hop",
    CornerRadius = UDim.new(0,19),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("9600FF"), 
        Color3.fromHex("AEBAF8")
    ),
    Draggable = true,
})

Window:Tag({
    Title = "STABLE",
    Color = Color3.fromHex("#30ff6a")
})



local ConfigManager = Window.ConfigManager
local myConfig = ConfigManager:CreateConfig("QuietXConfig")

WindUI:SetNotificationLower(true)

WindUI:Notify({
	Title = "SooyFish",
	Content = "All Features Loaded!",
	Duration = 5,
	Image = "square-check-big"
})

-------------------------------------------
----- =======[ ALL TAB ]
-------------------------------------------

local Home = Window:Tab({
	Title = "Developer Info",
	Icon = "hard-drive"
})

local AllMenu = Window:Section({
	Title = "All Menu Here",
	Icon = "tally-3",
	Opened = false,
})

local AutoFish = AllMenu:Tab({ 
	Title = "Auto Fish", 
	Icon = "fish"
})

local AutoFav = AllMenu:Tab({
	Title = "Auto Favorite",
	Icon = "star"
})

local AutoFarmTab = AllMenu:Tab({
	Title = "Auto Farm",
	Icon = "leaf"
})

local AutoFarmArt = AllMenu:Tab({
	Title = "Auto Farm Artifact",
	Icon = "flask-round"
})

local Trade = AllMenu:Tab({
	Title = "Trade",
	Icon = "handshake"
})

local Player = AllMenu:Tab({
    Title = "Player",
    Icon = "users-round"
})

local TabSkins = AllMenu:Tab({
    Title = "Skins",
    Icon = "sparkles"
})

local DStones = AllMenu:Tab({
	Title = "Double Enchant",
	Icon = "gem"
})

local Utils = AllMenu:Tab({
    Title = "Utility",
    Icon = "earth"
})

local FishNotif = AllMenu:Tab({
	Title = "Fish Notification",
	Icon = "bell-ring"
})

local SettingsTab = AllMenu:Tab({ 
	Title = "Settings", 
	Icon = "cog" 
})

-------------------------------------------
----- =======[ AUTO FISH TAB ]
-------------------------------------------

_G.REFishingStopped = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/FishingStopped"]
_G.RFCancelFishingInputs = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/CancelFishingInputs"]
_G.REUpdateChargeState = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/UpdateChargeState"]


_G.StopFishing = function()
	  _G.RFCancelFishingInputs:InvokeServer()
    firesignal(_G.REFishingStopped.OnClientEvent)
end

local FuncAutoFish = {
    REReplicateTextEffect = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ReplicateTextEffect"],
    autofish5x = false,
    perfectCast5x = true,
    fishingActive = false,
    delayInitialized = false,
    lastCatchTime5x = 0,
    CatchLast = tick(),
}



_G.REFishCaught = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/FishCaught"]
_G.REPlayFishingEffect = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/PlayFishingEffect"]
_G.equipRemote = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/EquipToolFromHotbar"]
_G.REObtainedNewFishNotification = ReplicatedStorage
    .Packages._Index["sleitnick_net@0.2.0"]
    .net["RE/ObtainedNewFishNotification"]


_G.isSpamming = false
_G.rSpamming = false
_G.spamThread = nil
_G.rspamThread = nil
_G.lastRecastTime = 0
_G.DELAY_ANTISTUCK = 10
_G.isRecasting5x = false
_G.STUCK_TIMEOUT = 10
_G.AntiStuckEnabled = false
_G.lastFishTime = tick()
_G.FINISH_DELAY = 2
_G.fishCounter = 0
_G.sellThreshold = 5
_G.sellActive = false
_G.AutoFishHighQuality = false -- [[ VARIABEL KONTROL UNTUK FITUR BARU ]]

_G.RemotePackage = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
_G.RemoteFish = _G.RemotePackage["RE/ObtainedNewFishNotification"]
_G.RemoteSell = _G.RemotePackage["RF/SellAllItems"]

_G.RemoteFish.OnClientEvent:Connect(function(_, _, data)
    if _G.sellActive and data then
        _G.fishCounter = _G.fishCounter + 1
        if _G.fishCounter >= _G.sellThreshold then
            _G.TrySellNow()
            _G.fishCounter = 0
        end
    end
end)

_G.LastSellTick = 0

function _G.TrySellNow()
    local now = tick()
    if now - _G.LastSellTick < 1 then 
        return 
    end
    _G.LastSellTick = now
    _G.RemoteSell:InvokeServer()
end

function _G.RecastSpam()
    if _G.rSpamming then return end
    _G.rSpamming = true
    _G.rspamThread = task.spawn(function()
        while _G.rSpamming do
            local ok, err = pcall(StartCast5X)
            if not ok then
                warn("StartCast5X error:", err)
                break
            end
        end
    end)
end

function _G.StopRecastSpam()
    _G.rSpamming = false
end
    

function _G.startSpam()
    if _G.isSpamming then return end
    _G.isSpamming = true
    _G.spamThread = task.spawn(function()
        task.wait(tonumber(_G.FINISH_DELAY))
        finishRemote:FireServer()
    end)
end
    
function _G.stopSpam()
   _G.isSpamming = false
end

_G.REPlayFishingEffect.OnClientEvent:Connect(function(player, head, data)
    if player == Players.LocalPlayer and FuncAutoFish.autofish5x then
        _G.StopRecastSpam()
    end
end)

local LowQualityColors = {
    ["0 0.764706 1 0.333333 0 1 0.764706 1 0.333333 0"] = true,  -- UNCOMMON
    ["0 0.333333 0.635294 1 0 1 0.333333 0.635294 1 0"] = true,  -- RARE
    ["0 1 0.980392 0.964706 0 1 1 0.980392 0.964706 0"] = true,  -- COMMON
}

local lastEventTime = tick()

task.spawn(function()
    while task.wait(1) do
        if _G.AutoFishHighQuality and FuncAutoFish.autofish5x and FuncAutoFish.REReplicateTextEffect then
            if tick() - lastEventTime > 10 then
                StopCast()
                task.wait(0.5)
                StartCast5X()
                lastEventTime = tick()
            end
        end
    end
end)

FuncAutoFish.REReplicateTextEffect.OnClientEvent:Connect(function(data)

    if not FuncAutoFish.autofish5x then return end

    local myHead = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Head")
    if not (data and data.TextData and data.TextData.TextColor and data.TextData.EffectType == "Exclaim" and myHead and data.Container == myHead) then
        return
    end
    
    lastEventTime = tick()

    if _G.AutoFishHighQuality then
        
        local colorValue = data.TextData.TextColor
        local r, g, b

        if typeof(colorValue) == "Color3" then
            r, g, b = colorValue.R, colorValue.G, colorValue.B
        elseif typeof(colorValue) == "ColorSequence" and #colorValue.Keypoints > 0 then
            local c = colorValue.Keypoints[1].Value
            r, g, b = c.R, c.G, c.B
        end

        local isBadFish = false

        if r and g and b then
            if r > 0.9 and g > 0.9 and b > 0.9 then
                -- COMMON
                isBadFish = true
            elseif b > 0.9 and r < 0.4 then
                -- RARE
                isBadFish = true
            elseif g > 0.9 and b < 0.4 then
                -- UNCOMMON
                isBadFish = true
            end
        else
            warn("Skip Error, Please Rejoin")
        end

        if isBadFish then
            StopCast()
            task.wait(0.3)
            StartCast5X()
        else
            _G.startSpam()
            task.wait()
            _G.RecastSpam()
        end
    else
        _G.startSpam()
        task.wait()
        _G.RecastSpam()
    end
end)


_G.REFishCaught.OnClientEvent:Connect(function(fishName, info)
    if FuncAutoFish.autofish5x then
        _G.lastFishTime = tick()
        _G.stopSpam()
        _G.StopFishing()
    end
end)

task.spawn(function()
	while task.wait(1) do
		if _G.AntiStuckEnabled and FuncAutoFish.autofish5x and not _G.AutoFishHighQuality then
			if tick() - _G.lastFishTime > tonumber(_G.STUCK_TIMEOUT) then
				StopAutoFish5X()
				task.wait(0.5)
				StartAutoFish5X()
				_G.lastFishTime = tick()
			end
		end
	end
end)

function StartCast5X()
    local getPowerFunction = Constants.GetPower
    local perfectThreshold = 0.99
    local chargeStartTime = workspace:GetServerTimeNow()
    rodRemote:InvokeServer(chargeStartTime)
    local calculationLoopStart = tick()
    local timeoutDuration = 0.01
    local lastPower = 0
    while (tick() - calculationLoopStart < timeoutDuration) do
        local currentPower = getPowerFunction(Constants, chargeStartTime)
        if currentPower < lastPower and lastPower >= perfectThreshold then
            break
        end

        lastPower = currentPower
        task.wait(0)
    end
    miniGameRemote:InvokeServer(-1.25, 1.0, workspace:GetServerTimeNow())
end

function StopCast()
    _G.StopFishing()
end


function StartAutoFish5X()
    FuncAutoFish.autofish5x = true
    _G.AntiStuckEnabled = true
    lastEventTime = tick()
    _G.lastFishTime = tick()
    _G.equipRemote:FireServer(1)
    task.wait(0.05)
    StartCast5X()
end

function StopAutoFish5X()
    FuncAutoFish.autofish5x = false
    _G.AntiStuckEnabled = false
    FuncAutoFish.delayInitialized = false
    _G.StopFishing()
    _G.isRecasting5x = false
    _G.stopSpam()
    _G.StopRecastSpam()
end


--[[

INI AUTO FISH LEGIT 

]]


_G.RunService = game:GetService("RunService")
_G.ReplicatedStorage = game:GetService("ReplicatedStorage")
_G.FishingControllerPath = _G.ReplicatedStorage.Controllers.FishingController
_G.FishingController = require(_G.FishingControllerPath)

_G.AutoFishingControllerPath = _G.ReplicatedStorage.Controllers.AutoFishingController
_G.AutoFishingController = require(_G.AutoFishingControllerPath)
_G.Replion = require(_G.ReplicatedStorage.Packages.Replion)

_G.AutoFishState = {
    IsActive = false,
    MinigameActive = false
}

_G.SPEED_LEGIT = 0.5

function _G.performClick()
    _G.FishingController:RequestFishingMinigameClick()
    task.wait(tonumber(_G.SPEED_LEGIT))
end

_G.originalAutoFishingStateChanged = _G.AutoFishingController.AutoFishingStateChanged
function _G.forceActiveVisual(arg1)
    _G.originalAutoFishingStateChanged(true)
end

_G.AutoFishingController.AutoFishingStateChanged = _G.forceActiveVisual

function _G.ensureServerAutoFishingOn()
    local replionData = _G.Replion.Client:WaitReplion("Data")
    local currentAutoFishingState = replionData:GetExpect("AutoFishing")

    if not currentAutoFishingState then
        local remoteFunctionName = "UpdateAutoFishingState"
        local Net = require(_G.ReplicatedStorage.Packages.Net)
        local UpdateAutoFishingRemote = Net:RemoteFunction(remoteFunctionName)

        local success, result = pcall(function()
            return UpdateAutoFishingRemote:InvokeServer(true)
        end)

        if success then
        else
        end
    else
    end
end

-- ===================================================================
-- BAGIAN 2: AUTO CLICK MINIGAME
-- ===================================================================

_G.originalRodStarted = _G.FishingController.FishingRodStarted
_G.originalFishingStopped = _G.FishingController.FishingStopped
_G.clickThread = nil

_G.FishingController.FishingRodStarted = function(self, arg1, arg2)
    _G.originalRodStarted(self, arg1, arg2)

    if _G.AutoFishState.IsActive and not _G.AutoFishState.MinigameActive then
        _G.AutoFishState.MinigameActive = true

        if _G.clickThread then
            task.cancel(_G.clickThread)
        end

        _G.clickThread = task.spawn(function()
            while _G.AutoFishState.IsActive and _G.AutoFishState.MinigameActive do
                _G.performClick()
            end
        end)
    end
end

_G.FishingController.FishingStopped = function(self, arg1)
    _G.originalFishingStopped(self, arg1)

    if _G.AutoFishState.MinigameActive then
        _G.AutoFishState.MinigameActive = false
        task.wait(1)
        _G.ensureServerAutoFishingOn()
    end
end

function _G.ToggleAutoClick(shouldActivate)
    _G.AutoFishState.IsActive = shouldActivate

    if shouldActivate then
        _G.ensureServerAutoFishingOn()
    else
        if _G.clickThread then
            task.cancel(_G.clickThread)
            _G.clickThread = nil
        end
        _G.AutoFishState.MinigameActive = false
    end
end

_G.FishAdvenc = AutoFish:Section({
    Title = "Adcenced Settings",
    TextSize = 22,
    TextXAlignment = "Center",
    Opened = false
})

_G.FishSec = AutoFish:Section({
    Title = "Auto Fishing Menu",
    TextSize = 22,
    TextXAlignment = "Center",
    Opened = true
})

_G.FishAdvenc:Input({
    Title = "Delay Finish",
    Desc = [[
High Rod = 1
Medium Rod = 1.5 - 1.7
Low Rod = 2 - 3
]],
    Value = _G.FINISH_DELAY,
    Type = "Input",
    Placeholder = "Input Delay Finish..",
    Callback = function(input)
        fDelays = tonumber(input)
        if not fDelays then
            NotifyWarning("Please Input Valid Number")
        end
        _G.FINISH_DELAY = fDelays
    end
})

_G.FishAdvenc:Input({
    Title = "Speed Legit",
    Desc = "Speed Click for Auto Fish Legit",
    Value = _G.SPEED_LEGIT,
    Type = "Input",
    Placeholder = "Input Speed..",
    Callback = function(input)
        DelayLegit = tonumber(input)
        if not DelayLegit then
            NotifyWarning("Please Input Valid Number")
        end
        _G.SPEED_LEGIT = DelayLegit
    end
})

_G.FishAdvenc:Input({
    Title = "Sell Threesold",
    Value = _G.sellThreshold,
    Type = "Input",
    Placeholder = "Input Delay Finish..",
    Callback = function(input)
        thresold = tonumber(input)
        if not thresold then
            NotifyWarning("Please Input Valid Number")
        end
        _G.sellThreshold = thresold
    end
})

_G.FishAdvenc:Input({
    Title = "Anti Stuck Delay",
    Desc = "Cooldown for anti stuck Auto Fish",
    Value = _G.STUCK_TIMEOUT,
    Type = "Input",
    Placeholder = "Input Delay Finish..",
    Callback = function(input)
        stuck = tonumber(input)
        if not stuck then
            NotifyWarning("Please Input Valid Number")
        end
        _G.STUCK_TIMEOUT = stuck
    end
})

_G.FishSec:Toggle({
    Title = "Auto Sell",
    Value = false,
    Callback = function(state)
        _G.sellActive = state
        if state then
            NotifySuccess("Auto Sell", "Limit: " .. _G.sellThreshold)
        else
            NotifySuccess("Auto Sell", "Disabled")
        end
    end
})

_G.AutoFishes = _G.FishSec:Toggle({
    Title = "Auto Fish",
    Callback = function(value)
        if value then
            StartAutoFish5X()
        else
            StopAutoFish5X()
        end
    end
})

_G.FishSec:Toggle({
    Title = "Fish High Quality",
    Desc = "Skip Common, Uncommon, & Rare",
    Value = _G.AutoFishHighQuality,
    Callback = function(state)
        _G.AutoFishHighQuality = state
    end
})

_G.FishSec:Toggle({
    Title = "Auto Fish Legit",
    Value = false,
    Callback = function(state)
        _G.equipRemote:FireServer(1)
        _G.ToggleAutoClick(state)

        local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local fishingGui = playerGui:WaitForChild("Fishing"):WaitForChild("Main")
        local chargeGui = playerGui:WaitForChild("Charge"):WaitForChild("Main")

        if state then
            fishingGui.Visible = false
            chargeGui.Visible = false
        else
            fishingGui.Visible = true
            chargeGui.Visible = true
        end
    end
})


_G.FishSec:Space()


_G.FishSec:Button({
    Title = "Stop Fishing",
    Locked = false,
    Justify = "Center",
    Icon = "",
    Callback = function()
        _G.StopFishing()
        RodIdle:Stop()
        RodIdle:Stop()
        _G.stopSpam()
        _G.StopRecastSpam()
    end
})

_G.FishSec:Space()


-- =======================================================
-- == AUTO CUTSCENE REMOVER (TOGGLE + HOOK)
-- =======================================================

_G.CutsceneController = require(ReplicatedStorage.Controllers.CutsceneController)
_G.GuiControl = require(ReplicatedStorage.Modules.GuiControl)
_G.ProximityPromptService = game:GetService("ProximityPromptService")

_G.AutoSkipCutscene = true

if not _G.OriginalPlayCutscene then
    _G.OriginalPlayCutscene = _G.CutsceneController.Play
end

_G.CutsceneController.Play = function(self, ...)
    if _G.AutoSkipCutscene then
        task.spawn(function()
            task.wait()
            if _G.GuiControl then 
                _G.GuiControl:SetHUDVisibility(true) 
            end
            _G.ProximityPromptService.Enabled = true
            LocalPlayer:SetAttribute("IgnoreFOV", false)
        end)

        return
    end

    return _G.OriginalPlayCutscene(self, ...)
end

_G.FishAdvenc:Toggle({
    Title = "Auto Skip Cutscenes",
    Value = true,
    Callback = function(state)
        _G.AutoSkipCutscene = state

        if state then
            if _G.CutsceneController then
                _G.CutsceneController:Stop()
                _G.GuiControl:SetHUDVisibility(true)
                _G.ProximityPromptService.Enabled = true
            end
            NotifySuccess("Cutscene", "Auto Skip Enabled. No more animations.")
        else
            NotifyInfo("Cutscene", "Auto Skip Disabled.")
        end
    end
})



_G.FishAdvenc:Input({
    Title = "Max Inventory Size",
    Value = tostring(Constants.MaxInventorySize or 0),
    Placeholder = "Input Number...",
    Callback = function(input)
        local newSize = tonumber(input)
        if not newSize then
            NotifyWarning("Inventory Size", "Must be numbers!")
            return
        end
        Constants.MaxInventorySize = newSize
    end
})

local REEquipItem = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/EquipItem"]
local RFSellItem = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/SellItem"]

local autoSellMythic = false
local SMBlockNotif = true

function ToggleAutoSellMythic(state)
	if SMBlockNotif then
		SMBlockNotif = false
		return
	end
	autoSellMythic = state
	if autoSellMythic then
		NotifySuccess("AutoSellMythic", "Status: ON")
	else
		NotifyWarning("AutoSellMythic", "Status: OFF")
	end
end

local oldFireServer
oldFireServer = hookmetamethod(game, "__namecall", function(self, ...)
	local args = {...}
	local method = getnamecallmethod()

	if autoSellMythic
		and method == "FireServer"
		and self == REEquipItem
		and typeof(args[1]) == "string"
		and args[2] == "Fishes" then

		local uuid = args[1]

		task.delay(1, function()
			pcall(function()
				local result = RFSellItem:InvokeServer(uuid)
				if result then
					NotifySuccess("AutoSellMythic", "Items Sold!!")
				else
					NotifyError("AutoSellMythic", "Failed to sell item!!")
				end
			end)
		end)
	end

	return oldFireServer(self, ...)
end)

AutoFish:Toggle({
	Title = "Auto Sell Mythic",
	Desc = "Automatically sells clicked fish",
	Default = false,
	Callback = function(state)
		ToggleAutoSellMythic(state)
	end
})


function sellAllFishes()
	local charFolder = workspace:FindFirstChild("Characters")
	local char = charFolder and charFolder:FindFirstChild(LocalPlayer.Name)
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		NotifyError("Character Not Found", "HRP tidak ditemukan.")
		return
	end

	local originalPos = hrp.CFrame
	local sellRemote = net:WaitForChild("RF/SellAllItems")

	task.spawn(function()
		NotifyInfo("Selling...", "I'm going to sell all the fish, please wait...", 3)

		task.wait(1)
		local success, err = pcall(function()
			sellRemote:InvokeServer()
		end)

		if success then
			NotifySuccess("Sold!", "All the fish were sold successfully.", 3)
		else
			NotifyError("Sell Failed", tostring(err, 3))
		end

	end)
end

AutoFish:Button({
    Title = "Sell All Fishes",
    Locked = false,
    Callback = function()
        sellAllFishes()
    end
})

AutoFish:Button({
    Title = "Auto Enchant Rod",
    Callback = function()
        local ENCHANT_POSITION = Vector3.new(3231, -1303, 1402)
		local char = workspace:WaitForChild("Characters"):FindFirstChild(LocalPlayer.Name)
		local hrp = char and char:FindFirstChild("HumanoidRootPart")

		if not hrp then
			NotifyError("Auto Enchant Rod", "Failed to get character HRP.")
			return
		end

		NotifyInfo("Preparing Enchant...", "Please manually place Enchant Stone into slot 5 before we begin...", 5)

		task.wait(3)

		local Player = game:GetService("Players").LocalPlayer
		local slot5 = Player.PlayerGui.Backpack.Display:GetChildren()[10]

		local itemName = slot5 and slot5:FindFirstChild("Inner") and slot5.Inner:FindFirstChild("Tags") and slot5.Inner.Tags:FindFirstChild("ItemName")

		if not itemName or not itemName.Text:lower():find("enchant") then
			NotifyError("Auto Enchant Rod", "Slot 5 does not contain an Enchant Stone.")
			return
		end

		NotifyInfo("Enchanting...", "It is in the process of Enchanting, please wait until the Enchantment is complete", 7)

		local originalPosition = hrp.Position
		task.wait(1)
		hrp.CFrame = CFrame.new(ENCHANT_POSITION + Vector3.new(0, 5, 0))
		task.wait(1.2)

		local equipRod = net:WaitForChild("RE/EquipToolFromHotbar")
		local activateEnchant = net:WaitForChild("RE/ActivateEnchantingAltar")

		pcall(function()
			equipRod:FireServer(5)
			task.wait(0.5)
			activateEnchant:FireServer()
			task.wait(7)
			NotifySuccess("Enchant", "Successfully Enchanted!", 3)
		end)

		task.wait(0.9)
		hrp.CFrame = CFrame.new(originalPosition + Vector3.new(0, 3, 0))
    end
})

-------------------------------------------
----- =======[ AUTO FAV TAB ]
-------------------------------------------


local GlobalFav = {
    REObtainedNewFishNotification = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"],
    REFavoriteItem = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/FavoriteItem"],

    FishIdToName = {},
    FishNameToId = {},
    FishNames = {},
    FishRarity = {},
    Variants = {},
    SelectedFishIds = {},
    SelectedVariants = {},
    SelectedRarities = {},
    AutoFavoriteEnabled = false
}

local TierToRarityName = {
    [3] = "RARE",
    [4] = "EPIC",
    [5] = "LEGENDARY",
    [6] = "MYTHIC",
    [7] = "SECRET"
}

for _, item in ipairs(ReplicatedStorage.Items:GetChildren()) do
    local ok, data = pcall(require, item)
    if ok and data.Data and data.Data.Type == "Fish" then
        local id = data.Data.Id
        local name = data.Data.Name
        local tier = data.Data.Tier or 1

        local nameWithId = name .. " [ID:" .. id .. "]"

        GlobalFav.FishIdToName[id] = nameWithId
        GlobalFav.FishNameToId[nameWithId] = id
        GlobalFav.FishRarity[id] = tier

        table.insert(GlobalFav.FishNames, nameWithId)
    end
end

-- Load Variants
for _, variantModule in pairs(ReplicatedStorage.Variants:GetChildren()) do
    local ok, variantData = pcall(require, variantModule)
    if ok and variantData.Data.Name then
        local name = variantData.Data.Name
        GlobalFav.Variants[name] = name
    end
end

AutoFav:Section({
    Title = "Auto Favorite Menu",
    TextSize = 22,
    TextXAlignment = "Center",
})

AutoFav:Toggle({
    Title = "Enable Auto Favorite",
    Value = false,
    Callback = function(state)
        GlobalFav.AutoFavoriteEnabled = state
        if state then
            NotifySuccess("Auto Favorite", "Auto Favorite feature enabled")
        else
            NotifyWarning("Auto Favorite", "Auto Favorite feature disabled")
        end
    end
})

local fishName = GlobalFav.FishIdToName[itemId]

_G.FishList = AutoFav:Dropdown({
    Title = "Auto Favorite Fishes",
    Values = GlobalFav.FishNames,
    Value = {},
    Multi = true,
    AllowNone = true,
    SearchBarEnabled = true,
    Callback = function(selectedNames)
        GlobalFav.SelectedFishIds = {}

        for _, nameWithId in ipairs(selectedNames) do
            local id = GlobalFav.FishNameToId[nameWithId]
            if id then
                GlobalFav.SelectedFishIds[id] = true
            end
        end

        NotifyInfo("Auto Favorite", "Favoriting fish: " .. HttpService:JSONEncode(selectedNames))
    end
})


AutoFav:Dropdown({
    Title = "Auto Favorite Variants",
    Values = GlobalFav.Variants,
    Multi = true,
    AllowNone = true,
    SearchBarEnabled = true,
    Callback = function(selectedVariants)
        GlobalFav.SelectedVariants = {}
        for _, vName in ipairs(selectedVariants) do
            for vId, name in pairs(GlobalFav.Variants) do
                if name == vName then
                    GlobalFav.SelectedVariants[vId] = true
                end
            end
        end
        NotifyInfo("Auto Favorite", "Favoriting active for variants: " .. HttpService:JSONEncode(selectedVariants))
    end
})

-- Rarity dropdown
local rarityList = {}
for tier, name in pairs(TierToRarityName) do
    table.insert(rarityList, name)
end

AutoFav:Dropdown({
    Title = "Auto Favorite by Rarity",
    Values = rarityList,
    Multi = true,
    AllowNone = true,
    SearchBarEnabled = true,
    Callback = function(selectedRarities)
        GlobalFav.SelectedRarities = {}
        for _, rarityName in ipairs(selectedRarities) do
            for tier, name in pairs(TierToRarityName) do
                if name == rarityName then
                    GlobalFav.SelectedRarities[tier] = true
                end
            end
        end
        NotifyInfo("Auto Favorite", "Favoriting active for rarities: " .. HttpService:JSONEncode(selectedRarities))
    end
})

GlobalFav.REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, _, data)
    if not GlobalFav.AutoFavoriteEnabled then return end

    local uuid = data.InventoryItem and data.InventoryItem.UUID
    if not uuid then return end

    local fishName = GlobalFav.FishIdToName[itemId] or "Unknown"
    local variantId = data.InventoryItem.Metadata and data.InventoryItem.Metadata.VariantId
    local tier = GlobalFav.FishRarity[itemId] or 1
    local rarityName = TierToRarityName[tier] or "Unknown"

    local isFishSelected = GlobalFav.SelectedFishIds[itemId]
    local isVariantSelected = variantId and GlobalFav.SelectedVariants[variantId]
    local isRaritySelected = GlobalFav.SelectedRarities[tier]

    local shouldFavorite = false
    if (isFishSelected or not next(GlobalFav.SelectedFishIds))
       and (isVariantSelected or not next(GlobalFav.SelectedVariants))
       and (isRaritySelected or not next(GlobalFav.SelectedRarities)) then
        shouldFavorite = true
    end

    if shouldFavorite then
        GlobalFav.REFavoriteItem:FireServer(uuid)

        local msg = "Favorited " .. fishName

        if isVariantSelected then
            msg = msg .. " (" .. (GlobalFav.Variants[variantId] or variantId) .. " Variant)"
        end

        if isRaritySelected then
            msg = msg .. " (" .. rarityName .. ")"
        end

        NotifySuccess("Auto Favorite", msg .. "!")
    end
end)


-------------------------------------------
----- =======[ AUTO FARM TAB ]
-------------------------------------------


local floatPlatform = nil

local function floatingPlat(enabled)
	if enabled then
			local charFolder = workspace:WaitForChild("Characters", 5)
			local char = charFolder:FindFirstChild(LocalPlayer.Name)
			if not char then return end

			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then return end

			floatPlatform = Instance.new("Part")
			floatPlatform.Anchored = true
			floatPlatform.Size = Vector3.new(10, 1, 10)
			floatPlatform.Transparency = 1
			floatPlatform.CanCollide = true
			floatPlatform.Name = "FloatPlatform"
			floatPlatform.Parent = workspace

			task.spawn(function()
				while floatPlatform and floatPlatform.Parent do
					pcall(function()
						floatPlatform.Position = hrp.Position - Vector3.new(0, 3.5, 0)
					end)
					task.wait(0.1)
				end
			end)

			NotifySuccess("Float Enabled", "This feature has been successfully activated!")
		else
			if floatPlatform then
				floatPlatform:Destroy()
				floatPlatform = nil
			end
			NotifyWarning("Float Disabled", "Feature disabled")
		end
end

  
  
local workspace = game:GetService("Workspace")

local BlockEnabled = false

local function createLocalBlock(size, position, color)
    local part = Instance.new("Part")
    part.Size = size or Vector3.new(5, 1, 5)
    part.Position = position or
    (LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, -3, 0)) or
    Vector3.new(0, 5, 0)
    part.Anchored = true
    part.CanCollide = true
    part.Color = color or Color3.fromRGB(0, 0, 255)
    part.Material = Enum.Material.ForceField
    part.Name = "LocalBlock"
    part.Parent = workspace
    return part
end


local function createBlockUnderPlayer()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        if workspace:FindFirstChild("LocalBlock") then
            workspace.LocalBlock:Destroy()
        end
        createLocalBlock(Vector3.new(6, 1, 6), hrp.Position - Vector3.new(0, 3, 0), Color3.fromRGB(0, 0, 255))
    end
end


local function ToggleBlockOnce(state)
    BlockEnabled = state
    if state then
        createBlockUnderPlayer()
    else
        if workspace:FindFirstChild("LocalBlock") then
            workspace.LocalBlock:Destroy()
        end
    end
end

local function getPartRecursive(o)
    if o:IsA("BasePart") then return o end
    for _, c in ipairs(o:GetChildren()) do
        local p = getPartRecursive(c)
        if p then return p end
    end
    return nil
end

local eventMap = {
    ["Shark Hunt"]       = { name = "Shark Hunt", part = nil },
    ["Ghost Shark Hunt"] = { name = "Ghost Shark Hunt", part = "Part" },
    ["Worm Hunt"]        = { name = "Model", part = "Part" },
    ["Black Hole"]       = { name = "BlackHole", part = nil },
    ["Meteor Rain"]      = { name = "MeteorRain", part = nil },
    ["Ghost Worm"]       = { name = "Model", part = "Part" },
    ["Shocked"]          = { name = "Shocked", part = nil },
    ["Megalodon Hunt"]   = { name = "Megalodon Hunt", part = "Color" },
}

local eventNames = {}
for _, data in pairs(eventMap) do
    if data.name ~= "Model" then
        table.insert(eventNames, data.name)
    end
end
table.insert(eventNames, "Worm Hunt")
table.insert(eventNames, "Ghost Worm")

local autoTPEvent = false
local savedCFrame = nil
local alreadyTeleported = false
local teleportTime = nil
local selectedEvent = nil
local wasAutoFishing = false

local function teleportTo(position)
    _G.isTeleporting = true
    local char = workspace:FindFirstChild("Characters"):FindFirstChild(LocalPlayer.Name)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if hrp then
        local wasLocked = hrp.Anchored -- Jika fitur Lock Position aktif
        if wasLocked then hrp.Anchored = false end
        task.wait(0.1)

        -- Teleport
        hrp.CFrame = CFrame.new(position + Vector3.new(0, 15, 0))
        ToggleBlockOnce(true)

        task.wait(0.5)
        if wasLocked then hrp.Anchored = true end
    end
    _G.isTeleporting = false
end

local function saveOriginalPosition()
    local char = workspace:FindFirstChild("Characters"):FindFirstChild(LocalPlayer.Name)
    if char and char:FindFirstChild("HumanoidRootPart") then
        savedCFrame = char.HumanoidRootPart.CFrame
    end
end

local function returnToOriginalPosition()
    if savedCFrame then
        local char = workspace:FindFirstChild("Characters"):FindFirstChild(LocalPlayer.Name)
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = savedCFrame
        end
    end
end

local function findEventPart(eventName)
    local menuRings = workspace:FindFirstChild("!!! MENU RINGS")
    if not menuRings then return nil end

    local props = menuRings:FindFirstChild("Props")
    if not props then return nil end

    local targetEventData = eventMap[eventName]
    if not targetEventData then return nil end

    local eventModel = props:FindFirstChild(targetEventData.name)
    if not eventModel or not eventModel:IsA("Model") then return nil end

    local targetPart = nil

    if eventName == "Megalodon Hunt" then
        targetPart = eventModel:FindFirstChild("Color")
    elseif eventName == "Ghost Shark Hunt" then
        targetPart = eventModel:FindFirstChild("Part")
    elseif eventName == "Worm Hunt" or eventName == "Ghost Worm" then
        targetPart = eventModel:FindFirstChild("Part")
    elseif eventModel.PrimaryPart and eventModel.PrimaryPart:IsA("BasePart") then
        targetPart = eventModel.PrimaryPart
    else

        targetPart = getPartRecursive(eventModel)
    end

    if targetPart and targetPart:IsA("BasePart") then
        return targetPart
    end

    return nil
end

local function monitorAutoTP()
    while task.wait(3) do -- Cek setiap 3 detik
        -- Periksa kondisi utama untuk menjalankan logika TP
        if autoTPEvent and selectedEvent then
            local char = workspace:FindFirstChild("Characters"):FindFirstChild(LocalPlayer.Name)

            if char then
                local eventPart = findEventPart(selectedEvent)

                if eventPart and not alreadyTeleported then
                    -- === [ EVENT TERDETEKSI & BELUM TELEPORT ] ===
                    saveOriginalPosition()
                    wasAutoFishing = FuncAutoFish.autofish5x 

                    if wasAutoFishing then
                        _G.StopAutoFish5X() 
                        task.wait(0.5)
                    end

                    teleportTo(eventPart.Position)
                    alreadyTeleported = true
                    teleportTime = tick()

                    -- Mulai AutoFish setelah TP
                    if wasAutoFishing then
                        _G.StartAutoFish5X()
                    end

                    NotifySuccess("Event Farm", ("Teleported to %s. Farming started."):format(selectedEvent))
                elseif alreadyTeleported then
                    -- === [ SUDAH DI LOKASI EVENT ] ===

                    -- Cek Event Hilang atau Timeout 15 menit
                    local isTimeout = teleportTime and (tick() - teleportTime >= 900)

                    if isTimeout or not eventPart then
                        -- Hentikan AutoFish
                        if wasAutoFishing then _G.StopAutoFish5X() end

                        returnToOriginalPosition()

                        NotifyInfo("Event Ended", ("Returned to start position. Reason: %s"):format(
                            isTimeout and "Timeout 15m" or "Event Ended"
                        ))

                        -- Reset State
                        alreadyTeleported = false
                        teleportTime = nil

                        -- Lanjutkan AutoFish jika sebelumnya aktif
                        if wasAutoFishing then
                            task.wait(1)
                            _G.StartAutoFish5X()
                        end
                    end
                end
            end
        else
            -- === [ AUTO TP OFF ] ===
            if alreadyTeleported then
                if wasAutoFishing then _G.StopAutoFish5X() end
                returnToOriginalPosition()
                alreadyTeleported = false
                teleportTime = nil
                NotifyWarning("Auto TP Event", "Fitur dimatikan. Kembali ke posisi awal.")
            end
        end
    end
end

if _G.monitorTPThread then task.cancel(_G.monitorTPThread) end
_G.monitorTPThread = task.spawn(monitorAutoTP)

local selectedIsland = "09"
local isAutoFarmRunning = false

local islandCodes = {
    ["01"] = "Crater Islands",
    ["02"] = "Tropical Grove",
    ["03"] = "Vulcano",
    ["04"] = "Coral Reefs",
    ["05"] = "Winter",
    ["06"] = "Machine",
    ["07"] = "Treasure Room",
    ["08"] = "Sisyphus Statue",
    ["09"] = "Fisherman Island",
    ["10"] = "Esoteric Depths",
    ["11"] = "Kohana",
    ["12"] = "Underground Cellar",
    ["13"] = "Ancient Jungle",
    ["14"] = "Secret Farm Ancient",
    ["15"] = "The Temple (Unlock First)",
    ["16"] = "Ancient Ruin",
    ["17"] = "Iron Cavern",
    ["18"] = "The Iron Cafe"
}

local farmLocations = {
    ["Crater Islands"] = {
    	CFrame.new(1066.1864, 57.2025681, 5045.5542, -0.682534158, 1.00865822e-08, 0.730853677, -5.8900711e-09, 1, -1.93017531e-08, -0.730853677, -1.74788859e-08, -0.682534158),
    	CFrame.new(1057.28992, 33.0884132, 5133.79883, 0.833871782, 5.44149223e-08, 0.551958203, -6.58184218e-09, 1, -8.86416984e-08, -0.551958203, 7.02829084e-08, 0.833871782),
    	CFrame.new(988.954712, 42.8254471, 5088.71289, -0.849417388, -9.89310394e-08, 0.527721584, -5.96115086e-08, 1, 9.15179328e-08, -0.527721584, 4.62786431e-08, -0.849417388),
    	CFrame.new(1006.70685, 17.2302666, 5092.14844, -0.989664078, 5.6538525e-09, -0.143405005, 9.14879283e-09, 1, -2.3711717e-08, 0.143405005, -2.47786183e-08, -0.989664078),
    	CFrame.new(1025.02356, 2.77259707, 5011.47021, -0.974474192, -6.87871804e-08, 0.224499553, -4.47472104e-08, 1, 1.12170284e-07, -0.224499553, 9.92613209e-08, -0.974474192),
    	CFrame.new(1071.14551, 3.528404, 5038.00293, -0.532300115, 3.38677708e-08, 0.84655571, 6.69992914e-08, 1, 2.12149165e-09, -0.84655571, 5.7847906e-08, -0.532300115),
    	CFrame.new(1022.55457, 16.6277809, 5066.28223, 0.721996129, 0, -0.691897094, 0, 1, 0, 0.691897094, 0, 0.721996129),
    },
    ["Tropical Grove"] = {
    	CFrame.new(-2165.05469, 2.77070165, 3639.87451, -0.589090407, -3.61497356e-08, -0.808067143, -3.20645626e-08, 1, -2.13606164e-08, 0.808067143, 1.3326984e-08, -0.589090407)
    },
    ["Vulcano"] = {
    	CFrame.new(-701.447937, 48.1446075, 93.1546631, -0.0770962164, 1.34335654e-08, -0.997023642, 9.84464776e-09, 1, 1.27124169e-08, 0.997023642, -8.83526763e-09, -0.0770962164),
    	CFrame.new(-654.994934, 57.2567711, 75.098526, -0.540957272, 2.58946509e-09, -0.841050088, -7.58775585e-08, 1, 5.18827363e-08, 0.841050088, 9.1883166e-08, -0.540957272),
    },
    ["Coral Reefs"] = {
    	CFrame.new(-3118.39624, 2.42531538, 2135.26392, 0.92336154, -1.0069185e-07, -0.383931547, 8.0607947e-08, 1, -6.84016968e-08, 0.383931547, 3.22115596e-08, 0.92336154),
    },
    ["Winter"] = {
    	CFrame.new(2036.15308, 6.54998732, 3381.88916, 0.943401575, 4.71338666e-08, -0.331652641, -3.28136842e-08, 1, 4.87781051e-08, 0.331652641, -3.51345975e-08, 0.943401575),
    },
    ["Machine"] = {
    	CFrame.new(-1459.3772, 14.7103214, 1831.5188, 0.777951121, 2.52131862e-08, -0.628324807, -5.24126378e-08, 1, -2.47663063e-08, 0.628324807, 5.21991339e-08, 0.777951121)
    },
    ["Treasure Room"] = {
    	CFrame.new(-3625.0708, -279.074219, -1594.57605, 0.918176472, -3.97606392e-09, -0.396171629, -1.12946204e-08, 1, -3.62128851e-08, 0.396171629, 3.77244298e-08, 0.918176472),
    	CFrame.new(-3600.72632, -276.06427, -1640.79663, -0.696130812, -6.0491181e-09, 0.717914939, -1.09490363e-08, 1, -2.19084972e-09, -0.717914939, -9.38559541e-09, -0.696130812),
    	CFrame.new(-3548.52222, -269.309845, -1659.26685, 0.0472991578, -4.08685423e-08, 0.998880744, -7.68598838e-08, 1, 4.45538149e-08, -0.998880744, -7.88812216e-08, 0.0472991578),
    	CFrame.new(-3581.84155, -279.09021, -1696.15637, -0.999634147, -0.000535600528, -0.0270430837, -0.000448358158, 0.999994695, -0.00323198596, 0.0270446707, -0.00321867829, -0.99962908),
    	CFrame.new(-3601.34302, -282.790955, -1629.37036, -0.526346684, 0.00143659476, 0.850268841, -0.000266355521, 0.999998271, -0.00185445137, -0.850269973, -0.00120255165, -0.526345372)
    },
    ["Sisyphus Statue"] = {
    	CFrame.new(-3777.43433, -135.074417, -975.198975, -0.284491211, -1.02338751e-08, -0.958678663, 6.38407585e-08, 1, -2.96199456e-08, 0.958678663, -6.96293867e-08, -0.284491211),
    	CFrame.new(-3697.77124, -135.074417, -886.946411, 0.979794085, -9.24526766e-09, 0.200008959, 1.35701708e-08, 1, -2.02526174e-08, -0.200008959, 2.25575487e-08, 0.979794085),
    	CFrame.new(-3764.021, -135.074417, -903.742493, 0.785813689, -3.05788426e-08, -0.618463278, -4.87374336e-08, 1, -1.11368585e-07, 0.618463278, 1.17657272e-07, 0.785813689)
    },
    ["Fisherman Island"] = {
    	CFrame.new(-75.2439423, 3.24433279, 3103.45093, -0.996514142, -3.14880424e-08, -0.0834242329, -3.84156422e-08, 1, 8.14354024e-08, 0.0834242329, 8.43563228e-08, -0.996514142),
    	CFrame.new(-162.285294, 3.26205397, 2954.47412, -0.74356699, -1.93168272e-08, -0.668661416, 1.03873425e-08, 1, -4.04397653e-08, 0.668661416, -3.70152904e-08, -0.74356699),
    	CFrame.new(-69.8645096, 3.2620542, 2866.48096, 0.342575252, 8.79649331e-09, 0.939490378, 4.78986739e-10, 1, -9.53770485e-09, -0.939490378, 3.71738529e-09, 0.342575252),
    	CFrame.new(247.130951, 2.47001815, 3001.72412, -0.724809051, -8.27166033e-08, -0.688949764, -8.16509669e-08, 1, -3.41610367e-08, 0.688949764, 3.14931867e-08, -0.724809051)
    },
    ["Esoteric Depths"] = {
    	CFrame.new(3253.26099, -1293.7677, 1435.24756, 0.21652025, -3.88184027e-08, -0.976278126, 1.20091812e-08, 1, -3.70982107e-08, 0.976278126, -3.69178754e-09, 0.21652025),
    	CFrame.new(3299.66333, -1302.85474, 1370.98621, -0.440755099, -5.91509552e-09, 0.897627413, -2.5926683e-09, 1, 5.31664224e-09, -0.897627413, 1.60869356e-11, -0.440755099),
    	CFrame.new(3250.94531, -1302.85547, 1324.77942, -0.998184919, 5.84032058e-08, 0.0602233484, 5.50187451e-08, 1, -5.78567096e-08, -0.0602233484, -5.44382814e-08, -0.998184919),
    	CFrame.new(3219.16309, -1294.03394, 1364.41492, 0.676777482, -4.18104094e-08, -0.736187637, 8.28715798e-08, 1, 1.93907237e-08, 0.736187637, -7.41322381e-08, 0.676777482)
    },
    ["Kohana"] = {
    	CFrame.new(-921.516602, 24.5000591, 373.572754, -0.315036476, -3.65496575e-08, -0.949079573, -2.09816324e-08, 1, -3.15460156e-08, 0.949079573, 9.97509186e-09, -0.315036476),
    	CFrame.new(-821.466125, 18.0640106, 442.570953, 0.502961993, 3.55151641e-08, 0.864308536, -2.61714685e-08, 1, -2.58610324e-08, -0.864308536, -9.61310764e-09, 0.502961993),
    	CFrame.new(-656.069275, 17.2500572, 450.77124, 0.899714053, -3.28262595e-09, -0.436479777, -5.17725418e-09, 1, -1.81925373e-08, 0.436479777, 1.86278477e-08, 0.899714053),
    	CFrame.new(-584.202759, 17.2500572, 459.276672, 0.0987685546, 5.48308599e-09, 0.995110452, -6.92575881e-08, 1, 1.36405531e-09, -0.995110452, -6.90536694e-08, 0.0987685546),
    },
    ["Underground Cellar"] = {
    	CFrame.new(2159.65723, -91.198143, -730.99707, -0.392579645, -1.64555736e-09, 0.919718027, 4.08579943e-08, 1, 1.92293435e-08, -0.919718027, 4.51268818e-08, -0.392579645),
    	CFrame.new(2114.22144, -91.1976471, -732.656738, -0.543168366, -3.4070105e-08, -0.839623809, 2.10003783e-08, 1, -5.41633582e-08, 0.839623809, -4.70522394e-08, -0.543168366),
    	CFrame.new(2134.35767, -91.1985855, -698.182983, 0.989448071, -1.28799131e-08, -0.144888103, 2.66212989e-08, 1, 9.29025887e-08, 0.144888103, -9.57793915e-08, 0.989448071),
    },
    ["Ancient Jungle"] = {
    	CFrame.new(1515.67676, 25.5616989, -306.595856, 0.763029754, -8.87780942e-08, 0.646363378, 5.24343307e-08, 1, 7.5451581e-08, -0.646363378, -2.36801707e-08, 0.763029754),
    	CFrame.new(1489.29553, 6.23855162, -342.620209, -0.831362545, 6.32348289e-08, -0.555730462, 7.59748353e-09, 1, 1.02421176e-07, 0.555730462, 8.09269736e-08, -0.831362545),
    	CFrame.new(1467.59143, 7.2090292, -324.716827, -0.086521171, 2.06461745e-08, -0.996250033, -4.92800183e-08, 1, 2.50037022e-08, 0.996250033, 5.12585707e-08, -0.086521171),
    },
    ["Secret Farm Ancient"] = {
    	CFrame.new(2110.91431, -58.1463356, -732.848816, 0.0894816518, -9.7328666e-08, -0.995988488, 5.18647809e-08, 1, -9.30610398e-08, 0.995988488, -4.3329468e-08, 0.0894816518)
    },
    ["The Temple (Unlock First)"] = {
    	CFrame.new(1479.11865, -22.1250019, -662.669373, 0.161120579, -2.03902815e-08, -0.986934721, -3.03227985e-08, 1, -2.56105164e-08, 0.986934721, 3.40530022e-08, 0.161120579),
    	CFrame.new(1465.41211, -22.1250019, -670.940002, -0.21706377, -2.10148947e-08, 0.976157427, 3.29077707e-08, 1, 2.88457365e-08, -0.976157427, 3.83845311e-08, -0.21706377),
    	CFrame.new(1496.21802, -32.1248207, -718.443481, 0.6035254, -8.12091461e-09, 0.797343791, -4.36373142e-08, 1, 4.32149143e-08, -0.797343791, -6.08752373e-08, 0.6035254),
    	CFrame.new(1470.30334, -12.2246475, -587.052612, -0.101084575, -9.68974163e-08, 0.994877815, -1.47451953e-08, 1, 9.5898109e-08, -0.994877815, -4.97584818e-09, -0.101084575),
    	CFrame.new(1451.19983, -22.1250019, -621.852478, -0.986927867, 8.68970318e-09, -0.161162451, 9.61592317e-09, 1, -4.96716179e-09, 0.161162451, -6.4519563e-09, -0.986927867),
    	CFrame.new(1499.44788, -22.1250019, -628.441711, -0.985374331, 7.20484294e-08, -0.170403719, 8.45688035e-08, 1, -6.62162876e-08, 0.170403719, -7.9658669e-08, -0.985374331)
    },
    ["Ancient Ruin"] = {
    	CFrame.new(6096.86865, -585.924683, 4667.34521, -0.0791911632, 5.17708685e-08, 0.996859431, -4.35256062e-08, 1, -5.53916735e-08, -0.996859431, -4.77754405e-08, -0.0791911632),
    	CFrame.new(6022.87109, -585.924194, 4631.0127, -0.669677734, -6.96009084e-10, -0.74265182, -5.20333909e-09, 1, 3.75485687e-09, 0.74265182, 6.37881348e-09, -0.669677734),
    	CFrame.new(6020.40186, -555.693909, 4513.84229, -0.0245459341, -2.1426688e-08, -0.999698699, -1.28175666e-08, 1, -2.11184314e-08, 0.999698699, 1.22953328e-08, -0.0245459341),
    	CFrame.new(6057.14893, -557.975098, 4485.46631, -0.985172093, -3.35700534e-08, -0.171569183, -3.98707982e-08, 1, 3.32783721e-08, 0.171569183, 3.9625526e-08, -0.985172093)
    },
    ["Iron Cavern"] = {
        CFrame.new(-8797.98438, -585.000061, 81.8659973, 0.621304512, 7.69412338e-08, -0.783569217, -8.01423212e-08, 1, 3.4647158e-08, 0.783569217, 4.12706207e-08, 0.621304512),
        CFrame.new(-8788.70508, -585.000061, 96.8170547, 0.814901888, 2.71509681e-09, -0.579598963, -5.01786808e-08, 1, -6.58655495e-08, 0.579598963, 8.27574738e-08, 0.814901888),
        CFrame.new(-8754.25977, -580.000061, 267.518188, 0.866729259, -4.04597955e-08, 0.498778909, 1.90199643e-08, 1, 4.806666e-08, -0.498778909, -3.21740252e-08, 0.866729259)
    },
    ["The Iron Cafe"] = {
        CFrame.new(-8618.95898, -547.500183, 177.389847, 0.981545031, 6.44111608e-08, 0.191231206, -7.8954109e-08, 1, 6.84294932e-08, -0.191231206, -8.22651174e-08, 0.981545031),
        CFrame.new(-8608.74414, -547.500183, 159.39743, -0.0346038602, -1.00222408e-08, 0.999401093, 7.37646433e-09, 1, 1.02836539e-08, -0.999401093, 7.72790099e-09, -0.0346038602),
        CFrame.new(-8617.29395, -547.500183, 145.088608, -0.997185349, 1.96364649e-08, -0.0749754608, 1.6428654e-08, 1, 4.34015313e-08, 0.0749754608, 4.20476276e-08, -0.997185349)
    }
}

local function startAutoFarmLoop()
    NotifySuccess("Auto Farm Enabled", "Fishing started on island: " .. selectedIsland)

    while isAutoFarmRunning do  
        local islandSpots = farmLocations[selectedIsland]  
        if type(islandSpots) == "table" and #islandSpots > 0 then  
            location = islandSpots[math.random(1, #islandSpots)]  
        else  
            location = islandSpots  
        end  

        if not location then  
            NotifyError("Invalid Island", "Selected island name not found.")  
            return  
        end  

        local char = workspace:FindFirstChild("Characters"):FindFirstChild(LocalPlayer.Name)  
        local hrp = char and char:FindFirstChild("HumanoidRootPart")  
        if not hrp then  
            NotifyError("Teleport Failed", "HumanoidRootPart not found.")  
            return  
        end  

        hrp.CFrame = location  
        task.wait(1.5)  

        StartAutoFish5X()
        
        while isAutoFarmRunning do
            if not isAutoFarmRunning then  
                StopAutoFish5X()  
                NotifyWarning("Auto Farm Stopped", "Auto Farm manually disabled. Auto Fish stopped.")  
                break  
            end  
            task.wait(0.5)
        end
    end
end      

local nameList = {}
local islandNamesToCode = {}

for code, name in pairs(islandCodes) do
    table.insert(nameList, name)
    islandNamesToCode[name] = code
end

table.sort(nameList)

local CodeIsland = AutoFarmTab:Dropdown({
    Title = "Farm Island",
    Values = nameList,
    Value = nameList[9],
    Callback = function(selectedName)
        local code = islandNamesToCode[selectedName]
        local islandName = islandCodes[code]
        if islandName and farmLocations[islandName] then
            selectedIsland = islandName
            NotifySuccess("Island Selected", "Farming location set to " .. islandName)
        else
            NotifyError("Invalid Selection", "The island name is not recognized.")
        end
    end
})

myConfig:Register("IslCode", CodeIsland)

local AutoFarm = AutoFarmTab:Toggle({
	Title = "Start Auto Farm",
	Callback = function(state)
		isAutoFarmRunning = state
		if state then
			startAutoFarmLoop()
		else
			StopAutoFish()
		end
	end
})

myConfig:Register("AutoFarmStart", AutoFarm)

local eventNamesForDropdown = {}
for name in pairs(eventMap) do
    table.insert(eventNamesForDropdown, name)
end

AutoFarmTab:Dropdown({
	Title = "Auto Teleport Event",
	Desc = "Select event to auto teleport",
	Values = eventNames,
	Callback = function(selected)
		selectedEvent = selected
		autoTPEvent = true
		NotifyInfo("Event Selected", "Now monitoring event: " .. selectedEvent)
	end
})

-------------------------------------------
----- =======[ ARTIFACT TAB ]
-------------------------------------------

local REPlaceLeverItem = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/PlaceLeverItem"]

_G.UnlockTemple = function()
    task.spawn(function()
        local Artifacts = {
            "Hourglass Diamond Artifact",
            "Crescent Artifact",
            "Arrow Artifact",
            "Diamond Artifact"
        }

        for _, artifact in ipairs(Artifacts) do
            REPlaceLeverItem:FireServer(artifact)
            NotifyInfo("Temple Unlock", "Placing: " .. artifact)
            task.wait(2.1)
        end

        NotifySuccess("Temple Unlock", "All Artifacts placed successfully!")
    end)
end


_G.ArtifactSpots = {
    ["Spot 1"] = CFrame.new(1404.16931, 6.38866091, 118.118126, -0.964853525, 8.69606822e-08, 0.262788326, 9.85441346e-08, 1, 3.08992689e-08, -0.262788326, 5.5709517e-08, -0.964853525),
    ["Spot 2"] = CFrame.new(883.969788, 6.62499952, -338.560059, -0.325799465, 2.72482961e-08, 0.945438921, 3.40634649e-08, 1, -1.70824759e-08, -0.945438921, 2.6639464e-08, -0.325799465),
    ["Spot 3"] = CFrame.new(1834.76819, 6.62499952, -296.731476, 0.413336992, -7.92166972e-08, -0.910578132, 3.06007166e-08, 1, -7.31055181e-08, 0.910578132, 2.35287234e-09, 0.413336992),
    ["Spot 4"] = CFrame.new(1483.25586, 6.62499952, -848.38031, -0.986296117, 2.72397838e-08, 0.164984599, 3.60663037e-08, 1, 5.05033348e-08, -0.164984599, 5.57616318e-08, -0.986296117)
}

local REFishCaught = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/FishCaught"]

local saveFile = "ArtifactProgress.json"

if isfile(saveFile) then
    local success, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(readfile(saveFile))
    end)
    if success and type(data) == "table" then
        _G.ArtifactCollected = data.ArtifactCollected or 0
        _G.CurrentSpot = data.CurrentSpot or 1
    else
        _G.ArtifactCollected = 0
        _G.CurrentSpot = 1
    end
else
    _G.ArtifactCollected = 0
    _G.CurrentSpot = 1
end

_G.ArtifactFarmEnabled = false

local function saveProgress()
    local data = {
        ArtifactCollected = _G.ArtifactCollected,
        CurrentSpot = _G.CurrentSpot
    }
    writefile(saveFile, game:GetService("HttpService"):JSONEncode(data))
end

_G.StartArtifactFarm = function()
    if _G.ArtifactFarmEnabled then return end
    _G.ArtifactFarmEnabled = true

    updateParagraph("Auto Farm Artifact", ("Resuming from Spot %d..."):format(_G.CurrentSpot))

    local Player = game.Players.LocalPlayer
    task.wait(1)
    Player.Character:PivotTo(_G.ArtifactSpots["Spot " .. tostring(_G.CurrentSpot)])
    task.wait(1)

    StartAutoFish5X()
    _G.AutoFishStarted = true

    _G.ArtifactConnection = REFishCaught.OnClientEvent:Connect(function(fishName, data)
        if string.find(fishName, "Artifact") then
            _G.ArtifactCollected = _G.ArtifactCollected + 1
            saveProgress()

            updateParagraph(
                "Auto Farm Artifact",
                ("Artifact Found : %s\nTotal: %d/4"):format(fishName, _G.ArtifactCollected)
            )

            if _G.ArtifactCollected < 4 then
                _G.CurrentSpot = _G.CurrentSpot + 1
                saveProgress()
                local spotName = "Spot " .. tostring(_G.CurrentSpot)
                if _G.ArtifactSpots[spotName] then
                    task.wait(2)
                    Player.Character:PivotTo(_G.ArtifactSpots[spotName])
                    updateParagraph("Auto Farm Artifact",
                        ("Artifact Found : %s\nTotal : %d/4\n\nTeleporting to %s..."):format(
                            fishName,
                            _G.ArtifactCollected,
                            spotName
                        )
                    )
                    task.wait(1)
                end
            else
                updateParagraph("Auto Farm Artifact", "All Artifacts collected! Unlocking Temple...")
                StopAutoFish5X()
                task.wait(1.5)
                if typeof(_G.UnlockTemple) == "function" then
                    _G.UnlockTemple()
                end
                _G.StopArtifactFarm()
                delfile(saveFile)
            end
        end
    end)
end

_G.StopArtifactFarm = function()
    StopAutoFish()
    _G.ArtifactFarmEnabled = false
    _G.AutoFishStarted = false
    if _G.ArtifactConnection then
        _G.ArtifactConnection:Disconnect()
        _G.ArtifactConnection = nil
    end
    saveProgress()
    updateParagraph("Auto Farm Artifact", "Auto Farm Artifact stopped. Progress saved.")
end

function updateParagraph(title, desc)
    if _G.ArtifactParagraph then
        _G.ArtifactParagraph:SetDesc(desc)
    end
end

_G.ArtifactParagraph = AutoFarmArt:Paragraph({
    Title = "Auto Farm Artifact",
    Desc = "Waiting for activation...",
    Color = "Green",
})

AutoFarmArt:Toggle({
    Title = "Auto Farm Artifact",
    Desc = "Automatically collects 4 Artifacts and unlocks The Temple.",
    Default = false,
    Callback = function(state)
        if state then
            _G.StartArtifactFarm()
        else
            _G.StopArtifactFarm()
        end
    end
})

local spotNames = {}
for name in pairs(_G.ArtifactSpots) do
    table.insert(spotNames, name)
end

AutoFarmArt:Dropdown({
    Title = "Teleport to Lever Temple",
    Values = spotNames,
    Value = spotNames[1],
    Callback = function(selected)
        local spotCFrame = _G.ArtifactSpots[selected]
        if spotCFrame then
            local player = game.Players.LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart")

            if hrp then
                hrp.CFrame = spotCFrame
                NotifySuccess("Lever Temple", "Teleported to " .. selected)
            else
                warn("HumanoidRootPart not found!")
            end
        else
            warn("Invalid teleport spot: " .. tostring(selected))
        end
    end
})

AutoFarmArt:Button({
    Title = "Unlock The Temple",
    Desc = "Still need Artifacts!",
    Justify = "Center",
    Callback = function()
        _G.UnlockTemple()
    end
})


-------------------------------------------
----- =======[ MASS TRADE TAB ]
-------------------------------------------

-- [Trade State Baru]
local tradeState = { 
    mode = "V1",
    selectedPlayerName = nil, 
    selectedPlayerId = nil, 
    tradeAmount = 0, 
    autoTradeV2 = false,
    filterUnfavorited = false,
    
    saveTempMode = false,
    TempTradeList = {}, 
    onTrade = false 
}

-- [Cache & Utility untuk Mode V2]
local inventoryCache = {}
local fullInventoryDropdownList = {}

-- Asumsi Modul game inti sudah tersedia (seperti Replion)
local ItemUtility = _G.ItemUtility or require(ReplicatedStorage.Shared.ItemUtility) 
local ItemStringUtility = _G.ItemStringUtility or require(ReplicatedStorage.Modules.ItemStringUtility)
local InitiateTrade = net:WaitForChild("RF/InitiateTrade") 
local RFAwaitTradeResponse = net:WaitForChild("RF/AwaitTradeResponse") 

-- Fungsi utilitas untuk mendapatkan daftar pemain
local function getPlayerListV2()
    local list = {}; 
    for _, p in ipairs(Players:GetPlayers()) do 
        if p ~= LocalPlayer then 
            table.insert(list, p.Name) 
        end 
    end; 
    table.sort(list); 
    return list
end

local function refreshDropdownV2()
    if _G.PlayerDropdownTrade then
        _G.PlayerDropdownTrade:Refresh(getPlayerListV2())
    end
end

-- =======================================================
-- LOGIKA PEMBARUAN INVENTARIS 
-- =======================================================

local function refreshInventory()
    local DataReplion = _G.Replion.Client:WaitReplion("Data")
    if not DataReplion or not ItemUtility or not ItemStringUtility then 
        warn("Cannot refresh inventory: Missing modules.")
        return 
    end
    
    local inventoryItems = DataReplion:Get({ "Inventory", "Items" })
    local groupedItems = {}
    inventoryCache = {}
    fullInventoryDropdownList = {}

    if not inventoryItems then return end

    for _, itemData in ipairs(inventoryItems) do
        local baseItemData = ItemUtility:GetItemData(itemData.Id)
        
        if baseItemData and baseItemData.Data and (baseItemData.Data.Type == "Fish" or baseItemData.Data.Type == "Enchant Stones") then
            -- Filter Unfavorited (Mode V2)
            if not (tradeState.filterUnfavorited and itemData.Favorited) then
                local dynamicName = ItemStringUtility.GetItemName(itemData, baseItemData)
                if not groupedItems[dynamicName] then
                    groupedItems[dynamicName] = 0
                    inventoryCache[dynamicName] = {}
                end
                groupedItems[dynamicName] = (groupedItems[dynamicName] or 0) + 1
                table.insert(inventoryCache[dynamicName], itemData.UUID)
            end
        end
    end

    for name, count in pairs(groupedItems) do
        table.insert(fullInventoryDropdownList, string.format("%s (%dx)", name, count))
    end
    table.sort(fullInventoryDropdownList)

    -- Perbarui Dropdown Item dan Pemain
    if _G.InventoryDropdown then _G.InventoryDropdown:Refresh(fullInventoryDropdownList) end
    if _G.PlayerDropdownTrade then _G.PlayerDropdownTrade:Refresh(getPlayerListV2()) end
end

-- =======================================================
-- LOGIKA HOOKING
-- =======================================================

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
_G.REEquipItem = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/EquipItem"]


mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    -- Logika Save/Send Trade Original (Mode Quiet)
    if method == "FireServer" and self == _G.REEquipItem then
        local uuid, categoryName = args[1], args[2]

        if tradeState.mode == "V1" and tradeState.saveTempMode then
            if uuid and categoryName then
                table.insert(tradeState.TempTradeList, {
                    UUID = uuid,
                    Category = categoryName
                })
                NotifySuccess("Save Mode", "Added item: " .. uuid .. " (" .. categoryName .. ")")
            else
                NotifyError("Save Mode", "Invalid data received.")
            end
            return nil
        end

        if tradeState.mode == "V1" and tradeState.onTrade then
            if uuid and tradeState.selectedPlayerId then
                InitiateTrade:InvokeServer(tradeState.selectedPlayerId, uuid)
                NotifySuccess("Trade Sent", "Trade sent to " .. tradeState.selectedPlayerName or tradeState.selectedPlayerId)
            else
                NotifyError("Trade Error", "Invalid target or item.")
            end
            return nil
        end
    end

	if _G.autoSellMythic 
		and method == "FireServer"
		and self == _G.REEquipItem 
		and typeof(args[1]) == "string"
		and args[2] == "Fishes" then

		local uuid = args[1]

		task.delay(1, function()
			pcall(function()
				local result = RFSellItem:InvokeServer(uuid)
				if result then
					NotifySuccess("AutoSellMythic", "Items Sold!!")
				else
					NotifyError("AutoSellMythic", "Failed to sell item!!")
				end
			end)
		end)
	end
    
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- Implementasi Auto Accept Trade
pcall(function()
    local PromptController = _G.PromptController or ReplicatedStorage:WaitForChild("Controllers").PromptController 
    local Promise = _G.Promise or require(ReplicatedStorage.Packages.Promise) 
    
    if PromptController and PromptController.FirePrompt then
        local oldFirePrompt = PromptController.FirePrompt
        PromptController.FirePrompt = function(self, promptText, ...)
            -- Cek apakah Auto Accept aktif dan prompt adalah Trade
            if _G.AutoAcceptTradeEnabled and type(promptText) == "string" and promptText:find("Accept") and promptText:find("from:") then
                -- Mengembalikan Promise yang otomatis me-resolve (menerima) setelah jeda.
                return Promise.new(function(resolve)
                    task.wait(2) -- Tunggu 2 detik
                    resolve(true)
                end)
            end
            return oldFirePrompt(self, promptText, ...)
        end
    end
end)


-- =======================================================
-- DEFINISI UI
-- =======================================================

Trade:Section({Title = "Trade Mode Selection"})

local modeDropdown = Trade:Dropdown({
    Title = "Select Trade Mode",
    Values = {"V1", "V2", "V3"},
    Value = "V1",
    Callback = function(v)
        tradeState.mode = v
        NotifySuccess("Mode Changed", "Trade mode set to: " .. v, 3)

        -- Logika Baru untuk Menampilkan/Menyembunyikan UI
        local isV1 = (v == "V1")
        local isV2 = (v == "V2")
        local isV3 = (v == "V3")

        -- Sembunyikan/Tampilkan Elemen V1
        if _G.TradeQuietElements then
            for _, element in ipairs(_G.TradeQuietElements) do
                if element.Element then element.Element.Visible = isV1 end
            end
        end
        
        -- Sembunyikan/Tampilkan Elemen V2
        if _G.TradeV2Elements then
            for _, element in ipairs(_G.TradeV2Elements) do
                if element.Element then element.Element.Visible = isV2 end
            end
        end

        -- Sembunyikan/Tampilkan Elemen V3
        if _G.TradeV3Elements then
            for _, element in ipairs(_G.TradeV3Elements) do
                if element.Element then element.Element.Visible = isV3 end
            end
        end
    end
})

local playerDropdown = Trade:Dropdown({
    Title = "Select Trade Target",
    Values = getPlayerListV2(),
    Value = getPlayerListV2()[1] or nil,
    SearchBarEnabled = true,
    Callback = function(selected)
        tradeState.selectedPlayerName = selected
        local player = Players:FindFirstChild(selected)
        if player then
            tradeState.selectedPlayerId = player.UserId
            NotifySuccess("Target Selected", "Target set to: " .. player.Name, 3)
        else
            tradeState.selectedPlayerId = nil
            NotifyError("Target Error", "Player not found!", 3)
        end
    end
})
_G.PlayerDropdownTrade = playerDropdown -- Simpan referensi untuk refresh

Players.PlayerAdded:Connect(function()
    task.delay(0.1, refreshDropdownV2)
end)

Players.PlayerRemoving:Connect(function()
    task.delay(0.1, refreshDropdownV2)
end)

refreshDropdownV2()

Trade:Section({Title = "Auto Accept Trade"})

Trade:Toggle({
    Title = "Enable Auto Accept Trade",
    Desc = "Automatically accepts incoming trade requests.",
    Value = false,
    Callback = function(value)
        _G.AutoAcceptTradeEnabled = value
        if value then
            NotifySuccess("Auto Accept", "Auto accept trade enabled.", 3)
        else
            NotifyWarning("Auto Accept", "Auto accept trade disabled.", 3)
        end
    end
})

Trade:Section({Title = "Mode V1"})
_G.TradeQuietElements = {}

-- Toggle Mode Save Items (Mode V1)
local saveModeToggle = Trade:Toggle({
    Title = "Mode Save Items",
    Desc = "Click inventory item to add for Mass Trade",
    Value = false,
    Callback = function(state)
        tradeState.saveTempMode = state
        if state then
            tradeState.TempTradeList = {}
            NotifySuccess("Save Mode", "Enabled - Click items to save")
        else
            NotifyInfo("Save Mode", "Disabled - "..#tradeState.TempTradeList.." items saved")
        end
    end
})
table.insert(_G.TradeQuietElements, {Element = saveModeToggle})

-- Toggle Trade (Original Send) (V1)
local originalTradeToggle = Trade:Toggle({
    Title = "Trade (Original Send)",
    Desc = "Click inventory items to Send Trade",
    Value = false,
    Callback = function(state)
        tradeState.onTrade = state
        if state then
            NotifySuccess("Trade", "Trade Mode Enabled. Click an item to send trade.")
        else
            NotifyWarning("Trade", "Trade Mode Disabled.")
        end
    end
})
table.insert(_G.TradeQuietElements, {Element = originalTradeToggle})

-- Fungsi Trade All (Mode V1)
local function TradeAllQuiet()       
    if not tradeState.selectedPlayerId then    
        NotifyError("Mass Trade", "Set trade target first!")       
        return         
    end          
    if #tradeState.TempTradeList == 0 then       
        NotifyWarning("Mass Trade", "No items saved!")          
        return         
    end          
    
    NotifyInfo("Mass Trade", "Starting V1 trade of "..#tradeState.TempTradeList.." items...")      
    
    task.spawn(function()          
        for i, item in ipairs(tradeState.TempTradeList) do          
            if not tradeState.autoTradeV2 then
                NotifyWarning("Mass Trade", "V1 Trade stopped!")         
                break          
            end          
        
            local uuid = item.UUID          
            local category = item.Category          
        
            NotifyInfo("Mass Trade", "Trade item "..i.." of "..#tradeState.TempTradeList)          
            InitiateTrade:InvokeServer(tradeState.selectedPlayerId, uuid, category)          
        
            task.wait(6.5)       
        end          
    
        NotifySuccess("Mass Trade", "Finished V1 trading!")        
        tradeState.autoTradeV2 = false          
        tradeState.TempTradeList = {}          
    end)          
end

-- Toggle Auto Trade (Mode V1)
local autoTradeQuietToggle = Trade:Toggle({
    Title = "Start Mass Trade V1",
    Desc = "Trade all saved items automatically.",
    Value = false,
    Callback = function(state)
        tradeState.autoTradeV2 = state
        if tradeState.mode == "V1" and state then
            if #tradeState.TempTradeList == 0 then
                NotifyError("Mass Trade", "No items saved to trade!")
                tradeState.autoTradeV2 = false
                return
            end
            TradeAllQuiet()
            NotifySuccess("Mass Trade", "V1 Auto Trade Enabled")
        else
            NotifyWarning("Mass Trade", "V1 Auto Trade Disabled")
        end
    end
})
table.insert(_G.TradeQuietElements, {Element = autoTradeQuietToggle})

Trade:Section({Title = "V2"})
_G.TradeV2Elements = {}

local filterToggleV2 = Trade:Toggle({
    Title = "Filter Unfavorited Items Only",
    Value = false,
    Callback = function(val)
        tradeState.filterUnfavorited = val
        refreshInventory()
        NotifyInfo("Filter Updated", "Inventory list refreshed.", 3)
    end
})
table.insert(_G.TradeV2Elements, {Element = filterToggleV2})

_G.InventoryDropdown = Trade:Dropdown({
    Title = "Select Item from Inventory",
    Values = {"- Refresh to load -"},
    AllowNone = true,
    SearchBarEnabled = true,
    Callback = function(val)
        tradeState.selectedItemName = val
    end
})
table.insert(_G.TradeV2Elements, {Element = _G.InventoryDropdown})

Trade:Button({ Title = "Refresh Inventory & Players", Icon = "refresh-cw", Callback = refreshInventory })

local amountInputV2 = Trade:Input({
    Title = "Amount to Trade",
    Placeholder = "Enter amount...",
    Type = "Input",
    Callback = function(val)
        tradeState.tradeAmount = tonumber(val) or 0
    end
})
table.insert(_G.TradeV2Elements, {Element = amountInputV2})

local statusParagraphV2 = Trade:Paragraph({ Title = "Status V2", Desc = "Waiting to start..." })
table.insert(_G.TradeV2Elements, {Element = statusParagraphV2})

-- Toggle Start Mass Trade (V2)
Trade:Toggle({
    Title = "Start Mass Trade V2",
    Value = false,
    Callback = function(value)
        tradeState.autoTradeV2 = value
        if tradeState.mode == "V2" and value then
            task.spawn(function()
                if not tradeState.selectedItemName or not tradeState.selectedPlayerId or tradeState.tradeAmount <= 0 then
                    statusParagraphV2:SetDesc("Error: Select item, amount, and player.")
                    tradeState.autoTradeV2 = false
                    return
                end

                local cleanItemName = tradeState.selectedItemName:match("^(.*) %((%d+)x%)$")
                if cleanItemName then cleanItemName = cleanItemName:match("^(.*)") end 
                if not cleanItemName then cleanItemName = tradeState.selectedItemName end

                local uuidsToSend = inventoryCache[cleanItemName]

                if not uuidsToSend or #uuidsToSend < tradeState.tradeAmount then
                    statusParagraphV2:SetDesc("Error: Not enough items. Refresh inventory.")
                    tradeState.autoTradeV2 = false
                    return
                end

                local successCount, failCount = 0, 0
                local targetName = tradeState.selectedPlayerName

                for i = 1, tradeState.tradeAmount do 
                    if not tradeState.autoTradeV2 then
                        statusParagraphV2:SetDesc("Process stopped by user.")
                        break
                    end

                    local uuid = uuidsToSend[i]
                    statusParagraphV2:SetDesc(string.format(
                        "Progress: %d/%d | Sending to: %s | Status: <font color='#eab308'>Waiting...</font>",
                        i, tradeState.tradeAmount, targetName))

                    local success, result = pcall(InitiateTrade.InvokeServer, InitiateTrade, tradeState.selectedPlayerId, uuid)

                    if success and result then
                        successCount = successCount + 1
                    else
                        failCount = failCount + 1
                    end

                    statusParagraphV2:SetDesc(string.format(
                        "Progress: %d/%d | Sent: %s | Success: %d | Failed: %d",
                        i, tradeState.tradeAmount, success and "âœ…" or "âŒ", successCount, failCount))
                    
                    task.wait(5) 
                end

                statusParagraphV2:SetDesc(string.format(
                    "Trade V2 Process Complete.\nSuccessful: %d | Failed: %d",
                    successCount, failCount))

                tradeState.autoTradeV2 = false
                refreshInventory()
            end)
        end
    end
})

-- Sembunyikan elemen GLua secara default, kecuali tombol refresh dan dropdown mode
for _, element in ipairs(_G.TradeV2Elements) do
    if element.Element then element.Element.Visible = false end
end

-- Pastikan elemen Quiet terlihat
for _, element in ipairs(_G.TradeQuietElements) do
    if element.Element then element.Element.Visible = true end
end

-------------------------------------------
----- ======= V3 - MASS TRADE BY CATEGORY
-------------------------------------------


if Trade and GlobalFav and GlobalFav.Variants and NotifyWarning and _G.Replion and _G.ItemUtility and _G.ItemStringUtility and InitiateTrade then
    
    _G.TradeV3Elements = {}

    local V3_Section = Trade:Section({Title = "V3 - Mass Trade by Category"})
    table.insert(_G.TradeV3Elements, {Element = V3_Section}) -- Daftarkan UI

    -- Data yang diperlukan untuk Tiers
    local tierMap = {
        ["Common"] = 1, ["Uncommon"] = 2, ["Rare"] = 3, ["Epic"] = 4,
        ["Legendary"] = 5, ["Mythic"] = 6, ["SECRET"] = 7
    }
    local tierNames = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET" }

    -- Data yang diperlukan untuk Variants (Mutasi)
    local variantNames = {}
    for vName, _ in pairs(GlobalFav.Variants) do
        table.insert(variantNames, vName)
    end
    if not table.find(variantNames, "Shiny") then
        table.insert(variantNames, "Shiny")
    end
    table.sort(variantNames)
    
    -- State untuk V3
    -- State untuk V3
    local categoryTradeState = {
        selectedTiers = {}, selectedVariants = {},
        filterUnfavorited = false, autoTrade = false,
        tradeAmount = 0 -- TAMBAHKAN BARIS INI
    }
    -- UI V3
    local V3_TierDropdown = Trade:Dropdown({
        Title = "Select Tiers (Rarity) to Trade",
        Values = tierNames, Multi = true, AllowNone = true,
        Callback = function(selectedNames)
            categoryTradeState.selectedTiers = {}
            for _, name in ipairs(selectedNames or {}) do
                if tierMap[name] then table.insert(categoryTradeState.selectedTiers, tierMap[name]) end
            end
            NotifyInfo("Trade V3", "Tiers to trade: " .. table.concat(selectedNames, ", "))
        end
    })
    table.insert(_G.TradeV3Elements, {Element = V3_TierDropdown}) -- Daftarkan UI

    local V3_VariantDropdown = Trade:Dropdown({
        Title = "Select Mutations (Variants) to Trade",
        Values = variantNames, Multi = true, AllowNone = true,
        Callback = function(selectedNames)
            categoryTradeState.selectedVariants = selectedNames or {}
            NotifyInfo("Trade V3", "Mutations to trade: " .. table.concat(selectedNames, ", "))
        end
    })
    table.insert(_G.TradeV3Elements, {Element = V3_VariantDropdown}) -- Daftarkan UI

    local V3_FilterToggle = Trade:Toggle({
        Title = "Filter Unfavorited Items Only",
        Desc = "Hanya mengirim item yang tidak di-lock (favorite).", Value = false,
        Callback = function(val)
            categoryTradeState.filterUnfavorited = val
            NotifyInfo("Trade V3", "Filter Unfavorited: " .. tostring(val))
        end
    })
    table.insert(_G.TradeV3Elements, {Element = V3_FilterToggle}) -- Daftarkan UI
    
    -- ===================================
    -- == [BARU] INPUT AMOUNT UNTUK V3
    -- ===================================
    local V3_AmountInput = Trade:Input({
        Title = "Amount to Trade",
        Placeholder = "Enter amount...",
        Type = "Input",
        Callback = function(val)
            categoryTradeState.tradeAmount = tonumber(val) or 0
        end
    })
    table.insert(_G.TradeV3Elements, {Element = V3_AmountInput})

    local V3_StatusParagraph = Trade:Paragraph({
        Title = "Status V3", Desc = "Waiting to start..."
    })
    table.insert(_G.TradeV3Elements, {Element = V3_StatusParagraph}) -- Daftarkan UI

    local V3_StartToggle = Trade:Toggle({
        Title = "Start Mass Category Trade", Value = false,
        Callback = function(value)
            categoryTradeState.autoTrade = value
            if not value then V3_StatusParagraph:SetDesc("Stopping..."); return end

            task.spawn(function()
                -- 1. Validasi
                if not tradeState.selectedPlayerId then
                    V3_StatusParagraph:SetDesc("Error: Please select a player from the 'Select Trade Target' dropdown above.")
                    pcall(V3_StartToggle.SetValue, V3_StartToggle, false); return
                end
                if #categoryTradeState.selectedTiers == 0 and #categoryTradeState.selectedVariants == 0 then
                    V3_StatusParagraph:SetDesc("Error: Select at least one Tier or Mutation to trade.")
                    pcall(V3_StartToggle.SetValue, V3_StartToggle, false); return
                end
                
                -- ===================================
                -- == [BARU] VALIDASI AMOUNT V3
                -- ===================================
                if categoryTradeState.tradeAmount <= 0 then
                    V3_StatusParagraph:SetDesc("Error: Please enter a valid amount in the 'Amount to Trade (V3)' input.")
                    pcall(V3_StartToggle.SetValue, V3_StartToggle, false); return
                end
                -- ===================================

                local DataReplion = _G.Replion.Client:WaitReplion("Data")
                if not DataReplion then
                    V3_StatusParagraph:SetDesc("Error: Could not get player data (Replion).")
                    pcall(V3_StartToggle.SetValue, V3_StartToggle, false); return
                end

                -- 2. Scan inventaris
                V3_StatusParagraph:SetDesc("Scanning inventory for matching items..."); task.wait(0.5)
                local uuidsToSend, itemNamesSummary = {}, {}
                local inventoryItems = DataReplion:Get({ "Inventory", "Items" })
                if not inventoryItems then
                    V3_StatusParagraph:SetDesc("Error: Inventory is empty.")
                    pcall(V3_StartToggle.SetValue, V3_StartToggle, false); return
                end

                -- 3. Filter item (Logika ini tetap sama)
                for _, itemData in ipairs(inventoryItems) do
                    if not categoryTradeState.autoTrade then break end
                    if not (categoryTradeState.filterUnfavorited and itemData.Favorited) then
                        local baseItemData = _G.ItemUtility:GetItemData(itemData.Id)
                        if baseItemData and baseItemData.Data and baseItemData.Data.Type == "Fish" then
                            local match = false
                            if #categoryTradeState.selectedTiers > 0 then
                                if baseItemData.Data.Tier and table.find(categoryTradeState.selectedTiers, baseItemData.Data.Tier) then match = true end
                            end
                            if not match and #categoryTradeState.selectedVariants > 0 then
                                if itemData.Metadata and type(itemData.Metadata) == "table" then
                                    local itemMutations = {}
                                    if itemData.Metadata.VariantId then table.insert(itemMutations, itemData.Metadata.VariantId) end
                                    if itemData.Metadata.Shiny == true then table.insert(itemMutations, "Shiny") end
                                    for _, itemMutationName in ipairs(itemMutations) do
                                        if table.find(categoryTradeState.selectedVariants, itemMutationName) then match = true; break end
                                    end
                                end
                            end
                            if match then
                                table.insert(uuidsToSend, itemData.UUID)
                                local simpleName = _G.ItemStringUtility.GetItemName(itemData, baseItemData)
                                itemNamesSummary[simpleName] = (itemNamesSummary[simpleName] or 0) + 1
                            end
                        end
                    end
                end

                if not categoryTradeState.autoTrade then V3_StatusParagraph:SetDesc("Trade stopped during scan."); return end
                if #uuidsToSend == 0 then
                    V3_StatusParagraph:SetDesc("Complete: No matching items found to trade.")
                    pcall(V3_StartToggle.SetValue, V3_StartToggle, false); return
                end

                -- ===================================
                -- == [DIUBAH] LOGIKA PENGIRIMAN ITEM DENGAN AMOUNT
                -- ===================================
                
                -- 4. Kirim item
                local totalFound = #uuidsToSend
                -- Gunakan math.min untuk mengambil jumlah yang lebih kecil antara yang ditemukan dan yang diminta
                local amountToSend = math.min(totalFound, categoryTradeState.tradeAmount) 
                local successCount, failCount = 0, 0
                local targetName = tradeState.selectedPlayerName

                -- Ubah loop dari 'ipairs' menjadi loop numerik sampai 'amountToSend'
                for i = 1, amountToSend do
                    if not categoryTradeState.autoTrade then V3_StatusParagraph:SetDesc("Trade stopped by user."); break end
                    
                    local uuid = uuidsToSend[i] -- Ambil UUID berdasarkan index
                    
                    -- Update status untuk menunjukkan progress, amount, dan total yang ditemukan
                    V3_StatusParagraph:SetDesc(string.format(
                        "Progress: %d/%d (Found: %d)\nSending to: %s\nSuccess: %d | Failed: %d", 
                        i, amountToSend, totalFound, targetName, successCount, failCount
                    ))
                    
                    local success, result = pcall(InitiateTrade.InvokeServer, InitiateTrade, tradeState.selectedPlayerId, uuid)
                    if success and result then successCount = successCount + 1 else failCount = failCount + 1 end
                    task.wait(5)
                end

                -- 5. Laporan akhir
                local finalSummary = string.format(
                    "Process Complete.\nTotal Attempted: %d of %d found.\nSuccessful: %d | Failed: %d", 
                    amountToSend, totalFound, successCount, failCount
                )
                -- ===================================

                V3_StatusParagraph:SetDesc(finalSummary)
                NotifySuccess("Mass Category Trade", finalSummary, 7)
                pcall(V3_StartToggle.SetValue, V3_StartToggle, false)
            end)
        end
    })
    table.insert(_G.TradeV3Elements, {Element = V3_StartToggle}) -- Daftarkan UI


else
    task.spawn(function()
        task.wait(2)
        NotifyError("Trade V3 Load Error", "Gagal memuat fitur Trade V3. Dependensi penting (seperti Trade atau GlobalFav) tidak ditemukan. Anda mungkin salah menempelkan kode atau skrip QuietXHub Anda tidak lengkap.", 10)
    end)
end

-------------------------------------------
----- =======[ PLAYER TAB ]
-------------------------------------------

local currentDropdown = nil

local function getPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.DisplayName)
        end
    end
    return list
end


local function teleportToPlayerExact(target)
    local characters = workspace:FindFirstChild("Characters")
    if not characters then return end

    local targetChar = characters:FindFirstChild(target)
    local myChar = characters:FindFirstChild(LocalPlayer.Name)

    if targetChar and myChar then
        local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        if targetHRP and myHRP then
            myHRP.CFrame = targetHRP.CFrame + Vector3.new(2, 0, 0)
        end
    end
end

local function refreshDropdown()
    if currentDropdown then
        currentDropdown:Refresh(getPlayerList())
    end
end

currentDropdown = Player:Dropdown({
    Title = "Teleport to Player",
    Desc = "Select player to teleport",
    Values = getPlayerList(),
    Callback = function(selectedDisplayName)
        for _, p in pairs(Players:GetPlayers()) do
            if p.DisplayName == selectedDisplayName then
                teleportToPlayerExact(p.Name)
                NotifySuccess("Teleport Successfully", "Successfully Teleported to " .. p.DisplayName .. "!", 3)
                break
            end
        end
    end
})

Players.PlayerAdded:Connect(function()
    task.delay(0.1, refreshDropdown)
end)

Players.PlayerRemoving:Connect(function()
    task.delay(0.1, refreshDropdown)
end)

refreshDropdown()


local defaultMinZoom = LocalPlayer.CameraMinZoomDistance
local defaultMaxZoom = LocalPlayer.CameraMaxZoomDistance

Player:Toggle({
    Title = "Unlimited Zoom",
    Desc = "Unlimited Camera Zoom for take a Picture",
    Value = false,
    Callback = function(state)
        if state then
            LocalPlayer.CameraMinZoomDistance = 0.5
            LocalPlayer.CameraMaxZoomDistance = 9999
        else
            LocalPlayer.CameraMinZoomDistance = defaultMinZoom
            LocalPlayer.CameraMaxZoomDistance = defaultMaxZoom
        end
    end
})


local function accessAllBoats()
    local vehicles = workspace:FindFirstChild("Vehicles")
    if not vehicles then
        NotifyError("Not Found", "Vehicles container not found.")
        return
    end

    local count = 0

    for _, boat in ipairs(vehicles:GetChildren()) do
        if boat:IsA("Model") and boat:GetAttribute("OwnerId") then
            local currentOwner = boat:GetAttribute("OwnerId")
            if currentOwner ~= LocalPlayer.UserId then
                boat:SetAttribute("OwnerId", LocalPlayer.UserId)
                count = count + 1
            end
        end
    end

    NotifySuccess("Access Granted", "You now own " .. count .. " boat(s).", 3)
end

Player:Button({
    Title = "Access All Boats",
    Callback = accessAllBoats
})

Player:Toggle({
	Title = "Infinity Jump",
	Callback = function(val)
		ijump = val
	end,
})

game:GetService("UserInputService").JumpRequest:Connect(function()
	if ijump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
		LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
	end
end)

local EnableFloat = Player:Toggle({
	Title = "Enable Float",
	Value = false,
	Callback = function(enabled)
			floatingPlat(enabled)
	end,
})

myConfig:Register("ActiveFloat", EnableFloat)

local universalNoclip = false
local originalCollisionState = {}

local NoClip = Player:Toggle({
	Title = "Universal No Clip",
	Value = false,
	Callback = function(val)
		universalNoclip = val

		if val then
			NotifySuccess("Universal Noclip Active", "You & your vehicle can penetrate all objects.", 3)
		else

			for part, state in pairs(originalCollisionState) do
				if part and part:IsA("BasePart") then
					part.CanCollide = state
				end
			end
			originalCollisionState = {}
			NotifyWarning("Universal Noclip Disabled", "All collisions are returned to their original state.", 3)
		end
	end,
})

game:GetService("RunService").Stepped:Connect(function()
	if not universalNoclip then return end

	local char = LocalPlayer.Character
	if char then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") and part.CanCollide == true then
				originalCollisionState[part] = true
				part.CanCollide = false
			end
		end
	end

	for _, model in ipairs(workspace:GetChildren()) do
		if model:IsA("Model") and model:FindFirstChildWhichIsA("VehicleSeat", true) then
			for _, part in ipairs(model:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide == true then
					originalCollisionState[part] = true
					part.CanCollide = false
				end
			end
		end
	end
end)

myConfig:Register("NoClip", NoClip)

local AntiDrown_Enabled = false
local rawmt = getrawmetatable(game)
setreadonly(rawmt, false)
local oldNamecall = rawmt.__namecall

rawmt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if tostring(self) == "URE/UpdateOxygen" and method == "FireServer" and AntiDrown_Enabled then
        return nil
    end

    return oldNamecall(self, ...)
end)

local DrownBN = true

local ADrown = Player:Toggle({
	Title = "Anti Drown (Oxygen Bypass)",
	Callback = function(state)
		AntiDrown_Enabled = state
		if DrownBN then
			DrownBN = false
			return
		end
		if state then
			NotifySuccess("Anti Drown Active", "Oxygen loss has been blocked.", 3)
		else
			NotifyWarning("Anti Drown Disabled", "You're vulnerable to drowning again.", 3)
		end
	end,
})

myConfig:Register("AntiDrown", ADrown)

local Speed = Player:Slider({
	Title = "WalkSpeed",
	Value = {
	    Min = 16,
	    Max = 200,
	    Default = 20
	},
	Step = 1,
	Callback = function(val)
		local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = val end
	end,
})

myConfig:Register("PlayerSpeed", Speed)

local Jp = Player:Slider({
	Title = "Jump Power",
	Value = {
	    Min = 50, 
	    Max = 500,
	    Default = 35
	},
	Step = 10,
	Callback = function(val)
		local char = LocalPlayer.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.UseJumpPower = true
				hum.JumpPower = val
			end
		end
	end,
})

myConfig:Register("JumpPower", Jp)

-------------------------------------------
----- =======[ SKINS TAB ]
-------------------------------------------

_G.RERollSkinCrate = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/RollSkinCrate"]
_G.RFPurchaseSkinCrate = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/PurchaseSkinCrate"]

_G.SkinCrates = {
	  ["Luxury Crate"] = {"Cursed Soul", "Timeless", "Disco", "Abyssfire", "Planetary"},
	  ["Enchanted Crate"] = {"Jelly", "Cursed", "Amber", "Flower Garden", "Aether Shard"},
	  ["Ocean Crate"] = { "Monochrome", "Crystalized"},
    ["Silver Crate"] = { "Polarized", "Forsaken", "Earthly", "Neptune's Trident" },
    ["Energy Crate"] = { "Fiery", "Soulreaver", "Pirate Octopus", "Pinata", "Purple Saber" }
}

_G.SelectedCrate = "Silver Crate"
_G.SelectedSkin = "Polarized"

TabSkins:Dropdown({
    Title = "Select Crate",
    Values = { "Luxury Crate", "Enchanted Crate", "Ocean Crate", "Silver Crate", "Energy Crate" },
    Value = _G.SelectedCrate,
    Callback = function(option)
        _G.SelectedCrate = option
        NotifySuccess("Crate Selected", "Selected: " .. option)
        
        local skins = _G.SkinCrates[option]
        if _G.SkinDropdown then
            _G.SkinDropdown:Refresh(skins)
            _G.SelectedSkin = skins[1]
        end
    end
})

_G.SkinDropdown = TabSkins:Dropdown({
    Title = "Select Skin",
    Values = _G.SkinCrates[_G.SelectedCrate],
    Value = _G.SelectedSkin,
    Callback = function(option)
        _G.SelectedSkin = option
        NotifySuccess("Skin Selected", "Selected: " .. option
        )
    end
})

TabSkins:Button({
    Title = "Fake Roll Skin",
    Callback = function()
        if _G.RERollSkinCrate then
            local crate = _G.SelectedCrate
            local skin = _G.SelectedSkin
            local data = string.format("[\"Fishing Rods\",\"!!! %s\",1]", skin)
            firesignal(_G.RERollSkinCrate.OnClientEvent, crate, data)
            
            NotifySuccess("Fake Roll Sent", "Crate: " .. crate .. "\nSkin: " .. skin)
        else
            warn("RERollSkinCrate not found.")
        end
    end
})

TabSkins:Button({
    Title = "Buy Selected Crate",
    Callback = function()
        if _G.RFPurchaseSkinCrate then
            _G.RFPurchaseSkinCrate:InvokeServer(_G.SelectedCrate, 1)
            NotifySuccess("Crate Purchased", "Successfully purchased " .. _G.SelectedCrate)
        else
            warn("RFPurchaseSkinCrate not found.")
        end
    end
})

-------------------------------------------
----- =======[ DOUBLE ENCHANT STONES ]
-------------------------------------------

DStones:Paragraph({
	Title = "Guide",
	Color = "Green",
	Desc = [[
TUTORIAL FOR DOUBLE ENCHANT

1. "Enabled Double Enchant" first
2. Hold your "SECRET" fish, then click "Get Enchant Stone"
3. Click "Double Enchant Rod" to do Double Enchant, and don't forget to place the stone in slot 5

Good Luck!
]]
})

_G.ReplicatedStorage = game:GetService("ReplicatedStorage")

DStones:Button({
    Title = "Enable Double Enchant",
    Locked = false,
    Callback = function()
        _G.ActivateDoubleEnchant = _G.ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ActivateSecondEnchantingAltar"]
        if _G.ActivateDoubleEnchant then
            _G.ActivateDoubleEnchant:FireServer()
            NotifySuccess("Double Enchant", "Double Enchant Enabled for Rods")
        else
            warn("Cant find Double Enchant functions")
        end
    end
})

DStones:Button({
    Title = "Get Enchant Stones",
    Locked = false,
    Callback = function()
        _G.CreateTranscendedStone = _G.ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/CreateTranscendedStone"]
        if _G.CreateTranscendedStone then
            local result = _G.CreateTranscendedStone:InvokeServer()
            NotifySuccess("Double Enchant", "Got Enchant Stone!")
        else
            warn("[❌] Tidak dapat menemukan RemoteFunction CreateTranscendedStone.")
        end
    end
})

DStones:Button({
	Title = "Double Enchant Rod",
	Desc = "Hold the stone in slot 5",
	Callback = function()
		_G.ActiveStone = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ActivateSecondEnchantingAltar"]
		if _G.ActiveStone then
			local result = _G.ActiveStone:FireServer()
			NotifySuccess("Double Enchant", "Enchanting....")
		else
			warn("Error something")
		end
	end
})

-------------------------------------------
----- =======[ UTILITY TAB ]
-------------------------------------------

_G.RFRedeemCode = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/RedeemCode"]

_G.RedeemCodes = {
    "BLAMETALON",
    "FISHMAS2025",
    "GOLDENSHARK",
    "THANKYOU",
    "PURPLEMOON"
}

_G.RedeemAllCodes = function()
    for _, code in ipairs(_G.RedeemCodes) do
        local success, result = pcall(function()
            return _G.RFRedeemCode:InvokeServer(code)
        end)
        task.wait(1)
    end
end

Utils:Button({
    Title = "Redeem All Codes",
    Locked = false,
    Justify = "Center",
    Icon = "",
    Callback = function()
        _G.RedeemAllCodes()
    end
})

local RFPurchaseMarketItem = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/PurchaseMarketItem"]

local merchantItems = {
    ["Luck Totem | 2M"] = 5,
    ["Royal Bait | 400K+"] = 4,
}

local function getKeys(tbl)
    local keys = {}
    for k, _ in pairs(tbl) do
        table.insert(keys, k)
    end
    return keys
end

Utils:Dropdown({
    Title = "Traveling Merchant",
    Desc = "Select an item to purchase from Traveling Merchant",
    Values = getKeys(merchantItems),
    Callback = function(selected)
        local itemID = merchantItems[selected]
        if itemID then
            local success, err = pcall(function()
                RFPurchaseMarketItem:InvokeServer(itemID)
            end)
            if success then
                NotifyInfo("Purchase Success", "Successfully bought: " .. selected)
            else
                NotifyInfo("Purchase Failed", "Error: " .. tostring(err))
            end
        end
    end
})

local weatherActive = {}
local weatherData = {
    ["Storm"] = { duration = 900 },
    ["Cloudy"] = { duration = 900 },
    ["Snow"] = { duration = 900 },
    ["Wind"] = { duration = 900 },
    ["Radiant"] = { duration = 900 }
}

local function randomDelay(min, max)
    return math.random(min * 100, max * 100) / 100
end

local function autoBuyWeather(weatherType)
    local purchaseRemote = ReplicatedStorage:WaitForChild("Packages")
        :WaitForChild("_Index")
        :WaitForChild("sleitnick_net@0.2.0")
        :WaitForChild("net")
        :WaitForChild("RF/PurchaseWeatherEvent")

    task.spawn(function()
        while weatherActive[weatherType] do
            pcall(function()
                purchaseRemote:InvokeServer(weatherType)
                NotifySuccess("Weather Purchased", "Successfully activated " .. weatherType)

                task.wait(weatherData[weatherType].duration)

                local randomWait = randomDelay(1, 5)
                NotifyInfo("Waiting...", "Delay before next purchase: " .. tostring(randomWait) .. "s")
                task.wait(randomWait)
            end)
        end
    end)
end

local WeatherDropdown = Utils:Dropdown({
    Title = "Auto Buy Weather",
    Values = { "Storm", "Cloudy", "Snow", "Wind", "Radiant" },
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = function(selected)
        for weatherType, active in pairs(weatherActive) do
            if active and not table.find(selected, weatherType) then
                weatherActive[weatherType] = false
                NotifyWarning("Auto Weather", "Auto buying " .. weatherType .. " has been stopped.")
            end
        end
        for _, weatherType in pairs(selected) do
            if not weatherActive[weatherType] then
                weatherActive[weatherType] = true
                NotifyInfo("Auto Weather", "Auto buying " .. weatherType .. " has started!")
                autoBuyWeather(weatherType)
            end
        end
    end
})

myConfig:Register("WeatherDropdown", WeatherDropdown)


local RodItemsPath = game:GetService("ReplicatedStorage"):WaitForChild("Items")

local BaitsPath = ReplicatedStorage:WaitForChild("Baits")

local lastModifiedRod = nil
local originalRodData = {}

local lastModifiedBait = nil
local originalBaitData = {}

local function deepCopyTable(tbl)
	local copy = {}
	for k, v in pairs(tbl) do
		copy[k] = typeof(v) == "table" and deepCopyTable(v) or v
	end
	return copy
end

local function resetPreviousRod()
	if lastModifiedRod and originalRodData[lastModifiedRod] then
		local rodModule = RodItemsPath:FindFirstChild(lastModifiedRod)
		if rodModule and rodModule:IsA("ModuleScript") then
			local rodData = require(rodModule)
			local originalData = originalRodData[lastModifiedRod]

			for key, value in pairs(originalData) do
				rodData[key] = value
			end
			NotifyWarning("Rod Reset", "Rod '" .. lastModifiedRod .. "' has been reset.", 3)
		end
	end
end

local function modifyRodData(rodNameInput)
	local targetModule = RodItemsPath:FindFirstChild(rodNameInput)
	if not targetModule then
		NotifyError("Rod Not Found", "No rod matched: " .. rodNameInput, 3)
		return
	end

	resetPreviousRod()

	local rodData = require(targetModule)
	if rodData.Data and rodData.Data.Type == "Fishing Rods" then
		originalRodData[rodNameInput] = deepCopyTable(rodData)
		lastModifiedRod = rodNameInput

		if rodData.RollData and rodData.RollData.BaseLuck then
			rodData.RollData.BaseLuck = rodData.RollData.BaseLuck * 1.35
		end
		if rodData.ClickPower then
			rodData.ClickPower = rodData.ClickPower * 1.25
		end
		if rodData.Resilience then
			rodData.Resilience = rodData.Resilience * 1.25
		end
		if typeof(rodData.Windup) == "NumberRange" then
			local newMin = rodData.Windup.Min * 0.50
			local newMax = rodData.Windup.Max * 0.50
			rodData.Windup = NumberRange.new(newMin, newMax)
		end
		if rodData.MaxWeight then
			rodData.MaxWeight = rodData.MaxWeight * 1.25
		end

		NotifySuccess("Rod Modified", "Rod '" .. rodData.Data.Name .. "' successfully boosted.", 3)
	else
		NotifyError("Invalid Rod", "The selected module is not a valid rod.", 3)
	end
end

local function resetPreviousBait()
	if lastModifiedBait and originalBaitData[lastModifiedBait] then
		local bait = BaitsPath:FindFirstChild(lastModifiedBait)
		if bait and bait:IsA("ModuleScript") then
			local baitData = require(bait)
			local originalData = originalBaitData[lastModifiedBait]

			for key, value in pairs(originalData) do
				baitData[key] = value
			end

			NotifyWarning("Bait Reset", "Bait '" .. lastModifiedBait .. "' has been reset.", 3)
		end
	end
end

local function modifyBaitData(baitName)
	local baitModule = BaitsPath:FindFirstChild(baitName)
	if not baitModule then
		NotifyError("Bait Not Found", "No bait matched: " .. baitName, 3)
		return
	end

	resetPreviousBait()

	local baitData = require(baitModule)
	originalBaitData[baitName] = deepCopyTable(baitData)
	lastModifiedBait = baitName

	if baitData.Modifiers and baitData.Modifiers.BaseLuck then
		baitData.Modifiers.BaseLuck = baitData.Modifiers.BaseLuck * 1.4
	end

	NotifySuccess("Bait Modified", "Bait '" .. baitName .. "' successfully boosted.", 3)
end

local rodOptions = {}
local rodNameMap = {}

for _, item in pairs(RodItemsPath:GetChildren()) do
	if item:IsA("ModuleScript") and item.Name:sub(1,3) == "!!!" then
		local displayName = item.Name:gsub("^!!!", "")
		table.insert(rodOptions, displayName)
		rodNameMap[displayName] = item.Name
	end
end

Utils:Dropdown({
	Title = "Rod Modifiers",
	Values = rodOptions,
	Multi = false,
	Callback = function(displayedRodName)
		local actualRodName = rodNameMap[displayedRodName]
		if actualRodName then
			modifyRodData(actualRodName)
		end
	end
})


local baitOptions = {}
for _, bait in pairs(BaitsPath:GetChildren()) do
	if bait:IsA("ModuleScript") then
		table.insert(baitOptions, bait.Name)
	end
end

Utils:Dropdown({
	Title = "Bait Modifier",
	Values = baitOptions,
	Multi = false,
	Callback = function(option)
		modifyBaitData(option)
	end
})

Utils:Button({
	Title = "Reset Last Modified Bait",
	Callback = function()
		if lastModifiedBait then
			resetPreviousBait()
			lastModifiedBait = nil
		else
			NotifyWarning("No Bait", "No bait has been modified yet.", 3)
		end
	end
})

Utils:Button({
	Title = "Reset Last Modified Rod",
	Callback = function()
		if lastModifiedRod then
			resetPreviousRod()
			lastModifiedRod = nil
		else
			NotifyWarning("No Rod", "No rod has been modified yet.", 3)
		end
	end
})

local islandCoords = {
	["01"] = { name = "Weather Machine", position = Vector3.new(-1471, -3, 1929) },
	["02"] = { name = "Esoteric Depths", position = Vector3.new(3157, -1303, 1439) },
	["03"] = { name = "Tropical Grove", position = Vector3.new(-2038, 3, 3650) },
	["04"] = { name = "Stingray Shores", position = Vector3.new(-32, 4, 2773) },
	["05"] = { name = "Kohana Volcano", position = Vector3.new(-519, 24, 189) },
	["06"] = { name = "Coral Reefs", position = Vector3.new(-3095, 1, 2177) },
	["07"] = { name = "Crater Island", position = Vector3.new(968, 1, 4854) },
	["08"] = { name = "Kohana", position = Vector3.new(-658, 3, 719) },
	["09"] = { name = "Winter Fest", position = Vector3.new(1611, 4, 3280) },
	["10"] = { name = "Isoteric Island", position = Vector3.new(1987, 4, 1400) },
	["11"] = { name = "Treasure Hall", position = Vector3.new(-3600, -267, -1558) },
	["12"] = { name = "Lost Shore", position = Vector3.new(-3663, 38, -989 ) },
	["13"] = { name = "Sishypus Statue", position = Vector3.new(-3792, -135, -986) },
	["14"] = { name = "Ancient Jungle", position = Vector3.new(1478, 131, -613) },
	["15"] = { name = "The Temple", position = Vector3.new(1477, -22, -631) },
	["16"] = { name = "Underground Cellar", position = Vector3.new(2133, -91, -674)},
	["17"] = { name = "Ancient Ruin", position = Vector3.new(6052, -546, 4427)},
	["18"] = {name = "Iron Cavern", position = Vector3.new(-8873, -582, 157) },
  ["19"] = {name = "Iron Cafe", position = Vector3.new(-8668, -549, 161) },
  ["20"] = {name = "Classic Island", position = Vector3.new(1259, 10, 2824) }
}

local islandNames = {}
for _, data in pairs(islandCoords) do
    table.insert(islandNames, data.name)
end

Utils:Dropdown({
    Title = "Island Selector",
    Desc = "Select island to teleport",
    Values = islandNames,
    Value = islandNames[1],
    Callback = function(selectedName)
        for code, data in pairs(islandCoords) do
            if data.name == selectedName then
                local success, err = pcall(function()
                    local charFolder = workspace:WaitForChild("Characters", 5)
                    local char = charFolder:FindFirstChild(LocalPlayer.Name)
                    if not char then error("Character not found") end
                    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 3)
                    if not hrp then error("HumanoidRootPart not found") end
                    hrp.CFrame = CFrame.new(data.position + Vector3.new(0, 5, 0))
                end)

                if success then
                    NotifySuccess("Teleported!", "You are now at " .. selectedName)
                else
                    NotifyError("Teleport Failed", tostring(err))
                end
                break
            end
        end
    end
})

local eventsList = { 
    "Shark Hunt", 
    "Ghost Shark Hunt", 
    "Worm Hunt", 
    "Black Hole", 
    "Shocked", 
    "Ghost Worm", 
    "Meteor Rain", 
    "Megalodon Hunt" 
}

Utils:Dropdown({
    Title = "Teleport Event",
    Values = eventsList,
    Value = "Shark Hunt",
    Callback = function(option)
        local props = workspace:FindFirstChild("Props")
        if props and props:FindFirstChild(option) then
            local targetModel
            if option == "Worm Hunt" or option == "Ghost Worm" then
                targetModel = props:FindFirstChild("Model")
            else
                targetModel = props[option]
            end

            if targetModel then
                local pivot = targetModel:GetPivot()
                local hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = pivot + Vector3.new(0, 15, 0)
                    WindUI:Notify({
                        Title = "Event Available!",
                        Content = "Teleported To " .. option,
                        Icon = "circle-check",
                        Duration = 3
                    })
                end
            else
                WindUI:Notify({
                    Title = "Event Not Found",
                    Content = option .. " Not Found!",
                    Icon = "ban",
                    Duration = 3
                })
            end
        else
            WindUI:Notify({
                Title = "Event Not Found",
                Content = option .. " Not Found!",
                Icon = "ban",
                Duration = 3
            })
        end
    end
})

local TweenService = game:GetService("TweenService")

local HRP = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera

local Items = ReplicatedStorage:WaitForChild("Items")
local Baits = ReplicatedStorage:WaitForChild("Baits")
local net = ReplicatedStorage:WaitForChild("Packages")
	:WaitForChild("_Index")
	:WaitForChild("sleitnick_net@0.2.0")
	:WaitForChild("net")


local npcCFrame = CFrame.new(
	66.866745, 4.62500143, 2858.98535,
	-0.981261611, 5.77215005e-08, -0.192680314,
	6.94250204e-08, 1, -5.39889484e-08,
	0.192680314, -6.63541186e-08, -0.981261611
)


local function FadeScreen(duration)
	local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false

	local frame = Instance.new("Frame", gui)
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 0.1

	local tweenIn = TweenService:Create(frame, TweenInfo.new(0.2), { BackgroundTransparency = 0.1 })
	tweenIn:Play()
	tweenIn.Completed:Wait()

	wait(duration)

	local tweenOut = TweenService:Create(frame, TweenInfo.new(0.3), { BackgroundTransparency = 0.1 })
	tweenOut:Play()
	tweenOut.Completed:Wait()
	gui:Destroy()
end

local function SafePurchase(callback)
	local originalCFrame = HRP.CFrame
	HRP.CFrame = npcCFrame
	FadeScreen(0.2)
	pcall(callback)
	wait(0.1)
	HRP.CFrame = originalCFrame
end

local rodOptions = {}
local rodData = {}

for _, rod in ipairs(Items:GetChildren()) do
	if rod:IsA("ModuleScript") and rod.Name:find("!!!") then
		local success, module = pcall(require, rod)
		if success and module and module.Data then
			local id = module.Data.Id
			local name = module.Data.Name or rod.Name
			local price = module.Price or module.Data.Price

			if price then
				table.insert(rodOptions, name .. " | Price: " .. tostring(price))
				rodData[name] = id
			end
		end
	end
end

Utils:Dropdown({
	Title = "Rod Shop",
	Desc = "Select Rod to Buy",
	Values = rodOptions,
	Value = nil,
	Callback = function(option)
		local selectedName = option:split(" |")[1]
		local id = rodData[selectedName]

		SafePurchase(function()
			net:WaitForChild("RF/PurchaseFishingRod"):InvokeServer(id)
			NotifySuccess("Rod Purchased", selectedName .. " has been successfully purchased!")
		end)
	end,
})


local baitOptions = {}
local baitData = {}

for _, bait in ipairs(Baits:GetChildren()) do
	if bait:IsA("ModuleScript") then
		local success, module = pcall(require, bait)
		if success and module and module.Data then
			local id = module.Data.Id
			local name = module.Data.Name or bait.Name
			local price = module.Price or module.Data.Price

			if price then
				table.insert(baitOptions, name .. " | Price: " .. tostring(price))
				baitData[name] = id
			end
		end
	end
end

Utils:Dropdown({
	Title = "Baits Shop",
	Desc = "Select Baits to Buy",
	Values = baitOptions,
	Value = nil,
	Callback = function(option)
		local selectedName = option:split(" |")[1]
		local id = baitData[selectedName]

		SafePurchase(function()
			net:WaitForChild("RF/PurchaseBait"):InvokeServer(id)
			NotifySuccess("Bait Purchased", selectedName .. " has been successfully purchased!")
		end)
	end,
})

local npcFolder = game:GetService("ReplicatedStorage"):WaitForChild("NPC")

local npcList = {}
for _, npc in pairs(npcFolder:GetChildren()) do
	if npc:IsA("Model") then
		local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
		if hrp then
			table.insert(npcList, npc.Name)
		end
	end
end


Utils:Dropdown({
	Title = "NPC",
	Desc = "Select NPC to Teleport",
	Values = npcList,
	Value = nil,
	Callback = function(selectedName)
		local npc = npcFolder:FindFirstChild(selectedName)
		if npc and npc:IsA("Model") then
			local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
			if hrp then
				local charFolder = workspace:FindFirstChild("Characters", 5)
				local char = charFolder and charFolder:FindFirstChild(LocalPlayer.Name)
				if not char then return end
				local myHRP = char:FindFirstChild("HumanoidRootPart")
				if myHRP then
					myHRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
					NotifySuccess("Teleported!", "You are now near: " .. selectedName)
				end
			end
		end
	end
})

-------------------------------------------
----- =======[ FISH NOTIF TAB ]
-------------------------------------------

local LocalPlayer = game:GetService("Players").LocalPlayer
local REObtainedNewFishNotification = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]

local webhookPath = nil
local FishWebhookEnabled = true

FishNotif:Paragraph({
	Title = "Fish Notification",
	Color = "Green",
	Desc = [[
This is a Fish Notification that functions to display fish in the channel server.
You can buy a Key for the custom Channel you want.
Price : 100K IDR
]]
})

local function validateWebhook(path)
	if not path:match("^%d+/.+") then
		return false, "Invalid format"
	end

	local url = "https://discord.com/api/webhooks/" .. path
	local success, response = pcall(function()
		return game:HttpGet(url)
	end)

	if not success then
		return false, "Failed to connect to Discord"
	end

	local ok, data = pcall(function()
		return HttpService:JSONDecode(response)
	end)

	if not ok or not data or not data.channel_id then
		return false, "Invalid"
	end

	return true, data.channel_id
end


FishNotif:Toggle({
    Title = "Fish Notification",
    Desc = "Send fish notifications to Discord",
    Value = true,
    Callback = function(state)
        FishWebhookEnabled = state
    end
})

local FishCategories = {
    ["Secret"] = {
        "Ancient Lochness Monster", "Ancient Whale", "Blob Shark", "Bloodmoon Whale", "Bone Whale",
        "Cryoshade Glider", "Crystal Crab", "Dead Zombie Shark", "Eerie Shark", "Elshark Gran Maja",
        "Frostborn Shark", "Ghost Shark", "Ghost Worm Fish", "Giant Squid", "Gladiator Shark",
        "Great Christmas Whale", "Great Whale", "King Jelly", "Lochness Monster", "Megalodon",
        "Monster Shark", "Mosasaur Shark", "Orca", "Queen Crab", "Robot Kraken", "Scare",
        "Skeleton Narwhal", "Talon Serpent", "Thin Armor Shark", "Wild Serpent", "Worm Fish",
        "Zombie Megalodon", "Zombie Shark"
    },

    ["Mythic"] = {
        "Ancient Relic Crocodile", "Ancient Squid", "Armor Catfish", "Blob Fish", "Cavern Dweller",
        "Crocodile", "Dark Pumpkin Appafish", "Flatheaded Whale Shark", "Fossilized Shark",
        "Frankenstein Longsnapper", "Gingerbread Shark", "Hammerhead Mummy",
        "Hybodus Shark", "King Crab", "Loving Shark", "Luminous Fish", "Magma Shark",
        "Mammoth Appafish", "Panther Eel", "Plasma Serpent", "Primordial Octopus",
        "Pumpkin Ray", "Runic Sea Crustacean", "Runic Squid", "Sea Crustacean",
        "Sharp One", "Starlight Manta Ray"
    },

    ["Legendary"] = {
        "Abyss Seahorse", "Ancient Pufferfish", "Blueflame Ray", "Crystal Salamander",
        "Deep Sea Crab", "Diamond Ring", "Dotted Stingray", "Fish Fossil", "Flying Manta",
        "Ghastly Crab", "Ghastly Hermit Crab", "Gingerbread Turtle", "Hammerhead Shark",
        "Hawks Turtle", "Lake Sturgeon", "Lined Cardinal Fish", "Loggerhead Turtle",
        "Manoai Statue Fish", "Manta Ray", "Plasma Shark", "Primal Axolotl",
        "Primal Lobster", "Prismy Seahorse", "Pumpkin Carved Shark", "Pumpkin Jellyfish",
        "Pumpkin StoneTurtle", "Ruby", "Runic Axolotl", "Runic Lobster",
        "Sacred Guardian Squid", "Saw Fish", "Strippled Seahorse", "Synodontis",
        "Temple Spokes Tuna", "Thresher Shark", "Wizard Stingray"
    },
}


local FishDataById = {}
for _, item in pairs(ReplicatedStorage.Items:GetChildren()) do
	local ok, data = pcall(require, item)
	if ok and data.Data and data.Data.Type == "Fish" then
		FishDataById[data.Data.Id] = {
			Name = data.Data.Name,
			SellPrice = data.SellPrice or 0
		}
	end
end


local VariantsByName = {}
for _, v in pairs(ReplicatedStorage.Variants:GetChildren()) do
	local ok, data = pcall(require, v)
	if ok and data.Data and data.Data.Type == "Variant" then
		VariantsByName[data.Data.Name] = data.SellMultiplier or 1
	end
end


local SelectedCategories = {"Secret", "Mythic"}

FishNotif:Button({
    Title = "Test Webhook",
    Description = "Trigger Test Fish Notification",
    Callback = function()
        local randomWeight = math.random(20000, 25000)

        firesignal(REObtainedNewFishNotification.OnClientEvent, 
            218,
            {
                Weight = randomWeight
            },
            {
                CustomDuration = 5,
                Type = "Item",
                ItemType = "Fishes",
                _newlyIndexed = false,
                InventoryItem = {
                    Id = 218,
                    Favorited = false,
                    UUID = game:GetService("HttpService"):GenerateGUID(false),
                    Metadata = {
                        Weight = randomWeight
                    }
                },
                ItemId = 218
            },
            false
        )
    end
})

-- Check target fish
local function isTargetFish(fishName)
	for _, category in pairs(SelectedCategories) do
		local list = FishCategories[category]
		if list then
			for _, keyword in pairs(list) do
				if string.find(string.lower(fishName), string.lower(keyword)) then
					return true
				end
			end
		end
	end
	return false
end

-- Roblox image fetcher
local function GetRobloxImage(assetId)
	local url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. assetId .. "&size=420x420&format=Png&isCircular=false"
	local success, response = pcall(game.HttpGet, game, url)
	if success then
		local data = HttpService:JSONDecode(response)
		if data and data.data and data.data[1] and data.data[1].imageUrl then
			return data.data[1].imageUrl
		end
	end
	return nil
end

-- Send Webhook
local function sendFishWebhook(fishName, rarityText, assetId, itemId, variantId)

	local WebhookURL = "https://discord.com/api/webhooks/1415211763091247155/oPwylc3-SPn35TcC7mZKmFPnbGSqGa6xOqRAD2FMkBOLb0PbGRpkfcT_jgF6kS0gNMpX"
	local username = LocalPlayer.DisplayName
	local imageUrl = "https://i.imgur.com/placeholder.png" -- Default placeholder

    task.spawn(function()
        local fetchedImage = GetRobloxImage(assetId)
        if fetchedImage then
            imageUrl = fetchedImage
        end
    end)
    
    -- Wait maksimal 2 detik untuk gambar
    local waitStart = tick()
    while imageUrl == "https://i.imgur.com/placeholder.png" and (tick() - waitStart) < 2 do
        task.wait(0.1)
    end

	-- Leaderstats
	local caught = LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Caught")
	local rarest = LocalPlayer.leaderstats and LocalPlayer.leaderstats:FindFirstChild("Rarest Fish")

	-- Sell Price calculation
	local basePrice = 0
	if itemId and FishDataById[itemId] then
		basePrice = FishDataById[itemId].SellPrice
	end

	if variantId and VariantsByName[variantId] then
		basePrice = basePrice * VariantsByName[variantId]
	end

	local embedDesc = string.format([[
Hei **%s**! 🎣
You have successfully caught a fish.

====| FISH DATA |====
🧾 Name : **%s**
🌟 Rarity : **%s**
💰 Sell Price : **%s**

====| ACCOUNT DATA |====
🎯 Total Caught : **%s**
🏆 Rarest Fish : **%s**
]],
		username,
		fishName,
		rarityText,
		tostring(basePrice),
		caught and caught.Value or "N/A",
		rarest and rarest.Value or "N/A"
	)

	local data = {
		["username"] = "QuietXHub",
		["embeds"] = {{
			["title"] = "Fish Caught!",
			["description"] = embedDesc,
			["color"] = tonumber("0x00bfff"),
			["image"] = { ["url"] = imageUrl },
			["footer"] = { ["text"] = "Fish Notification • " .. os.date("%d %B %Y, %H:%M:%S") }
		}}
	}

	local requestFunc = syn and syn.request or http and http.request or http_request or request or fluxus and fluxus.request
	if requestFunc then
		requestFunc({
			Url = WebhookURL,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(data)
		})
	else
		warn("HttpRequest tidak tersedia di executor ini.")
	end
end

-- Save last catch info from Event
local LastCatchData = {}

local REObtainedNewFishNotification = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, metadata)
	LastCatchData.ItemId = itemId
	LastCatchData.VariantId = metadata and metadata.VariantId
end)

-- GUI Detection (Trigger)
local function startFishDetection()
    local plr = LocalPlayer
    local guiNotif = plr.PlayerGui:WaitForChild("Small Notification", 10)
    if not guiNotif then
        warn("Small Notification GUI not found.")
        return
    end

    local displayContainer = guiNotif:FindFirstChild("Display") and guiNotif.Display:FindFirstChild("Container")
    if not displayContainer then
        warn("Notification Container not found.")
        return
    end

    local fishText = displayContainer:FindFirstChild("ItemName")
    local rarityText = displayContainer:FindFirstChild("Rarity")
    local imageFrame = guiNotif:FindFirstChild("Display") and
    guiNotif.Display:FindFirstChild("VectorFrame"):FindFirstChild("Vector")

    if not (fishText and rarityText and imageFrame) then
        warn("Required notification components not found.")
        return
    end

    -- ============================================
    -- PERBAIKAN: VALIDASI GANDA (ID + NAMA)
    -- ============================================
    fishText:GetPropertyChangedSignal("Text"):Connect(function()
        local fishName = fishText.Text
        local currentItemId = LastCatchData.ItemId
        local currentVariantId = LastCatchData.VariantId
        
        -- VALIDASI 1: Pastikan ItemId ada
        if not currentItemId then
            warn("⚠️ ItemId tidak ditemukan, skip webhook.")
            return
        end
        
        -- VALIDASI 2: Cek apakah Tier sesuai filter
        if not isTargetTier(currentItemId) then
            -- Debug (hapus nanti)
            -- print("⚠️ Ikan tidak masuk filter tier:", fishName, "| ID:", currentItemId)
            return
        end
        
        -- VALIDASI 3: Cross-check Nama dengan ItemId
        local expectedFishData = FishDataById[currentItemId]
        if expectedFishData then
            local expectedName = expectedFishData.Name
            
            -- Jika ada variant, nama bisa beda (contoh: "Megalodon" vs "Megalodon Lightning")
            -- Kita cek apakah nama UI MENGANDUNG nama base fish
            if not string.find(fishName, expectedName) then
                warn("⚠️ MISMATCH! UI Name:", fishName, "| Expected:", expectedName)
                warn("   Kemungkinan ItemId dari catch sebelumnya (race condition)")
                return -- SKIP webhook karena data tidak match
            end
        end
        
        -- VALIDASI 4: Ambil asset ID dari gambar
        local assetId = string.match(imageFrame.Image, "%d+")
        if not assetId then
            warn("❌ Asset ID tidak ditemukan dari imageFrame!")
            return
        end
        
        -- SEMUA VALIDASI PASS - KIRIM WEBHOOK
        local rarity = rarityText.Text
        
        print("✅ Webhook triggered for:", fishName, "| ID:", currentItemId, "| Tier:", _G.FishTierById[currentItemId])
        
        sendFishWebhook(fishName, rarity, assetId, currentItemId, currentVariantId)
    end)
end

startFishDetection()



-------------------------------------------
----- =======[ SETTINGS TAB ]
-------------------------------------------

local RunService = game:GetService("RunService")

function _G.Disable3DRendering(enabled)
	if enabled then
		RunService:Set3dRenderingEnabled(false)
	else
		RunService:Set3dRenderingEnabled(true)
	end
end

SettingsTab:Toggle({
    Title = "Disable 3D Rendering",
    Value = false,
    Callback = function(state)
        _G.Disable3DRendering(state)
    end
})

SettingsTab:Button({
	Title = "Boost FPS (Maximize Performance)",
	Callback = function()
		for _, v in pairs(game:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Material = Enum.Material.SmoothPlastic
				v.Reflectance = 0
			elseif v:IsA("Decal") or v:IsA("Texture") then
				v.Transparency = 1
			end
		end

		local Lighting = game:GetService("Lighting")
		for _, effect in pairs(Lighting:GetChildren()) do
			if effect:IsA("PostEffect") then
				effect.Enabled = false
			end
		end

		Lighting.GlobalShadows = false
		Lighting.FogEnd = 1e10

		settings().Rendering.QualityLevel = "Level01"
	end
})

SettingsTab:Button({
	Title = "HDR Shader",
	Callback = function()
		loadstring(game:HttpGet("https://paste.monster/IVE9Xt3YJWkp/raw/"))()
	end,
})

local TeleportService = game:GetService("TeleportService")

local function Rejoin()
	local player = Players.LocalPlayer
	if player then
		TeleportService:Teleport(game.PlaceId, player)
	end
end

local function ServerHop()
	local placeId = game.PlaceId
	local servers = {}
	local cursor = ""
	local found = false

	repeat
		local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
		if cursor ~= "" then
			url = url .. "&cursor=" .. cursor
		end

		local success, result = pcall(function()
			return HttpService:JSONDecode(game:HttpGet(url))
		end)

		if success and result and result.data then
			for _, server in pairs(result.data) do
				if server.playing < server.maxPlayers and server.id ~= game.JobId then
					table.insert(servers, server.id)
				end
			end
			cursor = result.nextPageCursor or ""
		else
			break
		end
	until not cursor or #servers > 0

	if #servers > 0 then
		local targetServer = servers[math.random(1, #servers)]
		TeleportService:TeleportToPlaceInstance(placeId, targetServer, LocalPlayer)
	else
		NotifyError("Server Hop Failed", "No servers available or all are full!")
	end
end

local Keybind = SettingsTab:Keybind({
    Title = "Keybind",
    Desc = "Keybind to open UI",
    Value = "G",
    Callback = function(v)
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})

myConfig:Register("Keybind", Keybind)

SettingsTab:Button({
	Title = "Rejoin Server",
	Callback = function()
		Rejoin()
	end,
})

SettingsTab:Button({
	Title = "Server Hop (New Server)",
	Callback = function()
		ServerHop()
	end,
})


SettingsTab:Button({
    Title = "Save",
    Desc = "Save Settings to config",
    Callback = function()
        myConfig:Save()
        NotifySuccess("Config Saved", "Config has been saved!")
    end
})

SettingsTab:Button({
    Title = "Load",
    Desc = "Loads Settings from config",
    Callback = function()
        myConfig:Load()
        NotifySuccess("Config Loaded", "Config has beed loaded!")
    end
})