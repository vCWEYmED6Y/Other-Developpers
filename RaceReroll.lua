--// Varialbes \\--
local HTTP = syn and syn.request or http_request or request or HttpPost
local httpService = game:GetService("HttpService")
local players = game:GetService("Players")
local sGui = game:GetService("StarterGui")
local ts = game:GetService("TeleportService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local p = players.LocalPlayer

if not p.Character then 
    p.CharacterAdded:Wait()
end 

local remotes = replicatedStorage:WaitForChild("Remotes")
local inventoryRemote = remotes:WaitForChild("Information"):WaitForChild("InventoryManage")
local updateHotbar = remotes:WaitForChild("Data"):WaitForChild("UpdateHotbar")

local _settings = _G.Settings
local WebhookURL = "https://ptb.discord.com/api/webhooks/1224143348160270346/_9c3FXdQCTCwgTl2hapMZnksMgxomQgxbymGqynjGUfR8ny1gGAsoi7_y9UaCjFzfi9p"

local Headers = {
    ['Content-Type'] = 'application/json',
}

local sendDebounce = 0

--// Functions \\--
local function assignSeparateThread(func)
    task.spawn(func)
end 
local function checkValidItem(itemName)
    local inventory = p.Backpack:WaitForChild("Tools")
    local itemExists = inventory:WaitForChild(itemName, 5)
    
    return itemExists ~= nil, itemExists 
end
local function selectAnswer(parent, action)
    for _, v in pairs(parent:GetChildren()) do 
        if v.Name == "Option" then 
            if v.Text == action then
                return v 
            end 
        end 
    end 
    return false
end 
local function sendWebhookMessage(title, message, color)
    if tick()-sendDebounce <= 1 then 
        return 
    end 
    sendDebounce = tick()
    local data = {
        ["embeds"] = {
            {
                ["title"] = "Arcane Lineage :: Race Reroll Logs",
                ["description"] = title,
                ["type"] = "rich",
                ["color"] = 16711680,
                ["fields"] = {
                    {
                        ["name"] = "Username:",
                        ["value"] = p.Name .. " (" .. p.UserId .. ")",
                        ["inline"] = true,
                    },
                    {
                        ["name"] = "CONTENT",
                        ["value"] = message,
                        ["inline"] = true,
                    },
                },
            },
        },
    }
    
    local PlayerData = httpService:JSONEncode(data)
    local RequestData = {
        Url = WebhookURL,
        Method = "POST",
        Headers = Headers,
        Body = PlayerData,
    }

    local success, response = pcall(HTTP, RequestData)
end 

--// Automatically get player race \\--
local CurrentRace
while task.wait() do 
    local success, result = pcall(function()
        return p.PlayerGui.StatMenu.Holder.ContentFrame.Equipment.Body.LeftColumn.Content.Race.Type.Text
    end) 

    if not success then 
        return 
    end 
    CurrentRace = result

    break
end 

sGui:SetCore("SendNotification", {
    Title = "Race Detector";
    Text = ("Current Race: ".. CurrentRace);
    Duration = 1
})

--// Races \--
local WantedRaces = _settings.WantedRaces
Unidentified = "None" -- Dont touch this

sGui:SetCore("SendNotification", {
    Title = "Race Detector";
    Text = ("Got Settings! ShardWait is set to ".. _settings.ShardWait.. "s. Player wants the following races: ".. table.concat(WantedRaces," "));
    Duration = 4
})
assignSeparateThread(function()
    for _, v in pairs(WantedRaces) do 
        sGui:SetCore("SendNotification", {
    Title = "RACES THAT ARE BEING LOGGED";
    Text = v
    Duration = 10
        })
    end 
end)

--// Script \--
local breaker = false 
local startRoll = false 
assignSeparateThread(function()
    sGui:SetCore("SendNotification", {
        Title = "Race Detector";
        Text = ("Roll-back is Set and Ready!");
        Duration = 5
    })
    while task.wait() do
        local success, errorOrRaceType = pcall(function()
            return p.PlayerGui.StatMenu.Holder.ContentFrame.Equipment.Body.LeftColumn.Content.Race.Type.Text
        end)

        if success then
            local raceType = errorOrRaceType
            local isWanted = WantedRaces[raceType]

            if isWanted or raceType == "Dullahan" then -- Race is "None"
                sGui:SetCore("SendNotification", {
                    Title = "Race Detector";
                    Text = ("Got race: ".. CurrentRace);
                    Duration = 5
                })
                breaker = true 
                assignSeparateThread(function()
                    sendWebhookMessage("Player got something good!", ("Was "..CurrentRace .." | Got "..raceType), 32768)
                end)
                
                return 
            end
            if raceType == CurrentRace then -- Race is your current race
                 
            elseif raceType == Unidentified then -- You got the race you wanted! yippie!

            else
                assignSeparateThread(function()
                    sendWebhookMessage("Player got something bad...", ("Was "..CurrentRace .." | Got "..raceType), 16711680)
                end)
                ts:Teleport(game.PlaceId, p) -- Should only get to that point if none of the checks went through

                return
            end
        else
            warn("Error occurred:", errorOrRaceType)
        end
    end
end)
task.wait(.5)
local result, lineageShard = checkValidItem("Lineage Shard")
if not result then 
    sGui:SetCore("SendNotification", {
        Title = "Race Detector";
        Text = ("Error! You don't own a lineage shard!");
        Duration = 2
    })
    return
end 

task.wait(1)
assignSeparateThread(function()
    while task.wait() do 
        for i = 1,2 do 
            updateHotbar:FireServer({["1"] = "\255"})
        end 
        if breaker then 
            sGui:SetCore("SendNotification", {
                Title = "Race Detector";
                Text = ("Data rollback was disabled, wait before leaving.");
                Duration = 5
            })
            break 
        end 
    end 
end)
sGui:SetCore("SendNotification", {
    Title = "Race Detector";
    Text = ("Rollback was initiated. Using lineage shard...");
    Duration = 1
})
task.wait(ShardWait)
inventoryRemote:FireServer("Use", "Lineage Shard", lineageShard)
task.wait(1)
local dialogueRemote = p.PlayerGui:WaitForChild("NPCDialogue"):WaitForChild("RemoteEvent")
local trueAnswer = selectAnswer(p.PlayerGui:WaitForChild("NPCDialogue"):WaitForChild("BG"):WaitForChild("Options"), "Yes, my resolve is unwavering.")
task.wait(.5)
sGui:SetCore("SendNotification", {
    Title = "Race Detector";
    Text = ("Got answer! Selecting...");
    Duration = 1
})
dialogueRemote:FireServer(trueAnswer)
