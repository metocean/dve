###

Plot a frequency histogram with additional buckets for each point.

TODO: Work out how to position these xy visualisations.
TODO: Allow the different categories and values to be specified.

###

d3 = require 'd3'
zip = require '../util/zip'

calculate_layout = (dimensions) ->
  dimensions =
    width: dimensions[0]/1.5
    height: 600

  info =
    top: 0
    right: 0
    bottom: 200
    left: 200

  title =
    top: 0
    right: dimensions.width - info.left
    bottom: 0
    left: 0
    height: dimensions.height
    width: info.left

  canvas =
    top: info.top
    right: info.right
    bottom: info.bottom
    left: info.left
    width: dimensions.width - info.left - info.right
    height: dimensions.height - info.top - info.bottom

  dimensions: dimensions
  info: info
  title: title
  canvas: canvas

module.exports = (spec, components) ->
  svg = null
  data = null
  filteredData = null
  inner = null
  scale = null
  axis = null
  chart = null
  groupedData = null
  colorScale = null
  textcolorScale = null

  result =
    render: (dom, state, params) ->
      layout = calculate_layout params.dimensions

      xData = (d[spec.bin] for d in state.data)
      yData = (d[spec.field] for d in state.data)
      data = [0...xData.length].map (i) ->
        {x: xData[i], y: yData[i]}


      colorScale = d3.scale.quantize()
        .range ['#E4EAF1', '#D1D8E3', '#BEC7D5', '#ABB6C7', '#98A5B9', '#8594AB', '#73829E', '#607190', '#4D6082', '#3A4E74', '#273D66', '#142C58', '#122851', '#102448']
        .domain [0, 13]

      svg = d3.select dom
        .append 'svg'
        .attr 'class', 'item histogram'
      svg
        .append 'g'
        .attr 'class', 'title'
        .attr 'transform', "translate(#{layout.title.left},#{layout.title.top})"
        .append 'text'
        .attr 'class', 'infotext'
        .text "#{spec.text}"
        .attr 'dy', 20
      svg
        .append 'g'
        .attr 'class', 'title'
        .attr 'transform', "translate(#{layout.title.left},50)"
        .append 'text'
        .attr 'class', 'infotext'
        .text "Source: #{spec.dataSource}"
        .attr 'dy', 20
      svg.append("a")
        .attr 'transform', "translate(#{layout.title.left},100)"
        .attr 'xlink:href', 'https://hcd.metoceanview.com'
        .append 'text'
        .attr 'class', 'infotext'
        .attr 'dy', 20
        .text 'Download'

      # X label
      svg.append 'text'
        .attr 'x', (layout.info.left + layout.canvas.width/2)
        .attr 'y',  layout.canvas.height + 50 
        .style 'text-anchor', 'middle'
        .text spec.xLabel

      # Y label
      svg.append 'text'
        .attr 'text-anchor', 'middle'
        .attr 'x', (-1 * layout.canvas.height / 2)
        .attr 'y', layout.info.left
        .attr 'dy', '-2em'
        .attr 'transform', 'rotate(-90)'
        .text spec.yLabel

      inner = svg
        .append 'g'
        .attr 'class', 'inner'
        .attr 'transform', "translate(#{layout.canvas.left},#{layout.canvas.top})"
      inner
        .append 'line'
        .attr 'class', 'divider'
        .attr 'x1', 0
        .attr 'x2', 0
        .attr 'y1', 0
        .attr 'y2', layout.dimensions.height
      inner
        .append 'g'
        .attr 'class', 'x axis'
        .attr 'transform', "translate(0,#{layout.canvas.height})"
      inner
        .append 'g'
        .attr 'class', 'y axis'

      chart = inner
        .append 'g'
        .attr 'class', 'chart'
      chart
        .append 'defs'
        .append 'rect'
        .attr 'x', '0'
        .attr 'y', '0'
        .attr 'width', layout.canvas.width
        .attr 'height', layout.canvas.height

      scale =
        x: d3.scale.ordinal().domain(xData)
        y: d3.scale.linear().domain([0, 1.1 * d3.max(yData)])

      axis =
        x : d3.svg.axis().scale(scale.x).orient 'bottom'
        y : d3.svg.axis().scale(scale.y).orient 'left'


      result.resize params.dimensions

    resize: (dimensions) ->
      layout = calculate_layout dimensions

      svg
        .attr 'width', layout.dimensions.width
        .attr 'height', layout.dimensions.height

      scale.x.rangeRoundBands([0, layout.canvas.width], 0.05)
      scale.y.range [layout.canvas.height, 0]

      bars = chart
        .selectAll '.bar'
        .data data
        .enter()
        .append 'g'
        .attr 'class', 'bar'
        .attr "transform", (d) -> "translate(" + scale.x(d.x) + "," + scale.y(d.y) + ")"

      bars.append("rect")
        .attr "x", 1
        .attr "width", scale.x.rangeBand()
        .attr 'height', (d) -> layout.canvas.height - scale.y(d.y)
        .style 'fill', (d) -> colorScale 3

      inner
        .select '.x.axis'
        .call axis.x

      inner
        .select '.y.axis'
        .call axis.y.tickSize -layout.canvas.width, 0, 0

      inner
        .selectAll '.y.axis .tick line'
        .data scale.y.ticks axis.y.ticks()[0]
        .attr 'class', (d) ->
          if d is 0 then 'zero' else null

      inner
        .select '.y.axis .domain'
        .remove()

