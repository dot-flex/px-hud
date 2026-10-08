fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
game 'gta5'

author 'masked1337'
description 'PX HUD - ESX / QBCore / Qbox'
version '1.0.0'

dependency '/onesync'
shared_scripts { 'config.lua', 'locales/*.lua', 'shared/locale.lua', 'shared/framework.lua' }
server_scripts { 'server/framework.lua', 'server/main.lua' }
client_scripts { 'client/framework.lua', 'client/needs.lua', 'client/stress.lua', 'client/vehicle.lua', 'client/minimap.lua', 'client/notify.lua', 'client/waypoint.lua', 'client/postal.lua', 'client/main.lua' }
ui_page 'web/index.html'
nui_callback_strict_mode 'true'
files {
    'web/app.js',
    'web/assets/BarlowCondensed-Medium.ttf',
    'web/assets/OFL.txt',
    'web/assets/Saira-OFL.txt',
    'web/assets/Saira.ttf',
    'web/fontawesome/LICENSE.txt',
    'web/fontawesome/css/solid.css',
    'web/fontawesome/webfonts/fa-solid-900.woff2',
    'web/fonts/LICENSE.txt',
    'web/fonts/UcC73FwrK3iLTeHuS_nVMrMxCp50SjIa0ZL7SUc.woff2',
    'web/fonts/UcC73FwrK3iLTeHuS_nVMrMxCp50SjIa1ZL7.woff2',
    'web/fonts/UcC73FwrK3iLTeHuS_nVMrMxCp50SjIa1pL7SUc.woff2',
    'web/fonts/UcC73FwrK3iLTeHuS_nVMrMxCp50SjIa25L7SUc.woff2',
    'web/fonts/UcC73FwrK3iLTeHuS_nVMrMxCp50SjIa2JL7SUc.woff2',
    'web/fonts/UcC73FwrK3iLTeHuS_nVMrMxCp50SjIa2ZL7SUc.woff2',
    'web/fonts/UcC73FwrK3iLTeHuS_nVMrMxCp50SjIa2pL7SUc.woff2',
    'web/fonts/fonts.css',
    'web/index.html',
    'web/notify.css',
    'web/notify.js',
    'web/style.css'
}
