function xGetPlayer(src)
    if Config.FrameWork.Type == 'qbx' then
        return exports.qbx_core:GetPlayer(src)
    elseif Config.FrameWork.Type == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        return QBCore.Functions.GetPlayer(src)
    elseif Config.FrameWork.Type == 'esx' then
        local ESX = exports["es_extended"]:getSharedObject()
        return ESX.GetPlayerFromId(src)
    end
end

function xGetPlayerIdentifier(src)
    local Player = xGetPlayer(src)
    if not Player then return nil end

    if Config.FrameWork.Type == 'qbx' or Config.FrameWork.Type == 'qb' then
        return Player.PlayerData.citizenid
    elseif Config.FrameWork.Type == 'esx' then
        return Player.identifier
    end
end

function xGetDataName(identifier)
    local firstName, lastName

    if not identifier or identifier == "" then
        return "Unknown"
    end

    if Config.FrameWork.Type == 'esx' then
        local result = MySQL.query.await(
            "SELECT `firstname`, `lastname` FROM `users` WHERE `identifier` = ?",
            { identifier }
        )
        if result[1] then
            firstName = result[1].firstname or "Unknown"
            lastName  = result[1].lastname or ""
        end

    elseif Config.FrameWork.Type == 'qb' or Config.FrameWork.Type == 'qbx' then
        local result = MySQL.query.await(
            "SELECT `charinfo` FROM `players` WHERE `citizenid` = ?",
            { identifier }
        )
        if result[1] then
            local charinfo = json.decode(result[1].charinfo or "{}")
            firstName = charinfo.firstname or "Unknown"
            lastName  = charinfo.lastname or ""
        end
    end

    return ("%s %s"):format(firstName or "Unknown", lastName or "")
end

function xRemoveMoney(src, account, amount)
    local Player = xGetPlayer(src)
    if not Player then return false end

    if Config.FrameWork.Type == 'qb' or Config.FrameWork.Type == 'qbx' then
        return Player.Functions.RemoveMoney(account, amount)
    elseif Config.FrameWork.Type == 'esx' then
        local bal = (account == 'bank') and Player.getAccount('bank').money or Player.getMoney()
        if bal < amount then return false end

        if account == 'bank' then
            Player.removeAccountMoney('bank', amount)
        else
            Player.removeMoney(amount)
        end
        return true
    end

    return false
end

function xRegisterStash(stashId, label, slots, weight)
    if Config.FrameWork.Inventory == 'ox' then
        exports.ox_inventory:RegisterStash(stashId, label, slots, weight, false)
    end
end

function xOpenStash(src, stashId, slots, weight)
    if Config.FrameWork.Inventory == 'ox' then
        TriggerClientEvent("R6-apartment:client:openInventory", src, stashId)

    elseif Config.FrameWork.Inventory == 'qb' then
        TriggerClientEvent("R6-apartment:client:openQbStash", src, stashId, slots, weight)
    end
end
