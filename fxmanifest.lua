fx_version 'cerulean'
game 'gta5'

author 'Your Name'
description 'Apex Framework for advanced roleplay'
version '1.0.0'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'Config/config.lua',
    'server/functions.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

dependency 'oxmysql'
