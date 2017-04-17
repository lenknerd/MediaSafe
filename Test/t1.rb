#!/usr/bin/ruby -w

require '../Shared/MediaSafeTools.rb'
require '../Server/MediaSafeServe.rb'


puts 'Okay required stuff...'

a = gets

`curl localhost:5678/`

b = gets

puts 'Done.'
