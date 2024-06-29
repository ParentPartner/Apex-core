-- server/main.lua
local oxmysql = exports.oxmysql

-- Function to ensure player exists in the database
local function ensurePlayerExists(identifier, callback)
    Apex.Functions.getPlayerData(identifier, function(data)
        if data.identifier then
            callback(true)
        else
            oxmysql:execute('INSERT INTO users (identifier, posX, posY, posZ, cash, bank, isAdmin) VALUES (?, ?, ?, ?, ?, ?, ?)', {identifier, 0.0, 0.0, 0.0, Config.StartingCash, Config.StartingBank, false}, function(result)
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
            print("Assigned first player as admin:", identifier)
        end
    end)
end

-- Handle player connecting to the server
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local playerId = source
    deferrals.defer()
    print("Connection in progress for:", playerName)

    -- Ensuring deferral isn't processed too early
    Citizen.Wait(0)
    deferrals.update(string.format("Hello %s. Your connection is being checked.", playerName))

    -- Simulating some connection delay
    Citizen.Wait(1000)

    -- Assuming everything is fine for now
    deferrals.done()
end)

-- Handle player spawn and retrieve their last saved position
RegisterNetEvent('apx:registerPlayer')
AddEventHandler('apx:registerPlayer', function()
    local playerId = source
    local identifier = GetPlayerIdentifiers(playerId)[1]
    print("Handling registration/loading for player ID:", playerId)

    ensurePlayerExists(identifier, function(exists)
        if exists then
            -- Assign the first player as admin
            assignFirstAdmin(identifier)
            
            -- Fetch last saved position from the database
            Apex.Functions.getPlayerData(identifier, function(data)
                if data.posX and data.posY and data.posZ then
                    -- Trigger client event to teleport player to last saved position
                    TriggerClientEvent('apx:teleportPlayer', playerId, data.posX, data.posY, data.posZ)
                    print("Teleporting player to last saved location for:", identifier, data.posX, data.posY, data.posZ)
                else
                    -- If no data is found, use the default spawn position
                    TriggerClientEvent('apx:teleportPlayer', playerId, Config.StartingPosition.x, Config.StartingPosition.y, Config.StartingPosition.z)
                    print("Teleporting player to default location for:", identifier)
                end
            end)
        else
            print("Failed to ensure player exists:", identifier)
        end
    end)
end)

-- Save player location when they disconnect
AddEventHandler('playerDropped', function(reason)
    local playerId = source
    local identifier = GetPlayerIdentifiers(playerId)[1]
    local playerCoords = GetEntityCoords(GetPlayerPed(playerId))

    print("Saving location for player", identifier, "at", playerCoords)

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

    print("Saving location for player", identifier, "at", vector3(x, y, z))

    -- Update the database with the player's last location
    Apex.Functions.updatePlayerData(identifier, 'posX', x)
    Apex.Functions.updatePlayerData(identifier, 'posY', y)
    Apex.Functions.updatePlayerData(identifier, 'posZ', z)
end)
