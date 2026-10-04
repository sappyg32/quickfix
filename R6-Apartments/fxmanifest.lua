fx_version 'cerulean'
game 'gta5'

description 'R6 Apartments'
version '1.0.0'
lua54 'yes'

escrow_ignore {
    'config.lua',
    'server/*.lua',
    'client/*.lua'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/cl_bridge.lua',
    'client/cl_main.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/sv_bridge.lua',
    'server/sv_main.lua'
}

dependency '/assetpacks'