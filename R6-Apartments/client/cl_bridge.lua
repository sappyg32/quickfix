function xAddTargetBox(name, coords, size, label, icon, distance, onSelect)
    if Config.FrameWork.Target == 'ox' then
        exports.ox_target:addBoxZone({
            coords = coords,
            size = size,
            options = {
                {
                    label = label,
                    icon = icon,
                    distance = distance,
                    onSelect = onSelect,
                }
            },
            name = name,
        })

    elseif Config.FrameWork.Target == 'qb' then
        exports['qb-target']:AddBoxZone(name, coords, size.x, size.y, {
            name = name,
            heading = 0,
            debugPoly = false,
            minZ = coords.z - (size.z / 2),
            maxZ = coords.z + (size.z / 2),
        }, {
            options = {
                {
                    icon = icon,
                    label = label,
                    distance = distance,
                    action = function()
                        onSelect()
                    end,
                }
            },
            distance = distance,
        })
    end
end

function xShowContext(id)
    lib.showContext(id)
end

function xRegisterContext(data)
    lib.registerContext(data)
end
