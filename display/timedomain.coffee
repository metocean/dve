d3 = require 'd3'
moment = require 'timespanner'
createhub = require '../util/hub'
listcomponent = require './list'
extend = require 'extend'

module.exports = (spec, components) ->
  list = listcomponent spec.spec, components

  timedomain =
    init: (state, params) ->
      data = state.data
      for d in data
        d.time = moment.utc d.time, moment.ISO_8601
      domain = d3.extent data, (d) -> d.time
      # yaml supports dates, so only parse if a string
      if spec.start?
        domain[0] = spec.start
        if typeof domain[0] is 'string'
          domain[0] = moment.spanner domain[0]
      if spec.end?
        domain[1] = spec.end
        if typeof domain[1] is 'string'
          domain[1] = moment.spanner domain[1]
      newparams = extend {}, params, domain: domain
      list.init state, newparams
    render: (dom, state, params) ->
      data = state.data
      for d in data
        d.time = moment.utc d.time, moment.ISO_8601
      domain = d3.extent data, (d) -> d.time
      # yaml supports dates, so only parse if a string
      if spec.start?
        domain[0] = spec.start
        if typeof domain[0] is 'string'
          domain[0] = moment.spanner domain[0]
      if spec.end?
        domain[1] = spec.end
        if typeof domain[1] is 'string'
          domain[1] = moment.spanner domain[1]
      newparams = extend {}, params, domain: domain
      list.render dom, state, newparams
    resize: (dimensions) ->
      list.resize dimensions
    query: (params) ->
      spec.queries
    remove: (dom, state, params) ->
      list.remove dom, state, params
