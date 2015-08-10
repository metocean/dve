d3 = require 'd3'
moment = require 'timespanner'
createhub = require '../util/hub'
listcomponent = require './list'
extend = require 'extend'

module.exports = (spec, components) ->
  list = listcomponent spec.spec, components
  render: (dom, state, params) ->
    range = null
    if moment.utc().isBetween params.domain[0], params.domain[1]
      tz = params.domain[0].tz()
      range = moment.utc().tz tz
    hub = createhub()
    newparams = extend {}, params,
      hub: hub
    list.render dom, state, newparams
    hub.emit 'range', range
  resize: (dimensions) ->
    list.resize dimensions
  query: (params) ->
    spec.queries
