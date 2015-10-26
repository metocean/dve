d3 = require 'd3'
jsyaml = require 'js-yaml'
components = require 'dve'
moment = require 'timespanner'



d3.json '/wsp-mean.json', (errData, data) ->
  d3.text '/spec.yml', (errSpec, spec) ->
    el = document.getElementById('histogram')
    spec = jsyaml.load spec
    scene = components[spec.type] spec, components
    scene.init {data: data}, {}
    scene.render el, data:data, {}





