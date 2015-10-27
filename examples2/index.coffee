d3 = require 'd3'
jsyaml = require 'js-yaml'
components = require 'dve'
moment = require 'timespanner'



d3.json '/data/wsp-mean.json', (errData, data) ->
  d3.text '/specs/histogram.yml', (errSpec, spec) ->
    el = document.getElementById('histogram')
    spec = jsyaml.load spec
    scene = components[spec.type] spec, components
    scene.init {data: data}, {}
    scene.render el, data:data, {}


d3.json '/data/wsp-count.json', (errData, data) ->
  d3.text '/specs/table.yml', (errSpec, spec) ->
    el = document.getElementById('table')
    spec = jsyaml.load spec
    scene = components[spec.type] spec, components
    scene.init {data: data}, {}
    scene.render el, data:data, {}


d3.json '/data/wsp-rose.json', (errData, data) ->
  d3.text '/specs/windrose.yml', (errSpec, spec) ->
    el = document.getElementById('windrose')
    spec = jsyaml.load spec
    scene = components[spec.type] spec, components
    scene.init {data: data}, {}
    scene.render el, data:data, {}

d3.json '/data/wsp-rose.json', (errData, data) ->
  d3.text '/specs/windrosebar.yml', (errSpec, spec) ->
    el = document.getElementById('windrosebar')
    spec = jsyaml.load spec
    scene = components[spec.type] spec, components
    scene.init {data: data}, {}
    scene.render el, data:data, {}


