local apartmentInstances = {}
local playerInstance     = {}
local pendingRequests    = {}

local BUCKET_BASE   = 1000
local bucketCounter = 0

local function GetOrCreateBucket(citizenid)
    if not apartmentInstances[citizenid] then
        bucketCounter = bucketCounter + 1
        apartmentInstances[citizenid] = BUCKET_BASE + bucketCounter
    end
    return apartmentInstances[citizenid]
end

RegisterNetEvent("R6-apartment:server:enterApartment", function(ownerCitizenId)
    local src = source
    local myCid = xGetPlayerIdentifier(src)
    if not myCid then return end

    local ownerCid = ownerCitizenId or myCid
    local bucket    = GetOrCreateBucket(ownerCid)

    SetPlayerRoutingBucket(src, bucket)
    playerInstance[src] = ownerCid
end)

RegisterNetEvent("R6-apartment:server:exitApartment", function()
    local src = source
    SetPlayerRoutingBucket(src, 0)
    playerInstance[src] = nil
end)

RegisterNetEvent("R6-apartment:server:sendVisitRequest", function(ownerSrc)
    local visitorSrc = source
    local visitorCid = xGetPlayerIdentifier(visitorSrc)
    local ownerCid    = xGetPlayerIdentifier(ownerSrc)

    if not visitorCid or not ownerCid then
        TriggerClientEvent('ox_lib:notify', visitorSrc, {
            title = 'Apartment', description = 'Player not found.', type = 'error'
        })
        return
    end

    if playerInstance[ownerSrc] ~= ownerCid then
        TriggerClientEvent('ox_lib:notify', visitorSrc, {
            title = 'Apartment', description = 'This player is not in their apartment.', type = 'error'
        })
        return
    end

    pendingRequests[visitorSrc] = ownerSrc

    local visitorName = xGetDataName(visitorCid)

    TriggerClientEvent("R6-apartment:client:receiveVisitRequest", ownerSrc, visitorSrc, visitorName)

    TriggerClientEvent('ox_lib:notify', visitorSrc, {
        title    = 'Visit Request',
        description = 'Request sent! Waiting for response...',
        type     = 'info',
        duration = (Config.VisitRequestTimeout * 1000),
    })

    SetTimeout(Config.VisitRequestTimeout * 1000, function()
        if pendingRequests[visitorSrc] == ownerSrc then
            pendingRequests[visitorSrc] = nil
            TriggerClientEvent('ox_lib:notify', visitorSrc, {
                title = 'Visit Request', description = 'Request timed out.', type = 'error'
            })
        end
    end)
end)

RegisterNetEvent("R6-apartment:server:respondVisitRequest", function(visitorSrc, accepted)
    local ownerSrc = source
    local ownerCid = xGetPlayerIdentifier(ownerSrc)
    if not ownerCid then return end

    if pendingRequests[visitorSrc] ~= ownerSrc then
        TriggerClientEvent('ox_lib:notify', ownerSrc, {
            title = 'Apartment', description = 'Request expired.', type = 'warning'
        })
        return
    end

    pendingRequests[visitorSrc] = nil

    if accepted then
        TriggerClientEvent("R6-apartment:client:visitResponse", visitorSrc, true, ownerCid)
        TriggerClientEvent('ox_lib:notify', ownerSrc, {
            title = 'Apartment', description = 'You accepted the visit request.', type = 'success'
        })
    else
        TriggerClientEvent("R6-apartment:client:visitResponse", visitorSrc, false, nil)
        TriggerClientEvent('ox_lib:notify', ownerSrc, {
            title = 'Apartment', description = 'You declined the visit request.', type = 'info'
        })
    end
end)

RegisterNetEvent("R6-apartment:server:checkOwner", function()
    local src     = source
    local myCid   = xGetPlayerIdentifier(src)
    if not myCid then return end

    local ownerCid = playerInstance[src]
    local isOwner   = (ownerCid == nil) or (ownerCid == myCid)
    TriggerClientEvent("R6-apartment:client:ownerCheck", src, isOwner)
end)

RegisterNetEvent("R6-apartment:server:openStash", function(ownerCitizenId)
    local src   = source
    local myCid = xGetPlayerIdentifier(src)
    if not myCid then return end

    local targetCid    = ownerCitizenId or myCid
    local currentOwner = playerInstance[src] or myCid

    if currentOwner ~= targetCid then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Apartment', description = 'You are not in this apartment.', type = 'error'
        })
        return
    end

    local stashId = "apartment_" .. targetCid

    MySQL.query('SELECT * FROM apartment_stash WHERE citizenid = ?', { targetCid }, function(result)
        local slots, weight

        if result[1] then
            slots  = result[1].slots
            weight = result[1].weight
        else
            slots  = Config.Apartment.Storage.slots
            weight = Config.Apartment.Storage.weight
            MySQL.update('INSERT INTO apartment_stash (citizenid, slots, weight) VALUES (?, ?, ?)',
                { targetCid, slots, weight })
        end

        xRegisterStash(stashId, "Apartment Storage", slots, weight)
        xOpenStash(src, stashId, slots, weight)
    end)
end)

RegisterNetEvent("R6-apartment:server:upgradeSlots", function(newSlots, price)
    local src   = source
    local myCid = xGetPlayerIdentifier(src)
    if not myCid then return end

    local ownerCid = playerInstance[src]
    if ownerCid ~= nil and ownerCid ~= myCid then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Apartment', description = 'Only the owner can upgrade.', type = 'error' })
        return
    end

    if xRemoveMoney(src, "bank", price) then
        local stashId = "apartment_" .. myCid

        MySQL.update('UPDATE apartment_stash SET slots = ? WHERE citizenid = ?', { newSlots, myCid }, function()
            MySQL.query('SELECT * FROM apartment_stash WHERE citizenid = ?', { myCid }, function(result)
                if result[1] then
                    xRegisterStash(stashId, "Apartment Storage", result[1].slots, result[1].weight)
                end
            end)
        end)

        TriggerClientEvent('ox_lib:notify', src, { title = 'Success', description = 'Slots upgraded!', type = 'success' })
    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'Not enough money!', type = 'error' })
    end
end)

RegisterNetEvent("R6-apartment:server:upgradeWeight", function(newWeight, price)
    local src   = source
    local myCid = xGetPlayerIdentifier(src)
    if not myCid then return end

    local ownerCid = playerInstance[src]
    if ownerCid ~= nil and ownerCid ~= myCid then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Apartment', description = 'Only the owner can upgrade.', type = 'error' })
        return
    end

    if xRemoveMoney(src, "bank", price) then
        local stashId = "apartment_" .. myCid

        MySQL.update('UPDATE apartment_stash SET weight = ? WHERE citizenid = ?', { newWeight, myCid }, function()
            MySQL.query('SELECT * FROM apartment_stash WHERE citizenid = ?', { myCid }, function(result)
                if result[1] then
                    xRegisterStash(stashId, "Apartment Storage", result[1].slots, result[1].weight)
                end
            end)
        end)

        TriggerClientEvent('ox_lib:notify', src, { title = 'Success', description = 'Weight upgraded!', type = 'success' })
    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'Not enough money!', type = 'error' })
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    pendingRequests[src] = nil
    playerInstance[src]  = nil
end)
