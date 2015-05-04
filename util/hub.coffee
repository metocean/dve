module.exports = ->
  hub_listeners = {}
  on: (id, listener) ->
    hub_listeners[id] = [] if !hub_listeners[id]?
    hub_listeners[id].push listener
  emit: (id, args...) ->
    return if !hub_listeners[id]?
    h args... for h in hub_listeners[id]
