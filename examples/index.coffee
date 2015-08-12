###

Using DVE with browserify is recommended but not required.

###

curve = (x) ->
  return 8 * x * x if x < 0.25
  return -8 * (x - 0.5) * (x - 0.5) + 1 if x < 0.75
  8 * (x - 1) * (x - 1)

d3 = require 'd3'
jsyaml = require 'js-yaml'
components = require 'dve'
moment = require 'timespanner'

fixdata = (data) ->
  for d in data
    d.time = moment d.time, 'DD-MM-YYYY HH:mm'
    d.wsp = parseFloat d.wsp
    d.wsp2 = parseFloat d.wsp
    d.wd = parseFloat d.wd
    d.gust = parseFloat d.gust

d3.csv '/example3.csv', (err, example3) ->
  fixdata example3
  d3.text '/test.yml', (error, spec) ->
    dom = document.querySelector '#root'
    spec = jsyaml.load spec
    scene = components[spec.type] spec, components

    scene.init { data: example3 }, {}
    scene.render dom, { data: example3 }, {}
    copiedrange = null
    scene.hub.on 'range', (range) ->
      copiedrange = range
      if !range?
        document.querySelector('input.value').value = ''
        document.querySelector('.editor').style.display = 'none'
      else
        document.querySelector('input.value').value = range.ma.toFixed 1
        document.querySelector('.editor').style.display = 'block'
    adjustrange = (n) ->
      return if !copiedrange?
      p1 = copiedrange.p1.format 'x'
      p2 = copiedrange.p2.format 'x'
      diff = p2 - p1
      for d in example3
        x = d.time.format('x') - p1
        if diff is 0
          continue if x isnt 0
          d.wsp2 += n
        x /= diff
        if x >= 0 and x <= 1
          d.wsp2 += n * curve x
      for d in example3
        d.wsp2 = Math.max 0, d.wsp2
    targetrange = (n) ->
      return if !copiedrange?
      p1 = copiedrange.p1.format 'x'
      p2 = copiedrange.p2.format 'x'
      diff = p2 - p1
      for d in example3
        x = d.time.format('x') - p1
        if diff is 0
          continue if x isnt 0
          d.wsp2 = n
        x /= diff
        if x >= 0 and x <= 1
          d.wsp2 += (n - d.wsp2) * curve x
      for d in example3
        d.wsp2 = Math.max 0, d.wsp2
    clearrange = ->
      return if !copiedrange?
      p1 = copiedrange.p1.format 'x'
      p2 = copiedrange.p2.format 'x'
      diff = p2 - p1
      for d in example3
        x = d.time.format('x') - p1
        if diff is 0
          continue if x isnt 0
          d.wsp2 = d.wsp
        x /= diff
        if x >= 0 and x <= 1
          d.wsp2 += (d.wsp - d.wsp2) * curve x
      for d in example3
        d.wsp2 = Math.max 0, d.wsp2
    document.onkeydown = (e) ->
      return if document.activeElement? and document.activeElement.tagName in ['TEXTAREA', 'INPUT']
      switch e.keyCode
        when 38
          adjustrange 1
          window.dispatchEvent new Event 'resize'
        when 40
          adjustrange -1
          window.dispatchEvent new Event 'resize'
        when 37
          scene.hub.emit 'range nudge back'
        when 39
          scene.hub.emit 'range nudge forward'
    document.querySelector('button.up').onclick = (e) ->
      adjustrange 1
      window.dispatchEvent new Event 'resize'
    document.querySelector('button.down').onclick = (e) ->
      adjustrange -1
      window.dispatchEvent new Event 'resize'
    document.querySelector('button.back').onclick = (e) ->
      scene.hub.emit 'range nudge back'
    document.querySelector('button.forward').onclick = (e) ->
      scene.hub.emit 'range nudge forward'
    document.querySelector('button.reset').onclick = (e) ->
      for d in example3
        d.wsp2 = d.wsp
      scene.hub.emit 'state updated', data: example3
    document.querySelector('form').onsubmit = (e) ->
      e.preventDefault()
      targetrange parseFloat document.querySelector('input.value').value
      window.dispatchEvent new Event 'resize'
    document.querySelector('button.clear').onclick = (e) ->
      clearrange()
      window.dispatchEvent new Event 'resize'
