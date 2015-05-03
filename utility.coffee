# Extend moment.duration to include 3m, 4h, 9d
old_moment_duration = moment.duration
moment.duration = ->
  return old_moment_duration.apply null, arguments if arguments.length isnt 1 or typeof arguments[0] isnt 'string'
  unit = arguments[0][-1...]
  ord = arguments[0][...-1]
  old_moment_duration parseFloat(ord), unit

# Add support for cycles
moment.cycle = (cycle) ->
  expand: (domain) ->
    index = 0
    current = domain[0].clone()
    current.add cycle.offset if cycle.offset?
    results = []
    while current.isBefore domain[1]
      results.push
        index: index
        start: current.clone()
        end: current.clone().add cycle.duration
      current.add cycle.every
      index++
    results

# Get the screen width and height
window.getDimensions = ->
  documentElement = document.documentElement
  body = document.getElementsByTagName('body')[0]
  [
    parseInt window.innerWidth || documentElement.clientWidth || body.clientWidth
    -2 + parseInt window.innerHeight || documentElement.clientHeight|| body.clientHeight
  ]

debounce = (delay, fn) ->
  timeout = null
  ->
    clearTimeout timeout if timeout > -1
    timeout = setTimeout fn, delay

hub_listeners = {}
hub =
  on: (id, listener) ->
    hub_listeners[id] = [] if !hub_listeners[id]?
    hub_listeners[id].push listener
  emit: (id, args...) ->
    return if !hub_listeners[id]?
    h args... for h in hub_listeners[id]

neighbours = (data, f) ->
  (value) ->
    value = +value
    return [] if data.length is 0 or +f(data[0])> value or +f(data[data.length-1]) < value
    last = null
    for d in data
      fd = +f(d)
      return [d] if fd == value
      return [last, d] if value < fd
      last = d
