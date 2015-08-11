createhub = require '../util/hub'
listcomponent = require './list'
extend = require 'extend'

module.exports = (spec, components) ->
  list = listcomponent spec.spec, components
  hub = createhub()
  render: (dom, state, params) ->
    newparams = extend {}, params, hub: hub
    list.render dom, state, newparams
  resize: (dimensions) ->
    list.resize dimensions
  query: (params) ->
    spec.queries
  hub: hub
