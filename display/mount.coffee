###

Mount a component or group of components into the dom.
Keep them resized based on window resize events.

###

d3 = require 'd3'
domdimensions = require '../util/domdimensions'
debounce = require '../util/debounce'
extend = require 'extend'
listcomponent = require './list'

module.exports = (spec, components) ->
  list = listcomponent spec.spec, components
  mount =
    init: (state, params) ->
      list.init state, params
    update: (state, params) ->
      list.items.forEach (item) ->
        item.update && item.update(state, params)
    render: (dom, state, params) ->
      params = extend {}, params,
        dimensions: domdimensions dom

      list.render dom, state, params

      namespacedListener = 'resize' + '.' + params.id

      d3
        .select window
        .on namespacedListener, debounce 125, ->
          params.dimensions = domdimensions dom
          list.remove dom, state, params
          dom.innerHTML = ''
          list.render dom, state, params

      # hack to take into account the scrollbar if our content extends past the bottom
      setTimeout(->
        dimensions = domdimensions dom
        mount.resize dimensions
      , 1000)

    resize: (dimensions) ->
      list.resize dimensions
    query: (params) ->
      list.query params
    remove: (dom, state, params) ->
      list.remove dom, state, params
    list: list
