###

Find the closest points in a dataset.

###

module.exports = (data, f) ->
  (value) ->
    value = +value
    if data.length is 0
      return []
    if +f(data[0]) > value
      return [data[0]]
    last = null
    for d in data
      fd = +f(d)
      return [d] if fd == value
      return [last, d] if value < fd
      last = d
    return [last]
