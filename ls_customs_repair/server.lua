local ESX = exports['es_extended']:getSharedObject()

RegisterNetEvent('ls_customs_repair:tryRepair', function(price)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer then return end

    local cost = tonumber(price) or 500

    if xPlayer.getMoney() < cost then
        TriggerClientEvent('esx:showNotification', src,
            ('You need ~g~$%s~s~ to repair your vehicle.'):format(cost))
        return
    end

    xPlayer.removeMoney(cost)
    TriggerClientEvent('esx:showNotification', src,
        ('You paid ~r~$%s~s~ for the repair.'):format(cost))
    TriggerClientEvent('ls_customs_repair:doRepair', src)
end)
