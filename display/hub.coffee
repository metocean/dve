createhub = require '../util/hub'
listcomponent = require './list'
extend = require 'extend'

module.exports = (spec, components) ->
  list = listcomponent spec.spec, components
  hub = createhub()
  init: (state, params) ->
    newparams = extend {}, params, hub: hub
    list.init state, newparams
  render: (dom, state, params) ->
    newparams = extend {}, params, hub: hub
    list.render dom, state, newparams
  resize: (dimensions) ->
    list.resize dimensions
  query: (params) ->
    spec.queries
  remove: (dom, state, params) ->
    list.remove dom, state, params
  hub: hub
