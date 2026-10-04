local isInsideApartment = false
local currentOwnerCitizenId = nil

CreateThread(function()
    local Coord = Config.Interact

    xAddTargetBox('apartment_enter', Coord.Enter, vector3(1, 1, 1), 'Enter Apartment', 'fas fa-door-open', 5.0, function()
        ShowEnterMenu()
    end)

    xAddTargetBox('apartment_exit', Coord.Exit, vector3(1, 1, 1), 'Exit Apartment', 'fas fa-door-closed', 5.0, function()
        TeleportOut()
    end)

    xAddTargetBox('apartment_manage', Coord.Manage, vector3(1, 1, 1), 'Manage Apartment', 'fas fa-cog', 5.0, function()
        local myId = GetPlayerServerId(PlayerId())
        TriggerServerEvent("R6-apartment:server:checkOwner", myId)
    end)

    xAddTargetBox('apartment_wardrobe', Coord.Wardrobe, vector3(1, 1, 1), 'Open Wardrobe', 'fas fa-tshirt', 5.0, function()
        TriggerEvent("illenium-appearance:client:openOutfitMenu")
    end)

    xAddTargetBox('apartment_storage', Coord.Storage, vector3(1, 1, 1), 'Open Storage', 'fas fa-box-open', 5.0, function()
        TriggerServerEvent("R6-apartment:server:openStash", currentOwnerCitizenId)
    end)
end)

CreateThread(function()
    local blip = AddBlipForCoord(-267.28, -967.12, 110.1)
    SetBlipSprite(blip, 475)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.6)
    SetBlipAsShortRange(blip, true)
    SetBlipColour(blip, 3)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Apartment")
    EndTextCommandSetBlipName(blip)
end)

function ShowEnterMenu()
    xRegisterContext({
        id = 'apartment_enter_menu',
        title = 'Apartment',
        options = {
            {
                title = 'Enter My Apartment',
                description = 'Go to your own apartment',
                icon = 'house',
                onSelect = function()
                    TeleportIn(nil)
                end,
            },
            {
                title = 'Visit a Friend',
                description = 'Enter the player\'s server ID to send a visit request',
                icon = 'user-friends',
                onSelect = function()
                    local input = lib.inputDialog('Visit a Friend', {
                        {
                            type        = 'number',
                            label       = 'Player Server ID',
                            description = 'Enter the server ID of the player you want to visit',
                            placeholder = '1',
                            required    = true,
                            min         = 1,
                        }
                    })
                    if not input or not input[1] then return end

                    local targetId = tonumber(input[1])
                    if not targetId then
                        lib.notify({ title = 'Apartment', description = 'Invalid ID.', type = 'error' })
                        return
                    end

                    TriggerServerEvent("R6-apartment:server:sendVisitRequest", targetId)
                end,
            },
        }
    })
    xShowContext('apartment_enter_menu')
end

RegisterNetEvent("R6-apartment:client:receiveVisitRequest", function(visitorServerId, visitorName)
    xRegisterContext({
        id = 'apartment_visit_request',
        title = 'Visit Request',
        description = visitorName .. ' wants to visit your apartment.',
        options = {
            {
                title = 'Accept',
                icon = 'check',
                onSelect = function()
                    TriggerServerEvent("R6-apartment:server:respondVisitRequest", visitorServerId, true)
                end,
            },
            {
                title = 'Decline',
                icon = 'times',
                onSelect = function()
                    TriggerServerEvent("R6-apartment:server:respondVisitRequest", visitorServerId, false)
                end,
            },
        }
    })
    xShowContext('apartment_visit_request')
end)

RegisterNetEvent("R6-apartment:client:visitResponse", function(accepted, ownerCitizenId)
    if accepted then
        lib.notify({ title = 'Apartment', description = 'Your visit was accepted! Entering...', type = 'success' })
        TeleportIn(ownerCitizenId)
    else
        lib.notify({ title = 'Apartment', description = 'Your visit request was declined.', type = 'error' })
    end
end)

RegisterNetEvent("R6-apartment:client:ownerCheck", function(isOwner)
    if isOwner then
        Manage()
    else
        lib.notify({ title = 'Apartment', description = 'Only the owner can manage this apartment.', type = 'error' })
    end
end)

function TeleportIn(ownerCitizenId)
    local enter = Config.Apartment.EnterCoord
    local ped   = PlayerPedId()

    DoScreenFadeOut(500)

    lib.progressBar({
        duration = 4000,
        label = 'Travelling...',
        useWhileDead = false,
        canCancel = false,
        disable = { move = true, combat = true },
        anim = { dict = 'random@atmrobberygen@male', clip = 'idle_b' },
    })

    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, "doorbell", 0.2)
    TriggerServerEvent("R6-apartment:server:enterApartment", ownerCitizenId)

    Wait(500)
    SetEntityCoords(ped, enter.x, enter.y, enter.z)
    SetEntityHeading(ped, enter.w)

    isInsideApartment = true
    currentOwnerCitizenId = ownerCitizenId

    Wait(300)
    DoScreenFadeIn(1500)
end

function TeleportOut()
    local exit = Config.Apartment.ExitCoord
    local ped  = PlayerPedId()

    DoScreenFadeOut(500)

    lib.progressBar({
        duration = 2000,
        label = 'Leaving...',
        useWhileDead = false,
        canCancel = false,
        disable = { move = true, combat = true },
        anim = { dict = 'random@atmrobberygen@male', clip = 'idle_b' },
    })

    TriggerServerEvent("R6-apartment:server:exitApartment")

    Wait(500)
    SetEntityCoords(ped, exit.x, exit.y, exit.z)
    SetEntityHeading(ped, exit.w)

    isInsideApartment = false
    currentOwnerCitizenId = nil

    Wait(300)
    DoScreenFadeIn(1500)
end

RegisterNetEvent("R6-apartment:client:openInventory", function(stashId)
    exports.ox_inventory:openInventory('stash', stashId)
end)

RegisterNetEvent("R6-apartment:client:openQbStash", function(stashId, slots, weight)
    TriggerServerEvent("inventory:server:OpenInventory", "stash", stashId, {
        maxweight = weight,
        slots = slots,
    })
    TriggerEvent("inventory:client:SetCurrentStash", stashId)
end)

function Manage()
    xRegisterContext({
        id = 'apartment_main_menu',
        title = 'Manage Apartment',
        options = {
            {
                title = 'Upgrade Slots',
                description = 'Upgrade your apartment storage slots',
                icon = 'box',
                onSelect = function()
                    local slotsMenu = {}
                    for k, v in pairs(Config.Mange.Slots) do
                        local val = v
                        slotsMenu[#slotsMenu + 1] = {
                            title = 'Upgrade to ' .. val.slot .. ' slots',
                            description = 'Price: $' .. val.price,
                            icon = 'box',
                            onSelect = function()
                                TriggerServerEvent("R6-apartment:server:upgradeSlots", val.slot, val.price)
                            end,
                        }
                    end
                    slotsMenu[#slotsMenu + 1] = {
                        title = 'Go Back', icon = 'arrow-left',
                        onSelect = function() xShowContext('apartment_main_menu') end,
                    }
                    xRegisterContext({ id = 'apartment_slots_menu', title = 'Upgrade Slots', options = slotsMenu })
                    xShowContext('apartment_slots_menu')
                end,
            },
            {
                title = 'Upgrade Weight',
                description = 'Upgrade your apartment storage weight',
                icon = 'weight-hanging',
                onSelect = function()
                    local weightMenu = {}
                    for k, v in pairs(Config.Mange.Weight) do
                        local val = v
                        weightMenu[#weightMenu + 1] = {
                            title = 'Upgrade to ' .. math.floor(val.weight / 1000) .. ' KG',
                            description = 'Price: $' .. val.price,
                            icon = 'weight-hanging',
                            onSelect = function()
                                TriggerServerEvent("R6-apartment:server:upgradeWeight", val.weight, val.price)
                            end,
                        }
                    end
                    weightMenu[#weightMenu + 1] = {
                        title = 'Go Back', icon = 'arrow-left',
                        onSelect = function() xShowContext('apartment_main_menu') end,
                    }
                    xRegisterContext({ id = 'apartment_weight_menu', title = 'Upgrade Weight', options = weightMenu })
                    xShowContext('apartment_weight_menu')
                end,
            },
        }
    })
    xShowContext('apartment_main_menu')
end
