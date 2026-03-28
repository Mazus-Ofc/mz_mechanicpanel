fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Mazus'
description 'Painel premium de mecânica para QBCore com orçamento, aprovação do proprietário e preview em câmera real.'
version '1.0.2'

ui_page 'html/index.html'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config/config.lua',
    'config/prices.lua',
    'shared/catalog.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/schema.lua',
    'server/core/bootstrap.lua',
    'server/core/state.lua',
    'server/core/helpers.lua',
    'server/core/vehicle.lua',
    'server/core/props.lua',
    'server/core/logs.lua',
    'server/core/sessions.lua',
    'server/core/orders.lua',
    'server/core/repairs.lua',
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies {
    'qb-core',
    'qb-inventory',
    'oxmysql'
}
