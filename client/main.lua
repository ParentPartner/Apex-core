-- client/main.lua

-- Event to teleport player to the specified coordinates
RegisterNetEvent('apx:teleportPlayer')
AddEventHandler('apx:teleportPlayer', function(x, y, z)
    local playerPed = PlayerPedId()
    SetEntityCoords(playerPed, x, y, z, false, false, false, true)
end)

-- Notify server that player has spawned
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('apx:registerPlayer')
end)

-- Notify server to save player location when they disconnect
AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        TriggerServerEvent('apx:savePlayerLocation', coords.x, coords.y, coords.z)
    end
end)
