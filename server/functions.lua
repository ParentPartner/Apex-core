local oxmysql = exports['oxmysql']
local json = require('json')
local banFilePath = './resources/Apex/Config/ban.json'
local kickFilePath = './resources/Apex/Config/kick.json'

Apex = {}
Apex.Functions = {}

-- Function to read bans from the JSON file
local function readBanFile()
    local file = io.open(banFilePath, "r")
    if not file then
        print("Failed to open ban file for reading")
        return {}
    end
    local content = file:read("*all")
    file:close()
    local bans = json.decode(content)
    if not bans then
        print("Failed to decode ban file: Invalid JSON format")
        return {}
    end
    return bans
end

-- Function to save bans to the JSON file
local function saveBanFile(bans)
    local file = io.open(banFilePath, "w")
    if not file then
        print("Failed to open ban file for writing")
        return false
    end
    file:write(json.encode(bans, { indent = true }))
    file:close()
    return true
end

-- Function to read kicks from the JSON file
local function readKickFile()
    local file = io.open(kickFilePath, "r")
    if not file then
        print("Failed to open kick file for reading")
        return {}
    end
    local content = file:read("*all")
    file:close()
    local kicks = json.decode(content)
    if not kicks then
        print("Failed to decode kick file: Invalid JSON format")
        return {}
    end
    return kicks
end

-- Function to save kicks to the JSON file
local function saveKickFile(kicks)
    local file = io.open(kickFilePath, "w")
    if not file then
        print("Failed to open kick file for writing")
        return false
    end
    file:write(json.encode(kicks, { indent = true }))
    file:close()
    return true
end

-- Function to update player data
Apex.Functions.updatePlayerData = function(identifier, key, value)
    oxmysql:execute('UPDATE users SET ' .. key .. ' = ? WHERE identifier = ?', {value, identifier}, function(result)
        if result and result.affectedRows > 0 then
            print("Saved " .. identifier .. "'s Location")
        end
    end)
end


-- Function to get player data
Apex.Functions.getPlayerData = function(identifier, callback)
    oxmysql:execute('SELECT * FROM users WHERE identifier = ?', {identifier}, function(result)
        callback(result[1] or {})
    end)
end

-- Function to add money to player (cash or bank)
Apex.Functions.addMoney = function(identifier, amount, type)
    type = type or 'cash'
    oxmysql:execute('UPDATE users SET ' .. type .. ' = ' .. type .. ' + ? WHERE identifier = ?', {amount, identifier})
end

-- Function to remove money from player (cash or bank)
Apex.Functions.removeMoney = function(identifier, amount, type)
    type = type or 'cash'
    oxmysql:execute('UPDATE users SET ' .. type .. ' = ' .. type .. ' - ? WHERE identifier = ?', {amount, identifier})
end

-- Function to get player money (cash and bank)
Apex.Functions.getMoney = function(identifier, callback)
    oxmysql:execute('SELECT cash, bank FROM users WHERE identifier = ?', {identifier}, function(result)
        if result and result[1] then
            callback(result[1].cash or 0, result[1].bank or 0)
        else
            callback(0, 0)
        end
    end)
end

-- Function to transfer money between cash and bank
Apex.Functions.transferMoney = function(identifier, amount, from, to)
    from = from or 'cash'
    to = to or 'bank'
    Apex.Functions.removeMoney(identifier, amount, from)
    Apex.Functions.addMoney(identifier, amount, to)
end

-- Function to set player job
Apex.Functions.setJob = function(identifier, job)
    Apex.Functions.updatePlayerData(identifier, 'job', job)
end

-- Function to get player job
Apex.Functions.getJob = function(identifier, callback)
    Apex.Functions.getPlayerData(identifier, function(data)
        callback(data.job)
    end)
end

-- Function to list all jobs
Apex.Functions.listJobs = function(callback)
    oxmysql:execute('SELECT * FROM jobs', {}, function(results)
        callback(results)
    end)
end

-- Function to add a new job
Apex.Functions.addJob = function(name, label)
    oxmysql:execute('INSERT INTO jobs (name, label) VALUES (?, ?)', {name, label}, function(result)
        if result and result.affectedRows > 0 then
            print("Added new job:", name)
        else
            print("Failed to add job:", name)
        end
    end)
end

-- Function to notify a player
Apex.Functions.notify = function(playerId, message, type)
    TriggerClientEvent('apx:notify', playerId, message, type)
end

-- Register a client event to handle notifications
RegisterNetEvent('apx:notify')
AddEventHandler('apx:notify', function(message, type)
    -- Client-side code to display the notification
    TriggerEvent('chat:addMessage', { args = { type or 'INFO', message } })
end)

-- Function to get player inventory
Apex.Functions.getInventory = function(identifier, callback)
    oxmysql:execute('SELECT inventory FROM users WHERE identifier = ?', {identifier}, function(result)
        if result and result[1] and result[1].inventory then
            callback(json.decode(result[1].inventory))
        else
            callback({})
        end
    end)
end

-- Function to update player inventory
Apex.Functions.updateInventory = function(identifier, inventory, callback)
    local encodedInventory = json.encode(inventory)
    oxmysql:execute('UPDATE users SET inventory = ? WHERE identifier = ?', {encodedInventory, identifier}, function(result)
        if result and result.affectedRows > 0 then
            callback(true)
        else
            callback(false)
        end
    end)
end

-- Function to check if a player is an admin
Apex.Functions.isAdmin = function(identifier, callback)
    oxmysql:execute('SELECT isAdmin FROM users WHERE identifier = ?', {identifier}, function(result)
        if result and result[1] then
            callback(result[1].isAdmin)
        else
            callback(false)
        end
    end)
end

-- Function to set a player as admin
Apex.Functions.setAdmin = function(identifier, isAdmin)
    Apex.Functions.updatePlayerData(identifier, 'isAdmin', isAdmin)
end

-- Function to ban a player
Apex.Functions.banPlayer = function(identifier, adminIdentifier, reason, duration)
    local bans = readBanFile()
    local banTime = os.time() + (duration * 60)

    table.insert(bans, {
        identifier = identifier,
        adminIdentifier = adminIdentifier,
        reason = reason,
        banTime = banTime,
        duration = duration
    })

    saveBanFile(bans)

    print("Banned player:", identifier, "by admin:", adminIdentifier, "for reason:", reason, "duration:", duration)
    -- Kick the player from the server if they are online
    local playerId = GetPlayerFromIdentifier(identifier)
    if playerId then
        DropPlayer(playerId, "You have been banned for " .. reason)
    end
end

-- Function to check if a player is banned
Apex.Functions.isBanned = function(identifier, callback)
    local bans = readBanFile()
    local currentTime = os.time()

    for _, ban in ipairs(bans) do
        if ban.identifier == identifier then
            if ban.banTime > currentTime or ban.duration == 0 then
                callback(true, ban)
                return
            else
                -- Remove expired bans
                table.remove(bans, _)
                saveBanFile(bans)
            end
        end
    end
    callback(false)
end

-- Function to kick a player
Apex.Functions.kickPlayer = function(identifier, adminIdentifier, reason)
    local kicks = readKickFile()
    table.insert(kicks, {
        identifier = identifier,
        adminIdentifier = adminIdentifier,
        reason = reason,
        kickTime = os.time()
    })

    saveKickFile(kicks)

    print("Kicked player:", identifier, "by admin:", adminIdentifier, "for reason:", reason)
    -- Kick the player from the server if they are online
    local playerId = GetPlayerFromIdentifier(identifier)
    if playerId then
        DropPlayer(playerId, "You have been kicked for " .. reason)
    end
end

-- Function to get a player from identifier
function GetPlayerFromIdentifier(identifier)
    for _, playerId in ipairs(GetPlayers()) do
        for _, id in ipairs(GetPlayerIdentifiers(playerId)) do
            if id == identifier then
                return playerId
            end
        end
    end
    return nil
end
