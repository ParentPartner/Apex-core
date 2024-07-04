local oxmysql = exports.oxmysql

-- Function to ensure player exists in the database
local function ensurePlayerExists(identifier, callback)
    Apex.Functions.getPlayerData(identifier, function(data)
        if data.identifier then
            callback(true)
        else
            oxmysql:execute('INSERT INTO users (identifier, posX, posY, posZ, cash, bank, isAdmin) VALUES (?, ?, ?, ?, ?, ?, ?)', 
            {identifier, 0.0, 0.0, 0.0, Config.StartingCash, Config.StartingBank, false}, function(result)
                callback(result.affectedRows > 0)
            end)
        end
    end)
end

-- Function to assign the first player as admin
local function assignFirstAdmin(identifier)
    oxmysql:execute('SELECT id FROM users ORDER BY id ASC LIMIT 1', {}, function(result)
        if #result > 0 and result[1].id == 1 then
            Apex.Functions.setAdmin(identifier, true)
        end
    end)
end

-- Handle player connecting to the server
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local playerId = source
    local identifier = GetPlayerIdentifiers(playerId)[1]
    deferrals.defer()

    -- Check if the player is banned
    Apex.Functions.isBanned(identifier, function(isBanned, banInfo)
        if isBanned then
            local reason = banInfo.reason or "No reason specified"
            local duration = banInfo.duration
            local timestamp = os.date("%Y-%m-%d %H:%M:%S", os.time(banInfo.timestamp) + (banInfo.duration * 60))
            local message = string.format("You are banned for %s until %s. Reason: %s", 
                duration == 0 and "permanently" or tostring(duration) .. " minutes", timestamp, reason)
            deferrals.done(message)
            return
        end

        -- Ensuring deferral isn't processed too early
        Citizen.Wait(0)
        deferrals.update(string.format("Hello %s. Your connection is being checked.", playerName))

        -- Simulating some connection delay
        Citizen.Wait(1000)

        -- Assuming everything is fine for now
        deferrals.done()
    end)
end)

-- Handle player spawn and retrieve their last saved position
RegisterNetEvent('apx:registerPlayer')
AddEventHandler('apx:registerPlayer', function()
    local playerId = source
    local identifier = GetPlayerIdentifiers(playerId)[1]

    ensurePlayerExists(identifier, function(exists)
        if exists then
            -- Assign the first player as admin
            assignFirstAdmin(identifier)
            
            -- Fetch last saved position from the database
            Apex.Functions.getPlayerData(identifier, function(data)
                if data.posX and data.posY and data.posZ then
                    -- Trigger client event to teleport player to last saved position
                    TriggerClientEvent('apx:teleportPlayer', playerId, data.posX, data.posY, data.posZ)
                else
                    -- If no data is found, use the default spawn position
                    TriggerClientEvent('apx:teleportPlayer', playerId, Config.StartingPosition.x, Config.StartingPosition.y, Config.StartingPosition.z)
                end
            end)
        end
    end)
end)

-- Save player location when they disconnect
AddEventHandler('playerDropped', function(reason)
    local playerId = source
    local identifier = GetPlayerIdentifiers(playerId)[1]
    local playerCoords = GetEntityCoords(GetPlayerPed(playerId))

    -- Update the database with the player's last location
    Apex.Functions.updatePlayerData(identifier, 'posX', playerCoords.x)
    Apex.Functions.updatePlayerData(identifier, 'posY', playerCoords.y)
    Apex.Functions.updatePlayerData(identifier, 'posZ', playerCoords.z)
end)

-- Add this handler to save player location when notified by the client
RegisterNetEvent('apx:savePlayerLocation')
AddEventHandler('apx:savePlayerLocation', function(x, y, z)
    local playerId = source
    local identifier = GetPlayerIdentifiers(playerId)[1]

    -- Update the database with the player's last location
    Apex.Functions.updatePlayerData(identifier, 'posX', x)
    Apex.Functions.updatePlayerData(identifier, 'posY', y)
    Apex.Functions.updatePlayerData(identifier, 'posZ', z)
end)
