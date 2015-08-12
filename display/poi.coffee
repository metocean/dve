moment = require 'timespanner'
createhub = require '../util/hub'
listcomponent = require './list'
extend = require 'extend'

module.exports = (spec, components) ->
  list = listcomponent spec.spec, components
  init: (state, params) ->
    list.init state, params
  render: (dom, state, params) ->
    poi = null
    if moment.utc().isBetween params.domain[0], params.domain[1]
      tz = params.domain[0].tz()
      poi = moment.utc().tz tz
    list.render dom, state, params
    params.hub.emit 'poi', poi if params.hub?
  resize: (dimensions) ->
    list.resize dimensions
  query: (params) ->
    spec.queries
  remove: (dom, state, params) ->
    list.remove dom, state, params
