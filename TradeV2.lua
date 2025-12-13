local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local net = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")
local VirtualUser = game:GetService("VirtualUser")

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

local inventoryCache = {}
local fullInventoryDropdownList = {}

-- Asumsi Modul game inti sudah tersedia (seperti Replion)
local ItemUtility = _G.ItemUtility or require(ReplicatedStorage.Shared.ItemUtility) 
local ItemStringUtility = _G.ItemStringUtility or require(ReplicatedStorage.Modules.ItemStringUtility)
local InitiateTrade = net:WaitForChild("RF/InitiateTrade") 
local RFAwaitTradeResponse = net:WaitForChild("RF/AwaitTradeResponse") 

function _G.TradeLogSummary(successCount, failCount)
    -- Get local player username (sender)
    local username = LocalPlayer.Name
    local folderPath = "Trade"
    local filePath = folderPath .. "/" .. username .. ".json"
    
    -- Create Trade folder if it doesn't exist
    if not isfolder(folderPath) then
        makefolder(folderPath)
    end
    
    -- Build JSON entry
    local entry = {
        timestamp = os.time(),
        success = successCount,
        failed = failCount
    }
    
    -- Write (replace) file with new data
    writefile(filePath, HttpService:JSONEncode(entry))
end

function _G.IsTierAllowed(tierId)
    if not _G.TRADE_TIER_FILTER or #_G.TRADE_TIER_FILTER == 0 then
        return true
    end

    -- JIKA TIER TIDAK ADA, JANGAN BLOK
    if not tierId then
        return true
    end

    for _, allowed in ipairs(_G.TRADE_TIER_FILTER) do
        if tierId == allowed then
            return true
        end
    end

    return false
end

function _G.IsItemAllowed(itemData, baseItemData)
    local tierMatch = _G.IsTierAllowed(baseItemData.Data.Tier)
    local nameMatch = _G.IsFishNameAllowed(itemData, baseItemData)

    -- LOGIKA OR
    return tierMatch or nameMatch
end

function _G.IsFishNameAllowed(itemData, baseItemData)
    if type(_G.TRADE_FISH_NAME_FILTER) ~= "table" or #_G.TRADE_FISH_NAME_FILTER == 0 then
        return true
    end

    if not _G.ItemStringUtility or type(_G.ItemStringUtility.GetItemName) ~= "function" then
        return false
    end

    local itemName
    local ok = pcall(function()
        itemName = _G.ItemStringUtility.GetItemName(itemData, baseItemData)
    end)

    if not ok or type(itemName) ~= "string" then
        return false
    end

    itemName = string.lower(itemName)

    for _, allowedName in ipairs(_G.TRADE_FISH_NAME_FILTER) do
        if type(allowedName) == "string" then
            if itemName == string.lower(allowedName) then
                return true
            end
        end
    end

    -- ❗ FILTER ADA TAPI TIDAK MATCH → BLOCK
    return false
end

function _G.ResolveUsername(username)
    for _, plr in ipairs(Players:GetPlayers()) do
        if string.lower(plr.Name) == string.lower(username) then
            return plr.UserId, plr
        end
    end
    return nil, nil
end

function _G.GetTradeUUIDs()
    local DataReplion = _G.Replion.Client:WaitReplion("Data")
    if not DataReplion then
        warn("[AUTO TRADE] DataReplion missing")
        return {}
    end

    -- FORCE REFRESH SNAPSHOT
    local items = DataReplion:Get({ "Inventory", "Items" })
    if not items then
        warn("[AUTO TRADE] Inventory empty")
        return {}
    end

    local result = {}
    local scanned = 0
    local skipped = 0

    for _, item in ipairs(items) do
        scanned += 1

        -- UUID VALIDASI
        if not item.UUID then
            skipped += 1
            continue
        end

        local base = _G.ItemUtility:GetItemData(item.Id)
        if not base or not base.Data then
            skipped += 1
            continue
        end

        if base.Data.Type ~= "Fish" then
            skipped += 1
            continue
        end

        if not _G.IsItemAllowed(item, base) then
            skipped += 1
            continue
        end

        table.insert(result, item.UUID)
    end

    warn(string.format(
        "[AUTO TRADE] Scan=%d | Valid=%d | Skipped=%d",
        scanned, #result, skipped
    ))

    return result
end


function _G.TeleportToTarget(targetPlayer)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 3)

    local tChar = targetPlayer.Character or targetPlayer.CharacterAdded:Wait()
    local tHrp = tChar:WaitForChild("HumanoidRootPart", 3)

    if not hrp or not tHrp then return end

    hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, -4)
end


if not _G.__TRADE_ENGINE_RUNNING then
    _G.__TRADE_ENGINE_RUNNING = true

    task.spawn(function()
        while true do
            task.wait(1)

            if _G.TRADE_ACTIVE and not _G.__TRADE_IN_PROGRESS then
                _G.__TRADE_IN_PROGRESS = true

                local ok, err = pcall(function()
                    _G.StartAutoTradeV3()
                end)

                if not ok then
                    warn("[AUTO TRADE ERROR]", err)
                    _G.TRADE_ACTIVE = false
                end
            end
        end
    end)
end

-- Implementasi Auto Accept Trade
pcall(function()
    local PromptController = _G.PromptController or ReplicatedStorage:WaitForChild("Controllers").PromptController 
    local Promise = _G.Promise or require(ReplicatedStorage.Packages.Promise) 
    
    if PromptController and PromptController.FirePrompt then
        local oldFirePrompt = PromptController.FirePrompt
        PromptController.FirePrompt = function(self, promptText, ...)
            -- Cek apakah Auto Accept aktif dan prompt adalah Trade
            if _G.TRADE_AUTO_ACCEPT and type(promptText) == "string" and promptText:find("Accept") and promptText:find("from:") then
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


function _G.StartAutoTradeV3()
    if not _G.TRADE_ACTIVE then return end

    local successCount = 0
    local failCount = 0

    -- VALIDASI TARGET
    if not _G.TRADE_TARGET_USERNAME then
        _G.TRADE_ACTIVE = false
        _G.__TRADE_IN_PROGRESS = false
        return
    end

    local userId, targetPlayer = _G.ResolveUsername(_G.TRADE_TARGET_USERNAME)
    if not userId or not targetPlayer then
        _G.TRADE_ACTIVE = false
        _G.__TRADE_IN_PROGRESS = false
        return
    end

    _G.TeleportToTarget(targetPlayer)
    task.wait(1)

    local uuids = _G.GetTradeUUIDs()
    if #uuids == 0 then
        -- LOG WALAU KOSONG
        _G.TradeLogSummary(0, 0)
        _G.TRADE_ACTIVE = false
        _G.__TRADE_IN_PROGRESS = false
        return
    end

    local amount = (_G.TRADE_AMOUNT == 0)
        and #uuids
        or math.min(#uuids, _G.TRADE_AMOUNT)

    for i = 1, amount do
        if not _G.TRADE_ACTIVE then break end

        local ok, res = pcall(function()
            return InitiateTrade:InvokeServer(userId, uuids[i])
        end)

        if ok and res then
            successCount += 1
        else
            failCount += 1
        end

        task.wait(5)
    end

    -- LOG FINAL (SATU BARIS)
    _G.TradeLogSummary(successCount, failCount)

    _G.TRADE_ACTIVE = false
    _G.__TRADE_IN_PROGRESS = false
end