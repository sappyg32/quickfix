local ESX = exports['es_extended']:getSharedObject()

local shopCoords = vec4(-210.93, -1323.63, 30.62, 213.57)
local repairPrice = 500
local blip = nil
local isNearShop = false

-- Map blip
CreateThread(function()
    blip = AddBlipForCoord(shopCoords.x, shopCoords.y, shopCoords.z)
    SetBlipSprite(blip, 72)            -- wrench / LS Customs style icon
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.9)
    SetBlipColour(blip, 5)             -- yellow
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Repair Shop')
    EndTextCommandSetBlipName(blip)
end)

-- Draw marker + prompt when close
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local dist = #(coords - vector3(shopCoords.x, shopCoords.y, shopCoords.z))

        if dist < 15.0 then
            sleep = 0
            DrawMarker(1, shopCoords.x, shopCoords.y, shopCoords.z - 1.0,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                2.0, 2.0, 1.0,
                255, 200, 0, 100,
                false, false, 2, false, nil, nil, false)

            if dist < 2.0 then
                if not isNearShop then
                    isNearShop = true
                    ESX.ShowHelpNotification(
                        ('Press ~INPUT_CONTEXT~ to repair your vehicle for ~g~$%s~s~'):format(repairPrice)
                    )
                end

                if IsControlJustReleased(0, 38) then -- E
                    TriggerServerEvent('ls_customs_repair:tryRepair', repairPrice)
                end
            else
                isNearShop = false
            end
        else
            isNearShop = false
        end

        Wait(sleep)
    end
end)

-- Perform the repair
RegisterNetEvent('ls_customs_repair:doRepair', function()
    local playerPed = PlayerPedId()

    if not IsPedInAnyVehicle(playerPed, false) then
        ESX.ShowNotification('You must be inside a vehicle to repair it.')
        return
    end

    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if GetPedInVehicleSeat(vehicle, -1) ~= playerPed then
        ESX.ShowNotification('You must be the driver to repair this vehicle.')
        return
    end

    ESX.ShowNotification('Repairing your vehicle...')
    SetVehicleOnGroundProperly(vehicle)

    -- Visual/feel: brief wait, then restore
    Wait(2000)

    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleDirtLevel(vehicle, 0.0)

    ESX.ShowNotification('Your vehicle has been repaired.')
end)
