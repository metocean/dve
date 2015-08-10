###

Using DVE with browserify is recommended but not required.

###

d3 = require 'd3'
jsyaml = require 'js-yaml'
components = require 'dve'
example2 = require './example2'
moment = require 'timespanner'

for d in example2
  d.time = moment d.time, 'DD-MM-YYYY HH:mm'

d3.text '/test.yml', (error, spec) ->
  dom = document.querySelector '#root'
  spec = jsyaml.load spec
  scene = components[spec.type] spec, components

  scene.render dom, { example2: example2 }, {}
