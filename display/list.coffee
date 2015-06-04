###

List components.

###

module.exports = (spec, components) ->
  unless spec instanceof Array
    spec = [spec]

  items = []

  list =
    render: (dom, state, params) ->
      for s in spec
        unless components[s.type]?
          return console.error "#{s.type} component not found"
        item = components[s.type] s, components
        item.render dom, state, params
        items.push item
    resize: (dimensions) ->
      for i in items
        continue unless i.resize?
        i.resize dimensions
    query: (params) ->
      result = {}
      for item in items
        if item.query?
          for key, query of item.query params
            result[key] = query
      result
