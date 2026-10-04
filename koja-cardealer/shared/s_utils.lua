-- ============================================================================
--  KOJA_CARDEALER -> GARAGE BRIDGE (ESX / QBCore)
--  Replaces the old SaveVehicleToGarage row insert.
--
--  The old insert only wrote (owner/identifier, plate, vehicle, state) which is
--  the ESX default owned_vehicles layout. Lunar Garage (and most modern garages)
--  read the row with the same column names the framework itself uses:
--
--      ESX     : owner, plate, vehicle, type, job, stored
--      QBCore  : citizenid, plate, mods, garage, state, vehicle, type, ...
--
--  Missing 'stored' (or stored = 0) makes the vehicle show up as IMPOUNDED
--  instead of stored in the garage; that is why the car appeared "registered to
--  you" but was never listed in the garage menu.
-- ============================================================================

if IsDuplicityVersion() then
    -- Identifier lookup: prefer the framework helper, fall back to the raw ESX
    -- identifier so an older core build still works.
    local function resolveIdentifier(source, xPlayer)
        local identifier
        if KojaLib and KojaLib.Server and KojaLib.Server.GetPlayerIdentifier then
            identifier = KojaLib.Server.GetPlayerIdentifier(source)
        end
        if not identifier and xPlayer then
            if type(xPlayer) == 'table' then
                identifier = xPlayer.identifier
            elseif type(xPlayer) == 'string' then
                identifier = xPlayer
            end
        end
        return identifier
    end

    -- ESX owner column type detection (VARCHAR(60) licence vs INT identifier).
    -- Detected once, cached for the session.
    local ownerIsInt = nil
    local ownerCheckStarted = false

    local function detectOwnerColumn()
        if ownerIsInt ~= nil or ownerCheckStarted then return end
        ownerCheckStarted = true
        MySQL.query('SELECT owner FROM owned_vehicles LIMIT 1', {}, function(rows)
            local sample = rows and rows[1] and rows[1].owner
            ownerIsInt = (sample ~= nil and tostring(sample):match('^%d+$') ~= nil)
        end)
    end

    ---@param data table { player, source, identifier, vehicle = { name, plate, price, payment } }
    SaveVehicleToGarage = function(data)
        if not data then return end
        local vehicle = data.vehicle or {}
        local model = vehicle.name
        local plate = vehicle.plate
        if not model or not plate then
            print('[KOJA_CARDEALER] SaveVehicleToGarage called without model/plate, aborting')
            return
        end

        local xPlayer = data.player
        local source = data.source or (type(xPlayer) == 'table' and xPlayer.source) or nil
        local identifier = data.identifier
        if not identifier and source then
            identifier = resolveIdentifier(source, xPlayer)
        end

        local props = json.encode({ model = joaat(model), plate = plate })
        -- 1 = stored in a garage, 0 = out / impounded
        local stored = 1

        local function logPurchase()
            local logData = {
                message = string.format("**Player:** %s\n**Purchased Vehicle**\n**Vehicle Model:** %s\n**License Plate:** %s\n**Price:** %s",
                    source and GetPlayerName(source) or tostring(identifier), model, plate, vehicle.price),
                title = 'Vehicle Purchase',
                footertext = 'KOJA_CARDEALER'
            }
            KojaLib.Server.LogMessage(logData, 'cardealer')
        end

        if KojaLib.Framework == 'qb' then
            local citizenid = identifier
            if source and QBCore then
                local qbPlayer = QBCore.Functions.GetPlayer(source)
                citizenid = (qbPlayer and qbPlayer.PlayerData and qbPlayer.PlayerData.citizenid) or identifier
            end
            MySQL.insert(
                'INSERT INTO player_vehicles (citizenid, plate, vehicle, mods, garage, state, type, jobVehicle) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                { citizenid, plate, props, props, 'OUT', stored, 'car', 0 },
                function() logPurchase() end
            )
        else
            detectOwnerColumn()
            local owner = identifier
            if ownerIsInt then owner = tonumber(identifier) or identifier end

            -- Modern ESX layout - what Lunar Garage and esx_garage expect.
            MySQL.insert(
                'INSERT INTO owned_vehicles (owner, plate, vehicle, type, job, stored) VALUES (?, ?, ?, ?, ?, ?)',
                { owner, plate, props, 'car', nil, stored },
                function(rowsChanged)
                    -- Fallback for old / stripped owned_vehicles tables.
                    if rowsChanged and rowsChanged > 0 then
                        logPurchase()
                        return
                    end
                    MySQL.insert(
                        'INSERT INTO owned_vehicles (owner, plate, vehicle, state) VALUES (?, ?, ?, ?)',
                        { owner, plate, props, stored },
                        function(rowsChanged2)
                            if rowsChanged2 and rowsChanged2 > 0 then
                                logPurchase()
                                return
                            end
                            MySQL.insert(
                                'INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (?, ?, ?)',
                                { owner, plate, props },
                                function() logPurchase() end
                            )
                        end
                    )
                end
            )
        end
    end

    exports('SaveVehicleToGarage', SaveVehicleToGarage)
end
