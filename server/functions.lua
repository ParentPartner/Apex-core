local oxmysql = exports['oxmysql']

Apex = {}
Apex.Functions = {}

-- Function to update player data
Apex.Functions.updatePlayerData = function(identifier, key, value)
    oxmysql:execute('UPDATE users SET ' .. key .. ' = ? WHERE identifier = ?', {value, identifier}, function(result)
        if result and result.affectedRows > 0 then
            print("Updated " .. key .. " for player:", identifier)
        else
            print("Failed to update " .. key .. " for player:", identifier)
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

-- Additional utility functions can be added here
