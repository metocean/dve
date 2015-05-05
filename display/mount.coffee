###

Mount a component or group of components into the dom.
Keep them resized based on window resize events.

TODO: Optional offset (e.g. remove hardcoded 42)

###

d3 = require 'd3'
windowdimensions = require '../util/windowdimensions'
debounce = require '../util/debounce'

getwindowdimensions = ->
  dimensions = windowdimensions()
  dimensions[0] -= 42
  dimensions

module.exports = (dom, options) ->
  { components, spec } = options

  dimensions = getwindowdimensions()

  unless spec instanceof Array
    spec = [spec]

  items = []
  for s in spec
    unless components[s.type]?
      return console.error "#{s.type} component not found"
    items.push components[s.type] dom,
      components: components
      spec: s
      dimensions: dimensions

  d3
    .select window
    .on 'resize', debounce 125, ->
      dimensions = getwindowdimensions()
      for i in items
        continue unless i.resize?
        i.resize dimensions
