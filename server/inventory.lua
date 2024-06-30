local oxmysql = exports['oxmysql']

Apex = Apex or {}
Apex.Inventory = {}

-- Function to get player inventory
Apex.Inventory.getInventory = function(identifier, callback)
    oxmysql:execute('SELECT inventory FROM users WHERE identifier = ?', {identifier}, function(result)
        if result and result[1] and result[1].inventory then
            callback(json.decode(result[1].inventory))
        else
            callback({})
        end
    end)
end

-- Function to update player inventory
Apex.Inventory.updateInventory = function(identifier, inventory, callback)
    local encodedInventory = json.encode(inventory)
    oxmysql:execute('UPDATE users SET inventory = ? WHERE identifier = ?', {encodedInventory, identifier}, function(result)
        if result and result.affectedRows > 0 then
            callback(true)
        else
            callback(false)
        end
    end)
end

-- Function to add item to player's inventory
Apex.Inventory.addItem = function(identifier, item, quantity, callback)
    Apex.Inventory.getInventory(identifier, function(inventory)
        inventory[item] = (inventory[item] or 0) + quantity
        Apex.Inventory.updateInventory(identifier, inventory, callback)
    end)
end

-- Function to remove item from player's inventory
Apex.Inventory.removeItem = function(identifier, item, quantity, callback)
    Apex.Inventory.getInventory(identifier, function(inventory)
        if inventory[item] and inventory[item] >= quantity then
            inventory[item] = inventory[item] - quantity
            if inventory[item] == 0 then
                inventory[item] = nil
            end
            Apex.Inventory.updateInventory(identifier, inventory, callback)
        else
            if callback then callback(false) end
        end
    end)
end

return Apex.Inventory
