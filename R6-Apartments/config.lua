Config = {}

Config.FrameWork = {
    Type = "qb",          -- Which framework your server runs on (qb / qbx / esx)
    Target = "ox",         -- Which target system you use for interactions (ox_target or qb-target)
    Inventory = "ox",       -- Which inventory system you use for the stash (ox_inventory or qb-inventory)
}

Config.Interact = {
    -- Coordinates for each interaction point inside/outside the apartment
    Enter    = vec3(-269.71, -961.29, 31.54),   -- Where players interact to enter the apartment
    Exit     = vec3(-1457.75, -530.52, 56.94),  -- Where players interact to leave the apartment
    Manage   = vec3(-263.66, -974.96, 109.95),  -- Where the owner can manage/upgrade the apartment
    Wardrobe = vec3(-1467.91, -537.60, 50.73),  -- Where players can change their outfit
    Storage  = vec3(-1457.75, -530.52, 56.94),  -- Where players can open the apartment stash
}

Config.Apartment = {
    EnterCoord = vec4(-1451.32, -523.44, 56.93, 37.00),  -- Coordinates the player teleports to when entering
    ExitCoord  = vec4(-271.06, -957.73, 31.22, 303.88),  -- Coordinates the player teleports to when exiting
    Storage    = { slots = 30, weight = 150000 },         -- Default stash size for new players
}

Config.VisitRequestTimeout = 30 -- How many seconds the owner has to accept/decline a visit request before it expires

Config.Mange = {
    Slots = {
        -- Each tier upgrades the stash to a new slot amount for a price
        Menu1 = { slot = 40, price = 250  },
        Menu2 = { slot = 50, price = 500  },
        Menu3 = { slot = 50, price = 750  },
        Menu4 = { slot = 70, price = 1000 },
    },
    Weight = {
        -- Each tier upgrades the stash weight limit for a price
        Menu1 = { weight = 175000, price = 250  },
        Menu2 = { weight = 200000, price = 500  },
        Menu3 = { weight = 225000, price = 750  },
        Menu4 = { weight = 250000, price = 1000 },
    },
}