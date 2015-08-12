listcomponent = require './list'

module.exports = (spec, components) ->
  list = listcomponent spec.spec, components

  odoql =
    init: (state, params) ->
      list.init state, params
    render: (dom, state, params) ->
      list.render dom, state, params
    resize: (dimensions) ->
      list.resize dimensions
    query: (params) ->
      spec.queries
    remove: (dom, state, params) ->
      list.remove dom, state, params
