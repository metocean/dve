###

Plot a single line on a chart.
Great for continuous data.
Not great for observations or direction.
Can include style for css based line styles.

TODO: Add points of interest such as local maxima and minima.
TODO: Push series labels to chart for overlapping adjustment.

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
    result[spec.field] = null if result[spec.field] is 0
    result

  line = svg
    .append 'path'
    .attr 'class', "#{spec.style} #{spec.type}"
    .attr 'd', ''

  labelShad = svg
    .append 'text'
    .attr 'class', 'label-shad'
    .attr 'text-anchor', 'start'
    .attr 'dy', 12
    .text "#{spec.text} (#{spec.units})"

  label = svg
    .append 'text'
    .attr 'class', 'label'
    .attr 'text-anchor', 'start'
    .attr 'dy', 12
    .text "#{spec.text} (#{spec.units})"

  #---creation: createpoi----#
  focus = svg
    .append 'g'
    .attr 'class', 'focus'

  focus
    .append 'circle'
    .attr 'class', 'poi-circle'
    .attr 'display', 'none'
    .attr 'r', 4

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

  data = data.filter (d) -> d[spec.field]?

  getNeighbours = neighbours data, (d) -> d.time

  start = getNeighbours(domain[0])[0]
  end = getNeighbours(domain[1])
  end = end[end.length-1]

  filteredData = data.filter (d) ->
    +d.time >= +start.time and +d.time <= +end.time

  poi = null
  hub.on 'poi', (p) ->
    poi = p
    updatepoi()

  provideMax = ->
    d3.max filteredData, (d) -> d[spec.field]

  updatepoi = ->
    if !poi?
      focus
        .select '.poi-circle'
        .attr 'display', 'none'
      focus
        .select '.poi-y-val-shad'
        .attr 'display', 'none'
      focus
        .select '.poi-y-val'
        .attr 'display', 'none'
      return

    yValWidth = +focus.select('.poi-y-val').node().getComputedTextLength()

    if (dimensions[0] - (scale.x poi)-yValWidth) < yValWidth
      dxAttr = - yValWidth - 8
    else
      dxAttr = 8

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

    focus
      .select '.poi-circle'
      .attr 'display', null
      .attr 'transform', "translate(#{scale.x(d.time)}, #{scale.y(d[spec.field])})"

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

    path =  d3.svg.line()
      .x (d) -> scale.x d.time
      .y (d) -> scale.y d[spec.field]

    line
      .attr 'd', path filteredData

    labelWidth = +label.node().getComputedTextLength()

    labelShad
      .attr 'transform', "translate(#{dimensions[0] - labelWidth}, #{scale.y(filteredData[filteredData.length-2][spec.field])})"

    label
      .attr 'transform', "translate(#{dimensions[0] - labelWidth}, #{scale.y(filteredData[filteredData.length-2][spec.field])})"

    updatepoi()

  resize: resize
  provideMax: provideMax
