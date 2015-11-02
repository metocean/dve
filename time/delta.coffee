###

Plot a single line on a chart.
Great for continuous data.
Not great for observations or direction.
Can include style for css based line styles.

TODO: Add points of interest such as local maxima and minima.
TODO: Push series labels to chart for overlapping adjustment.

###

d3 = require 'd3'
neighbours = require '../util/neighbours'

module.exports = (spec, components) ->
  svg = null
  line = null
  positive = null
  negative = null
  data = null
  scale = null
  prevdimensions = null

  selectdata = (state, params) ->
    data = state.data.filter (d) -> d[spec.field]?
    getNeighbours = neighbours data, (d) -> d.time
    start = getNeighbours(params.domain[0])[0]
    end = getNeighbours(params.domain[1])
    end = end[end.length-1]
    data.filter (d) ->
      +d.time >= +start.time and +d.time <= +end.time

  result =
    id: spec.id
    updateData: (state, params) ->
      selectdata state, params
      result.resize prevdimensions
    init: (state, params) ->
      if params.hub?
        params.hub.on 'state updated', (state) ->
          data = selectdata state, params
          result.resize prevdimensions
    render: (dom, state, params) ->
      svg = dom.append 'g'
      scale = params.scale

      positive = svg
        .append 'path'
        .attr 'class', "#{spec.style} #{spec.type} positive"
        .attr 'd', ''

      negative = svg
        .append 'path'
        .attr 'class', "#{spec.style} #{spec.type} negative"
        .attr 'd', ''

      line = svg
        .append 'path'
        .attr 'class', "#{spec.style} #{spec.type}"
        .attr 'd', ''

      data = selectdata state, params
      prevdimensions = params.dimensions
      result.resize prevdimensions

    provideMax: ->
      d3.max data, (d) -> Math.max d[spec.field], d[spec.delta]

    resize: (dimensions) ->
      prevdimensions = dimensions

      path =  d3.svg.line()
        .x (d) -> scale.x d.time
        .y (d) -> scale.y d[spec.delta]

      positivearea =  d3.svg.area()
        .x (d) -> scale.x d.time
        .y0 (d) -> scale.y d[spec.field]
        .y1 (d) -> scale.y Math.max d[spec.field], d[spec.delta]

      negativearea =  d3.svg.area()
        .x (d) -> scale.x d.time
        .y0 (d) -> scale.y Math.min d[spec.field], d[spec.delta]
        .y1 (d) -> scale.y d[spec.field]

      line.attr 'd', path data
      positive.attr 'd', positivearea data
      negative.attr 'd', negativearea data
