fx_version 'bodacious'
games { 'gta5' }
lua54 "yes"

author "sobing"

description "racing feature design nopixel 4.0"

version '1.0'

client_scripts{
    'client/*.lua',
}

server_scripts {
  '@mysql-async/lib/MySQL.lua',
  'server/*.lua',
}

shared_scripts {
	'shared/cores.lua',
  'shared/config.lua'
}

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/script.js',
  'html/style.css',
  'html/*otf',
  'html/*png',
  'html/*mp3',
  'html/*wav',
  'html/*ttf',
  'html/*TTF',
  'images/*.png',
  'images/*.jpg',
  'images/*.webp',
  'images/*.mp4',
  'images/*.svg',
  'stream/*.ymf',
	'stream/*.ydr',
	'stream/*.ymap',
	'stream/*.ytyp',
}

data_file 'DLC_ITYP_REQUEST' 'stream/furkan.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/propfurkan.ydr'