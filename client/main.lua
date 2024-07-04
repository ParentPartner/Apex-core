-- client/main.lua

-- Event to teleport player to the specified coordinates
RegisterNetEvent('apx:teleportPlayer')
AddEventHandler('apx:teleportPlayer', function(x, y, z)
    local playerPed = PlayerPedId()
    if playerPed then
        SetEntityCoords(playerPed, x, y, z, false, false, false, true)
    else
        print("Error: Failed to get playerPed.")
    end
end)

-- Notify server that player has spawned
AddEventHandler('playerSpawned', function()
    local playerId = PlayerId()
    if playerId then
        TriggerServerEvent('apx:registerPlayer')
    else
        print("Error: Failed to get playerId.")
    end
end)

-- Notify server to save player location when they disconnect
AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        local playerPed = PlayerPedId()
        if playerPed then
            local coords = GetEntityCoords(playerPed)
            if coords then
                TriggerServerEvent('apx:savePlayerLocation', coords.x, coords.y, coords.z)
            else
                print("Error: Failed to get player coordinates.")
            end
        else
            print("Error: Failed to get playerPed.")
        end
    end
end)
