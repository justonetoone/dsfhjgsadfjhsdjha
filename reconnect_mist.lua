--[[
    Reconnect Mist - WebSocket Heartbeat Script
    For Mist Rejoin - Online/Offline status monitoring via WebSocket
    
    Features:
    - Key verification with security_token binding
    - WebSocket heartbeat for online status (real-time)
    - Auto-reconnect on disconnect
    - Minimal overhead (no UI, just heartbeat)
    
    ============ USAGE ============
    Configure before loading:
    
    getgenv().ReconnectKey = "YOUR_32_CHARACTER_KEY_HERE"
    loadstring(...)()
    ===============================
]]

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- ============================================================================
-- HARDCODED CONFIGURATION (Obfuscate with Luraph)
-- ============================================================================
local WEBSOCKET_URL = "wss://mist.reconnect-tool.com/ws"
local WS_API_KEY = "mist_k7X9vP2nL4qR8wE1cY6uA3dF0hJ5mT9sB2xZ4nQ7pW1rK8yU6gC3eI0oM5tN2vD"

-- API Configuration (for key verification to get security_token)
local KEY_API_URL = "https://services.reconnect-tool.com/v2/script-key/verify-websocket"
local KEY_API_KEY = "Pvv00JGyLpJXaEDvNJpQXVPYt5mL1jR4nLPSEduESqo"

-- Timing Configuration
local HEARTBEAT_INTERVAL = 30  -- seconds
local RECONNECT_DELAY = 5      -- seconds
local MAX_INACTIVITY = 90      -- seconds

-- State
local socket = nil
local connected = false
local lastMessageTime = os.time()
local stopHeartbeat = false
local verified = false
local securityToken = nil  -- From /verify-websocket endpoint

-- Get local player info
local LP = Players.LocalPlayer
local username = LP and LP.Name or "Unknown"

-- ============================================================================
-- HWID FUNCTIONS
-- ============================================================================

local function getHWID()
    local hwid = nil
    
    -- Method 1: gethwid
    if gethwid then
        pcall(function() hwid = gethwid() end)
        if hwid then return hwid end
    end
    
    -- Method 2: get_hwid
    if get_hwid then
        pcall(function() hwid = get_hwid() end)
        if hwid then return hwid end
    end
    
    -- Method 3: getHWID
    if getHWID then
        pcall(function() hwid = getHWID() end)
        if hwid then return hwid end
    end
    
    -- Method 4: HWID global
    if HWID then
        return HWID
    end
    
    -- Method 5: identifyexecutor + fallback
    if identifyexecutor then
        local executor = identifyexecutor()
        if executor == "Delta" and Delta and Delta.HWID then
            return Delta.HWID
        end
    end
    
    return "HWID_NOT_AVAILABLE"
end

local SCRIPT_HWID = getHWID()
print("[Mist] HWID: " .. SCRIPT_HWID)

-- ============================================================================
-- CONFIG FUNCTIONS
-- ============================================================================

local function getScriptKey()
    if getgenv and getgenv().ReconnectKey then
        return getgenv().ReconnectKey
    end
    if getgenv and getgenv().ReconnectConfig and getgenv().ReconnectConfig.Key then
        return getgenv().ReconnectConfig.Key
    end
    return nil
end

-- ============================================================================
-- KEY VERIFICATION (Returns security_token for WebSocket)
-- ============================================================================

local function verifyKey(key, hwid)
    print("[Mist] Verifying key...")
    
    local httpRequest = request or http_request or (http and http.request) or (syn and syn.request) or (fluxus and fluxus.request)
    
    if not httpRequest then
        warn("[Mist] HTTP request function not available!")
        return false, nil, "HTTP not supported"
    end
    
    local success, response = pcall(function()
        return httpRequest({
            Url = KEY_API_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["X-API-Key"] = KEY_API_KEY
            },
            Body = HttpService:JSONEncode({
                key = key,
                hwid = hwid
            })
        })
    end)
    
    if not success then
        warn("[Mist] Key verification request failed: " .. tostring(response))
        return false, nil, "Request failed"
    end
    
    if response.StatusCode == 200 then
        local responseData = HttpService:JSONDecode(response.Body)
        if responseData.success then
            local token = responseData.security_token
            print("[Mist] ✓ Key verified! Got security_token")
            return true, token, "Valid"
        end
    elseif response.StatusCode == 401 then
        return false, nil, "Invalid key"
    elseif response.StatusCode == 403 then
        local responseData = HttpService:JSONDecode(response.Body)
        return false, nil, responseData.detail or "Access denied"
    elseif response.StatusCode == 429 then
        return false, nil, "Rate limited"
    end
    
    return false, nil, "Server error"
end

local function kickPlayer(reason)
    warn("[Mist] KICKING: " .. reason)
    local player = Players.LocalPlayer
    if player then
        pcall(function() player:Kick(reason) end)
        task.delay(0.5, function()
            pcall(function() TeleportService:Teleport(0, player) end)
        end)
    end
end

-- ============================================================================
-- WEBSOCKET CONNECTION
-- ============================================================================

local function connectWebSocket()
    if socket then
        pcall(function() socket:Close() end)
        socket = nil
    end
    
    if not securityToken then
        warn("[Mist] No security_token! Call verifyKey first.")
        return
    end
    
    -- Build connection URL: type=lua + apiKey + token (security_token)
    local connectUrl = WEBSOCKET_URL .. "?type=lua&apiKey=" .. WS_API_KEY .. "&token=" .. securityToken
    
    local success, err = pcall(function()
        socket = WebSocket.connect(connectUrl)
        connected = true
        lastMessageTime = os.time()
        
        print("[Mist] Connected to WebSocket server")
        
        -- Register with username
        socket:Send(HttpService:JSONEncode({
            type = "register",
            username = username
        }))
        
        -- Message handler
        socket.OnMessage:Connect(function(message)
            lastMessageTime = os.time()
            
            local decodeSuccess, data = pcall(function()
                return HttpService:JSONDecode(message)
            end)
            
            if decodeSuccess and data then
                if data.type == "connected" then
                    print("[Mist] ✓ Connected: " .. tostring(data.message))
                elseif data.type == "registered" then
                    print("[Mist] ✓ Registered as: " .. tostring(data.username))
                elseif data.type == "heartbeat_ack" then
                    -- Heartbeat acknowledged silently
                elseif data.type == "error" then
                    warn("[Mist] Server error: " .. tostring(data.message))
                    if data.message and (data.message:find("Invalid API key") or data.message:find("Client app must connect first")) then
                        stopHeartbeat = true
                        kickPlayer(data.message)
                    end
                end
            end
        end)
        
        -- Close handler
        socket.OnClose:Connect(function()
            connected = false
            print("[Mist] Connection closed")
            
            if not stopHeartbeat then
                warn("[Mist] Reconnecting in " .. RECONNECT_DELAY .. "s...")
                task.wait(RECONNECT_DELAY)
                connectWebSocket()
            end
        end)
    end)
    
    if not success then
        warn("[Mist] Connection failed: " .. tostring(err))
        connected = false
        
        if not stopHeartbeat then
            task.wait(RECONNECT_DELAY)
            connectWebSocket()
        end
    end
end

-- ============================================================================
-- HEARTBEAT
-- ============================================================================

local function sendHeartbeat()
    if not connected or not socket then return end
    
    -- Force reconnect if server inactive
    if os.time() - lastMessageTime > MAX_INACTIVITY then
        warn("[Mist] Server inactive, reconnecting...")
        connectWebSocket()
        return
    end
    
    local success, err = pcall(function()
        socket:Send(HttpService:JSONEncode({
            type = "heartbeat",
            username = username
        }))
    end)
    
    if not success then
        warn("[Mist] Heartbeat failed: " .. tostring(err))
        connected = false
        connectWebSocket()
    end
end

-- ============================================================================
-- MAIN EXECUTION
-- ============================================================================

local function main()
    -- Wait for game to load
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    repeat task.wait() until Players.LocalPlayer and Players.LocalPlayer.Character
    task.wait(1)
    
    -- Update username after player loads
    LP = Players.LocalPlayer
    username = LP and LP.Name or "Unknown"
    
    print("[Mist] =========================================")
    print("[Mist] Reconnect Mist - WebSocket Heartbeat v3")
    print("[Mist] Username: " .. username)
    print("[Mist] HWID: " .. SCRIPT_HWID)
    print("[Mist] =========================================")
    
    -- Get script key from config
    local SCRIPT_KEY = getScriptKey()
    
    -- Validate key
    if not SCRIPT_KEY or SCRIPT_KEY == "" then
        warn("[Mist] ERROR: No script key provided!")
        warn("[Mist] Set: getgenv().ReconnectKey = 'YOUR_KEY'")
        kickPlayer("No script key provided")
        return
    end
    
    if #SCRIPT_KEY ~= 32 then
        warn("[Mist] ERROR: Invalid key format (must be 32 chars)")
        kickPlayer("Invalid key format")
        return
    end
    
    -- Verify key and get security_token
    local keyValid, token, keyMessage = verifyKey(SCRIPT_KEY, SCRIPT_HWID)
    
    if not keyValid then
        warn("[Mist] Key verification failed: " .. keyMessage)
        kickPlayer("Key verification failed: " .. keyMessage)
        return
    end
    
    securityToken = token
    verified = true
    print("[Mist] ✓ Key verified! Got security_token")
    
    -- Connect to WebSocket
    print("[Mist] Connecting to WebSocket server...")
    connectWebSocket()
    
    -- Heartbeat loop
    while not stopHeartbeat do
        if connected then
            sendHeartbeat()
        else
            connectWebSocket()
        end
        task.wait(HEARTBEAT_INTERVAL)
    end
    
    -- Cleanup
    if connected and socket then
        pcall(function()
            socket:Send(HttpService:JSONEncode({
                type = "disconnect"
            }))
            socket:Close()
        end)
    end
    
    print("[Mist] Stopped")
end

-- Run
local success, err = pcall(main)
if not success then
    warn("[Mist] Error: " .. tostring(err))
end

-- Return control functions
return {
    stop = function()
        stopHeartbeat = true
        if socket then
            pcall(function() socket:Close() end)
        end
    end,
    isConnected = function()
        return connected
    end,
    isVerified = function()
        return verified
    end,
    getUsername = function()
        return username
    end
}
