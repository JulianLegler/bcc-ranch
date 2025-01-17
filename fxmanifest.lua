game 'rdr3'
fx_version "adamant"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'
author 'Jake2k4'

shared_scripts {
    'config.lua',
    'locale.lua',
    'languages/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
    'server/exports.lua',
    'server/AdminMenu.lua',
    'server/CooldownController.lua',
    'server/RanchDataModel.lua',
    'server/ServerRanchController.lua',
}

client_scripts {
    'client/functions.lua',
    'client/RanchModel.lua',
    'client/RanchController.lua',
    'client/menusetup/*.lua',
    'client/MainRanch.lua',
    'client/chores.lua',
    'client/AnimalManager/*.lua',
}

dependency {
    'vorp_core',
    'vorp_inventory',
    'bcc-utils',
    'vorp_character',
    'vorp_inputs',
    'bcc-minigames'
}


version '1.2.4'
