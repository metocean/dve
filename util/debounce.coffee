module.exports = (delay, fn) ->
  timeout = null
  ->
    clearTimeout timeout if timeout > -1
    timeout = setTimeout fn, delay