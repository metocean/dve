###

Plot a frequency histogram with additional buckets for each point.

TODO: Work out how to position these xy visualisations.
TODO: Allow the different categories and values to be specified.

###

d3 = require 'd3'
zip = require '../util/zip'

calculate_layout = (dimensions) ->
  innerMargin = 
    top: 10
    right: 0
    bottom: 60
    left: 70

  maxContainerWidth = 800
  minContainerWidth = 400
  innerAspectRatio = 0.5

  container = {}
  inner = {}
  container.width = Math.min(dimensions[0], maxContainerWidth)
  container.width = Math.max(container.width, minContainerWidth)
  inner.right = container.width - innerMargin.right
  inner.left = 0 + innerMargin.left
  inner.width = inner.right - inner.left
  inner.height = innerAspectRatio * inner.width
  inner.top = 0 + innerMargin.top
  inner.bottom = inner.top + inner.height
  container.height = inner.bottom + innerMargin.bottom

  container: container
  inner: inner
  innerMargin: innerMargin

module.exports = (spec, components) ->

  result =
    render: (dom, state, params) ->
      layout = calculate_layout params.dimensions

      # Parse data
      xData = (d[spec.bin] for d in state.data)
      yData = (d[spec.field] for d in state.data)
      data = [0...xData.length].map (i) ->
        {x: xData[i], y: yData[i]}


      svg = d3.select dom
        .append 'svg'
        .attr 'class', 'item histogram'
        .attr 'width', layout.container.width
        .attr 'height', layout.container.height

      scale =
        x: d3.scale.ordinal().domain(xData)
        y: d3.scale.linear().domain([0, 1.1 * d3.max(yData)])
      scale.x.rangeRoundBands([0, layout.inner.width], 0.05)
      scale.y.range [layout.inner.height, 0]
      axis =
        x: d3.svg.axis().scale(scale.x).orient 'bottom'
        y: d3.svg.axis().scale(scale.y).orient 'left'

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
        .attr 'y',  layout.inner.height + layout.innerMargin.bottom - 25  # Not sure why this isn't 20...
        .attr 'dy', 20
        .attr 'class', 'axis-label axis-label--x'
        .style 'text-anchor', 'middle'
        .text spec.xLabel
      inner.append 'text'
        .attr 'text-anchor', 'middle'
        .attr 'x', -1 * (layout.inner.height/2)
        .attr 'y', -1 * layout.innerMargin.left
        .attr 'dy', '1em'
        .attr 'transform', 'rotate(-90)'  # This also rotates the xy cooridnate system
        .attr 'class', 'axis-label axis-label--y'
        .text spec.yLabel
      inner
        .select '.x.axis'
        .call axis.x
      inner
        .select '.y.axis'
        .call axis.y.tickSize -layout.inner.width, 0, 0
      inner
        .selectAll '.y.axis .tick line'
        .data scale.y.ticks axis.y.ticks()[0]
      inner
        .select '.y.axis .domain'
        .remove()

      chart = inner.append 'g'
        .attr 'class', 'chart'
      chart
        .append 'defs'
        .append 'rect'
        .attr 'x', 0
        .attr 'y', 0
        .attr 'width', layout.inner.width
        .attr 'height', layout.inner.height

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
        .style 'fill', '#4D6082'

