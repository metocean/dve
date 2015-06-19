###

Plot a frequency histogram with additional buckets for each point.

TODO: Work out how to position these xy visualisations.
TODO: Allow the different categories and values to be specified.

###

d3 = require 'd3'
zip = require '../util/zip'

calculate_layout = (dimensions) ->
  # Inner is the plot area, but doesn't include axes or labels
  inner = {}
  innerMargin = 
    top: 0
    right: 0
    bottom: 50
    left: 70

  # Container is the entire dom element d3 has to work with
  maxContainerWidth = 700
  container = {}

  # Container width is set already. That determines inner width, which determines the inner 
  # height, which determines the container width.
  container.width = Math.min(dimensions[0], maxContainerWidth)
  inner.right = container.width - innerMargin.right
  inner.left = 0 + innerMargin.left
  inner.width = inner.right - inner.left
  innerAspectRatio = 0.5
  inner.height = innerAspectRatio * inner.width
  inner.top = 0 + innerMargin.top
  inner.bottom = inner.top + inner.height
  container.height = inner.bottom + innerMargin.bottom

  dimensions: container
  inner: inner

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

      # Parse data
      xData = (d[spec.bin] for d in state.data)
      yData = (d[spec.field] for d in state.data)
      data = [0...xData.length].map (i) ->
        {x: xData[i], y: yData[i]}

      colorScale = d3.scale.quantize()
        .range ['#E4EAF1', '#D1D8E3', '#BEC7D5', '#ABB6C7', '#98A5B9', '#8594AB', '#73829E', '#607190', '#4D6082', '#3A4E74', '#273D66', '#142C58', '#122851', '#102448']
        .domain [0, 13]

      # Base element
      svg = d3.select dom
        .append 'svg'
        .attr 'class', 'item histogram'

      inner = svg.append 'g'
        .attr 'class', 'inner'
        .attr 'transform', "translate(#{layout.inner.left},#{layout.inner.top})"
      inner.append 'g'
        .attr 'class', 'x axis'
        .attr 'transform', "translate(0,#{layout.inner.height})"
      inner.append 'g'
        .attr 'class', 'y axis'
      inner.append 'text'
        .attr 'x', (layout.inner.width/2)
        .attr 'y',  layout.inner.height + 30
        .attr 'dy', '1em'
        .attr 'class', 'axis-label axis-label--x'
        .style 'text-anchor', 'middle'
        .text spec.xLabel
      inner.append 'text'
        .attr 'text-anchor', 'middle'
        .attr 'x', -1 * (layout.inner.height/2)
        .attr 'y', -50
        .attr 'dy', '1em'
        .attr 'transform', 'rotate(-90)'  # This also rotates the xy cooridnate system
        .attr 'class', 'axis-label axis-label--y'
        .text spec.yLabel

      chart = inner.append 'g'
        .attr 'class', 'chart'
      chart
        .append 'defs'
        .append 'rect'
        .attr 'x', 0
        .attr 'y', 0
        .attr 'width', layout.inner.width
        .attr 'height', layout.inner.height

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

      scale.x.rangeRoundBands([0, layout.inner.width], 0.05)
      scale.y.range [layout.inner.height, 0]

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
        .attr 'height', (d) -> layout.inner.height - scale.y(d.y)
        .style 'fill', (d) -> colorScale 3

      inner
        .select '.x.axis'
        .call axis.x

      inner
        .select '.y.axis'
        .call axis.y.tickSize -layout.inner.width, 0, 0

      inner
        .selectAll '.y.axis .tick line'
        .data scale.y.ticks axis.y.ticks()[0]
        .attr 'class', (d) ->
          if d is 0 then 'zero' else null

      inner
        .select '.y.axis .domain'
        .remove()

