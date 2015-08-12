###

Using DVE with browserify is recommended but not required.

###

curve = (x) ->
  return 8 * x * x if x < 0.25
  return -8 * (x - 0.5) * (x - 0.5) + 1 if x < 0.75
  8 * (x - 1) * (x - 1)

values = [
  "0.00"
  "0.05"
  "0.10"
  "0.15"
  "0.20"
  "0.25"
  "0.30"
  "0.35"
  "0.40"
  "0.45"
  "0.50"
  "0.55"
  "0.60"
  "0.65"
  "0.70"
  "0.75"
  "0.80"
  "0.85"
  "0.90"
  "0.95"
  "1.00"
]

for v in values
  console.log "#{v} - #{curve parseFloat v}"


d3 = require 'd3'
jsyaml = require 'js-yaml'
components = require 'dve'
moment = require 'timespanner'

fixdata = (data) ->
  for d in data
    d.time = moment d.time, 'DD-MM-YYYY HH:mm'
    d.wsp = parseFloat d.wsp
    d.wsp2 = parseFloat d.wsp2
    d.wd = parseFloat d.wd
    d.gust = parseFloat d.gust

d3.csv '/example3.csv', (err, example3) ->
  fixdata example3
  d3.text '/test.yml', (error, spec) ->
    dom = document.querySelector '#root'
    spec = jsyaml.load spec
    scene = components[spec.type] spec, components

    scene.render dom, { data: example3 }, {}
    adjustedrange = null
    scene.hub.on 'range', (range) ->
      return if !range?
      adjustedrange =
        if range.p1 <= range.p2
          p1: range.p1
          p2: range.p2
        else
          p1: range.p2
          p2: range.p1
    document.querySelector('button.up').onclick = (e) ->
      p1 = adjustedrange.p1.format 'x'
      p2 = adjustedrange.p2.format 'x'
      diff = p2 - p1
      for d in example3
        x = d.time.format('x') - p1
        if diff is 0
          if x is 0
            d.wsp2 += 1
          else
            continue
        x /= diff
        if x >= 0 and x <= 1
          d.wsp2 += curve x
      scene.hub.emit 'state updated', data: example3
    document.querySelector('button.down').onclick = (e) ->
      p1 = adjustedrange.p1.format 'x'
      p2 = adjustedrange.p2.format 'x'
      diff = p2 - p1
      for d in example3
        x = d.time.format('x') - p1
        if diff is 0
          if x is 0
            d.wsp2 -= 1
          else
            continue
        x /= diff
        if x >= 0 and x <= 1
          d.wsp2 -= curve x
      scene.hub.emit 'state updated', data: example3
