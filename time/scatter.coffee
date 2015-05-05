###

Plot a series of dots on a chart.
Great for discontinuous like observations.

TODO: Same todos as line

###

d3 = require 'd3'
moment = require 'moment'
neighbours = require '../util/neighbours'

module.exports = (dom, options) ->
  { components, spec, dimensions, data, domain, hub, scale, axis } = options

  svg = dom.append 'g'

  data = data.map (d) ->
    result = time: d.time
    result[spec.field] = +d[spec.field]
    result

  data = data.filter (d) -> d[spec.field]?

  getNeighbours = neighbours data, (d) -> d.time

  start = getNeighbours(domain[0])[0]
  end = getNeighbours(domain[1])
  end = end[end.length-1]

  filteredData = data.filter (d) ->
    +d.time >= +start.time and +d.time <= +end.time

  value =
    x: (d) -> d.time
    y: (d) -> d[spec.field]

  dotContainer = svg.append 'g'

  dotContainer
    .selectAll ".dot"
    .data filteredData
    .enter()
    .append "circle"
    .attr "class", "dot"
    .attr "r", 3.5

  focus = svg
    .append 'g'
    .attr 'class', 'focus'

  focus
    .append 'text'
    .attr 'class', 'poi-y-val-shad'
    .attr 'display', 'none'
    .attr 'dy', '-0.3em'

  focus
    .append 'text'
    .attr 'class', 'poi-y-val'
    .attr 'display', 'none'
    .attr 'dy', '-0.3em'

  poi = null
  hub.on 'poi', (p) ->
    poi = p
    updatepoi()

  provideMax = ->
    d3.max filteredData, (d) -> d[spec.field]

  drawDots = (svg, data) ->
    svg.selectAll ".dot"
      .data data
      .attr "cx", (d) -> scale.x value.x d
      .attr "cy", (d) -> scale.y value.y d

  updatepoi = ->
    if !poi?
      focus
        .select '.poi-y-val-shad'
        .attr 'display', 'none'
      focus
        .select '.poi-y-val'
        .attr 'display', 'none'
      svg
        .selectAll '.dot'
        .data filteredData
        .style 'fill', 'rgb(20, 44, 88)'
      return

    Neighbours = neighbours filteredData, (d) -> d.time
    poiNeighbours = Neighbours poi

    d

    if poiNeighbours.length is 1
      d = poiNeighbours[0]
    else if +poiNeighbours[0].time < +domain[0]
      d = poiNeighbours[1]
    else if +poiNeighbours[1].time > +domain[1]
      d = poiNeighbours[0]
    else
      d0 = poiNeighbours[0]
      d1 = poiNeighbours[1]
      halfway = d0.time + (d1.time - d0.time)/2
      d = if poi.isBefore(halfway) then d0 else d1

    svg
      .selectAll '.dot'
      .data filteredData
      .style 'fill', (f) ->
        return 'rgb(216, 34, 42)' if f.time == d.time

    yValWidth = +focus.select('.poi-y-val').node().getComputedTextLength()

    if (dimensions[0] - (scale.x poi)-yValWidth) < yValWidth
      dxAttr = - yValWidth - 8
    else
      dxAttr = 8

    focus
      .select '.poi-y-val-shad'
      .attr 'display', null
      .attr 'transform', "translate(#{scale.x(d.time)}, #{scale.y(d[spec.field])})"
      .attr 'dx', dxAttr
      .text "#{d[spec.field].toPrecision(3)} (#{spec.units})"

    focus
      .select '.poi-y-val'
      .attr 'display', null
      .attr 'transform', "translate(#{scale.x(d.time)}, #{scale.y(d[spec.field])})"
      .attr 'dx', dxAttr
      .text "#{d[spec.field].toPrecision(3)} (#{spec.units})"

  resize = (dimensions) ->
    dimensions = dimensions

    drawDots dotContainer, filteredData

    updatepoi()

  resize: resize
  provideMax: provideMax
