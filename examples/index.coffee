###

Using DVE with browserify is recommended but not required.

###

d3 = require 'd3'
jsyaml = require 'js-yaml'
components = require 'dve'

d3.text '/test.yml', (error, spec) ->
  dom = document.querySelector 'body'
  spec = jsyaml.load spec
  scene = components.report dom,
    components: components
    spec: spec