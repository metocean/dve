listcomponent = require './list'
extend = require 'extend'

module.exports = (spec, components) ->
  list = listcomponent spec.spec, components

  select =
    init: (state, params) ->
      list.init state, params
    render: (dom, state, params) ->
      data = state[spec.dataset]
      state = extend {}, state, data: data
      list.render dom, state, params
    resize: (dimensions) ->
      list.resize dimensions
    query: (params) ->
      list.query params
    remove: (dom, state, params) ->
      list.remove dom, state, params
