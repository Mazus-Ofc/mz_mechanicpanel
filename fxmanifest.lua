fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Mazus'
description 'Painel premium de mecânica para QBCore com orçamento, aprovação do proprietário e preview em câmera real.'
version '1.0.0'

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
