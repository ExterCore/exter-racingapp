Core = nil
CoreName = nil
CoreReady = false
playersByIdentifier = {}
Citizen.CreateThread(function()
    for k, v in pairs(Cores) do
        if GetResourceState(v.ResourceName) == "starting" or GetResourceState(v.ResourceName) == "started" then
            CoreName = v.ResourceName
            Core = v.GetFramework()
            CoreReady = true
            TriggerEvent('race:getData')

            for _, playerId in ipairs(GetPlayers()) do
                local identifier = GetPlayerCid(tonumber(playerId)) 
                if identifier then
                    playersByIdentifier[identifier] = playerId
                end
            end

        end
    end
end)

function GetPlayer(source)
    if CoreName == "qb-core" or CoreName == "qbx_core" then
        local player = Core.Functions.GetPlayer(source)
        return player
    elseif CoreName == "es_extended" then
        local player = Core.GetPlayerFromId(source)
        return player
    else
        --CUSTOM GET PLAYER FUNCTION HERE
    end
end

function GetPlayerCid(source)
    if CoreName == "qb-core" then
        local player = Core.Functions.GetPlayer(source)
        if player ~= nil then
            return player.PlayerData.citizenid
        else
            return nil
        end
    elseif CoreName == "es_extended" then
        local player = Core.GetPlayerFromId(source)
        return player.getIdentifier()
    else
        --CUSTOM GET PLAYER CID FUNCTION HERE
    end
end

function GetSourceFromIdentifier(identifier)
    if CoreName == "qb-core" then
        return playersByIdentifier[identifier]
    elseif CoreName == "es_extended" then
        local player = Core.GetPlayerFromIdentifier(identifier)
        return player.source
    else
        --CUSTOM GET SOURCE FROM IDENTIFIER FUNCTION HERE
    end
end


function Notify(source, text, length, type)
    if CoreName == "qb-core" or CoreName == "qbx_core" then
        Core.Functions.Notify(source, text, length, type)
    elseif CoreName == "es_extended" then
        local player = Core.GetPlayerFromId(source)
        player.showNotification(text)
    else
    --CUSTOM NOTIFY FUNCTION HERE
    end
end

function GetItemCount(source,item)
    if CoreName == "qb-core" or CoreName == "qbx_core" then
        local player = Core.Functions.GetPlayer(source)
        if player.Functions.GetItemByName(item) == nil then
            return 0
        end
        return player.Functions.GetItemByName(item).amount
    elseif CoreName == "es_extended" then
        local player = Core.GetPlayerFromId(source)
        local hasQs = GetResourceState('qs-inventory') == 'started'
        local hasEsx = GetResourceState('esx_inventoryhud') == 'started'
        local hasOx = GetResourceState('ox_inventory') == 'started'

        if hasQs then
            return exports['qs-inventory']:GetItem(source, item).amount
        elseif hasOx or hasEsx then
            return player.getInventoryItem(item).count
        elseif hasOx then
            return exports["ox_inventory"]:Search(source, item).count
        else
            --CUSTOM INVENTORY GET ITEM COUNT FUNCTION HERE
        end
    end
end

function GetPlayerMoney(src, type)
    if CoreName == "qb-core" or CoreName == "qbx_core" then
        local player = Core.Functions.GetPlayer(src)
        return player.PlayerData.money[type]
    elseif CoreName == "es_extended" then
        local player = Core.GetPlayerFromId(src)
        local acType = "bank"
        if type == "cash" then
            acType = "money"
        end
        local account = player.getAccount(acType).money
        return player
    else
        --CUSTOM ACCOUNT GET MONEY FUNCTION HERE
    end
end

function AddMoney(src, type, amount, description)
    if CoreName == "qb-core" or CoreName == "qbx_core" then
        local player = Core.Functions.GetPlayer(src)
        player.Functions.AddMoney(type, amount, description)
    elseif CoreName == "es_extended" then
        local player = Core.GetPlayerFromId(src)
        if type == "bank" then
            player.addAccountMoney("bank", amount, description)
        elseif type == "cash" then
            player.addMoney(amount, description)
        end
    end
end


function RemoveMoney(src, type, amount, description)
    if CoreName == "qb-core" or CoreName == "qbx_core" then
        local player = Core.Functions.GetPlayer(src)
        player.Functions.RemoveMoney(type, amount, description)
    elseif CoreName == "es_extended" then
        local player = Core.GetPlayerFromId(src)
        if type == "bank" then
            player.removeAccountMoney("bank", amount, description)
        elseif type == "cash" then
            player.removeMoney(amount, description)
        else
            --CUSTOM ACCOUNT REMOVE MONEY FUNCTION HERE
        end
    end
end



function AddItem(source, name, amount, metadata)
    if CoreName == "qb-core" or CoreName == "qbx_core" then
        local player = Core.Functions.GetPlayer(source)
        player.Functions.AddItem(name, amount)
    elseif CoreName == "es_extended" then
        local player = Core.GetPlayerFromId(source)
        local hasQs = GetResourceState('qs-inventory') == 'started'
        local hasEsx = GetResourceState('esx_inventoryhud') == 'started'
        local hasOx = GetResourceState('qb-inventory') == 'started'

        if hasQs then
            return exports['qs-inventory']:AddItem(source, name, amount)
        elseif hasEsx then
            return player.addInventoryItem(name, amount)
        elseif hasOx then
            return exports["qb-inventory"]:AddItem(source, name, amount, metadata)
        else
            --CUSTOM INVENTORY ADD ITEM FUNCTION HERE
        end

    end
end

function RemoveItem(source, name, amount, metadata)
    if CoreName == "qb-core" or CoreName == "qbx_core" then
        local player = Core.Functions.GetPlayer(source)
        player.Functions.RemoveItem(name, amount, metadata)
    elseif CoreName == "es_extended" then
        local player = Core.GetPlayerFromId(source)
        local hasQs = GetResourceState('qs-inventory') == 'started'
        local hasEsx = GetResourceState('esx_inventoryhud') == 'started'
        local hasOx = GetResourceState('qb-inventory') == 'started'

        if hasQs then
            return exports['qs-inventory']:RemoveItem(source, name, amount, metadata)
        elseif hasEsx then
            return player.removeInventoryItem(name, amount)
        elseif hasOx then
            return exports["qb-inventory"]:RemoveItem(source, name, amount, metadata)
        else
            --CUSTOM INVENTORY REMOVE ITEM FUNCTION HERE
        end
    end
end

function GetItem(source, name)
    if CoreName == "qb-core" or CoreName == "qbx_core" then
        local player = Core.Functions.GetPlayer(source)
        return player.Functions.GetItemByName(name)
    elseif CoreName == "es_extended" then
        local player = Core.GetPlayerFromId(source)
        local hasQs = GetResourceState('qs-inventory') == 'started'
        local hasEsx = GetResourceState('esx_inventoryhud') == 'started'
        local hasOx = GetResourceState('qb-inventory') == 'started'

        if hasQs then
            return exports['qs-inventory']:GetItem(source, name)
        elseif hasEsx then
            return player.getInventoryItem(name)
        elseif hasOx then
            return exports["qb-inventory"]:GetItem(source, name)
        else
            --CUSTOM INVENTORY GET ITEM FUNCTION HERE
        end
    end
end

function GetInventory(source)
    if CoreName == "qb-core" or CoreName == "qbx_core" then
        local player = Core.Functions.GetPlayer(source)
        return player.PlayerData.items
    elseif CoreName == "es_extended" then
        local player = Core.GetPlayerFromId(source)
        local hasQs = GetResourceState('qs-inventory') == 'started'
        local hasEsx = GetResourceState('esx_inventoryhud') == 'started'
        local hasOx = GetResourceState('qb-inventory') == 'started'

        if hasQs then
            return exports['qs-inventory']:GetPlayerInventory(source)
        elseif hasEsx or hasOx then
            return player.getInventory()
        -- elseif hasOx then
        --     return exports["qb-inventory"]:GetPlayerInventory(source)
        else
            --CUSTOM INVENTORY GET INVENTORY FUNCTION HERE
        end
    end
end

function ItemCountControl(source, name, amount)
    if CoreName == "qb-core" or CoreName == "qbx_core" then
        local player = Core.Functions.GetPlayer(source)
        return player.Functions.GetItemByName(name).amount >= amount
    elseif CoreName == "es_extended" then
        local player = Core.GetPlayerFromId(source)
        local hasQs = GetResourceState('qs-inventory') == 'started'
        local hasEsx = GetResourceState('esx_inventoryhud') == 'started'
        local hasOx = GetResourceState('qb-inventory') == 'started'

        if hasQs then
            return exports['qs-inventory']:GetItem(source, name).amount >= amount
        elseif hasEsx then
            return player.getInventoryItem(name).count >= amount
        elseif hasOx then
            return exports["qb-inventory"]:GetItem(source, name).amount >= amount
        else
            --CUSTOM INVENTORY ITEM COUNT CONTROL FUNCTION HERE
        end
    end
end


function RegisterUseableItem(name)
    while CoreReady == false do Citizen.Wait(0) end
    if CoreName == "qb-core" or CoreName == "qbx_core" then
        Core.Functions.CreateUseableItem(name, function(source, item)
            TriggerClientEvent('race:openTablet', source)
        end)
    elseif CoreName == "es_extended" then
        local hasQs = GetResourceState('qs-inventory') == 'started'
        if hasQs then
            Core.RegisterUsableItem(name, function(source, item)
                TriggerClientEvent('race:openTablet', source)
            end)
        end
        Core.RegisterUsableItem(name, function(source, _, item)
            TriggerClientEvent('race:openTablet', source)
        end)
    end
end


Config.ServerCallbacks = {}
function CreateCallback(name, cb)
    Config.ServerCallbacks[name] = cb
end

function TriggerCallback(name, source, cb, ...)
    if not Config.ServerCallbacks[name] then return end
    Config.ServerCallbacks[name](source, cb, ...)
end

RegisterNetEvent('race:server:triggerCallback', function(name, ...)
    local src = source
    TriggerCallback(name, src, function(...)
        TriggerClientEvent('race:client:triggerCallback', src, name, ...)
    end, ...)
end)