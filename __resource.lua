resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

description 'ESX Turtle POACHING'

client_scripts {
  '@es_extended/locale.lua',
  'locales/fr.lua',
  'config.lua',
  'client/main.lua',
}

server_scripts {
  '@es_extended/locale.lua',
  'locales/fr.lua',
  'config.lua',
  'server/main.lua',
}
