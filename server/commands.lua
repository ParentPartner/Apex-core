-- server/commands.lua

-- Register a command to set job
RegisterCommand('setjob', function(source, args, rawCommand)
    local playerId = source
    if playerId > 0 then
        local identifier = GetPlayerIdentifiers(playerId)[1]
        local job = args[1]
        if job then
            Apex.Functions.setJob(identifier, job)
            TriggerClientEvent('chat:addMessage', playerId, { args = { 'Job', 'Your job has been set to ' .. job } })
        else
            TriggerClientEvent('chat:addMessage', playerId, { args = { 'Job', 'Please specify a job.' } })
        end
    end
end, false)

-- Register a command to get current job
RegisterCommand('getjob', function(source, args, rawCommand)
    local playerId = source
    if playerId > 0 then
        local identifier = GetPlayerIdentifiers(playerId)[1]
        Apex.Functions.getJob(identifier, function(job)
            TriggerClientEvent('chat:addMessage', playerId, { args = { 'Job', 'Your current job is ' .. (job or 'none') } })
        end)
    end
end, false)

-- Register a command to list all jobs
RegisterCommand('listjobs', function(source, args, rawCommand)
    local playerId = source
    if playerId > 0 then
        Apex.Functions.listJobs(function(jobs)
            for _, job in ipairs(jobs) do
                TriggerClientEvent('chat:addMessage', playerId, { args = { 'Job', job.name .. ' - ' .. job.label } })
            end
        end)
    end
end, false)

-- Register a command to give money
RegisterCommand('givemoney', function(source, args, rawCommand)
    local playerId = source
    local amount = tonumber(args[1])
    local type = args[2] or 'cash'

    if playerId and amount then
        local identifier = GetPlayerIdentifiers(playerId)[1]
        Apex.Functions.addMoney(identifier, amount, type)
        TriggerClientEvent('chat:addMessage', playerId, { args = { 'Money', 'You have received $' .. amount .. ' ' .. type } })
    end
end, false)

-- Register a command to check money
RegisterCommand('checkmoney', function(source, args, rawCommand)
    local playerId = source
    if playerId > 0 then
        local identifier = GetPlayerIdentifiers(playerId)[1]
        Apex.Functions.getMoney(identifier, function(cash, bank)
            TriggerClientEvent('chat:addMessage', playerId, { args = { 'Money', 'Cash: $' .. cash .. ', Bank: $' .. bank } })
        end)
    end
end, false)

-- Function to ban a player (admin only)
RegisterCommand('ban', function(source, args, rawCommand)
    local playerId = source
    local targetId = tonumber(args[1])
    local duration = tonumber(args[#args]) or 0
    table.remove(args, 1)
    table.remove(args, #args)
    local reason = table.concat(args, " ")

    if targetId and reason and duration then
        local identifier = GetPlayerIdentifiers(playerId)[1]
        local targetIdentifier = GetPlayerIdentifiers(targetId)[1]
        if identifier == targetIdentifier then
            TriggerClientEvent('chat:addMessage', playerId, { args = { 'Admin', 'You cannot ban yourself.' } })
            return
        end
        Apex.Functions.isAdmin(identifier, function(isAdmin)
            if isAdmin then
                Apex.Functions.banPlayer(targetIdentifier, identifier, reason, duration)
                TriggerClientEvent('chat:addMessage', playerId, { args = { 'Admin', 'Player ' .. targetId .. ' has been banned for ' .. reason .. ' (duration: ' .. duration .. ' minutes).' } })
            else
                TriggerClientEvent('chat:addMessage', playerId, { args = { 'Admin', 'You do not have permission to use this command.' } })
            end
        end)
    else
        TriggerClientEvent('chat:addMessage', playerId, { args = { 'Admin', 'Invalid player ID, reason, or duration.' } })
    end
end, false)

-- Command to kick a player (admin only)
RegisterCommand('kick', function(source, args, rawCommand)
    local playerId = source
    local targetId = tonumber(args[1])
    table.remove(args, 1)
    local reason = table.concat(args, " ")

    if targetId and reason then
        local identifier = GetPlayerIdentifiers(playerId)[1]
        local targetIdentifier = GetPlayerIdentifiers(targetId)[1]
        if identifier == targetIdentifier then
            TriggerClientEvent('chat:addMessage', playerId, { args = { 'Admin', 'You cannot kick yourself.' } })
            return
        end
        Apex.Functions.isAdmin(identifier, function(isAdmin)
            if isAdmin then
                Apex.Functions.kickPlayer(targetIdentifier, identifier, reason)
                TriggerClientEvent('chat:addMessage', playerId, { args = { 'Admin', 'Player ' .. targetId .. ' has been kicked for ' .. reason .. '.' } })
            else
                TriggerClientEvent('chat:addMessage', playerId, { args = { 'Admin', 'You do not have permission to use this command.' } })
            end
        end)
    else
        TriggerClientEvent('chat:addMessage', playerId, { args = { 'Admin', 'Invalid player ID or reason.' } })
    end
end, false)

-- Additional commands can be added here
