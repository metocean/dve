###

Plot a windrose in bar chart format.

###


d3 = require 'd3'

calculate_layout = (dimensions, speczz, nBins) ->
  # Inner is the plot area, but doesn't include axes or labels
  inner = {}
  innerMargin = 
    top: 30
    right: 0
    bottom: 65
    left: 60

  # Container is the entire dom element d3 has to work with
  maxContainerWidth = 900
  minContainerWidth = 520
  container = {}

  # Container width is set already. That determines inner width, which determines the inner 
  # height, which determines the container width.
  container.width = Math.min(dimensions[0], maxContainerWidth)
  container.width = Math.max(container.width, minContainerWidth)
  container.right = container.width
  container.left = 0
  inner.right = container.right - innerMargin.right
  inner.left = 0 + innerMargin.left
  inner.width = inner.right - inner.left
  innerAspectRatio = 0.5
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
      angularBins = state.data.bins[0].labels
      radialBins = state.data.bins[1].labels
      nSegments = angularBins.length
      nBins = radialBins.length

      layout = calculate_layout params.dimensions, spec, nBins

      svg = d3.select dom
        .append 'svg'
        .attr 'class', 'item windrosebar'

      groupedData = []
      for row, i in state.data.data
        obj = {}
        obj.angle = i * 360 / angularBins.length
        obj.key = obj.angle
        obj.label = angularBins[i]
        obj.value = obj.label
        obj.data = []
        start = 0
        for cell, j in row
          sobj = {}
          sobj.index = j
          sobj.start = start
          start += cell
          sobj.end = start
          obj.data.push sobj
        obj.count = start
        groupedData.push obj


      dataMax = d3.max (d.count for d in groupedData)


      inner = svg
        .append 'g'
        .attr 'class', 'inner'
        .attr 'transform', "translate(#{layout.inner.left},#{layout.inner.top})"
      inner
        .append 'g'
        .attr 'class', 'x axis'
        .attr 'transform', "translate(0,#{layout.inner.height})"
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
        .attr 'width', layout.inner.width
        .attr 'height', layout.inner.height

      colorScale = d3.scale.quantize()
        .range ['#E4EAF1', '#D1D8E3', '#BEC7D5', '#ABB6C7', '#98A5B9', '#8594AB', '#73829E', '#607190', '#4D6082', '#3A4E74', '#273D66', '#142C58', '#122851', '#102448']
        .domain [0, nBins]

      scale =
        x: d3.scale.ordinal().domain(groupedData.map (d) -> d.value)
        y: d3.scale.linear().domain([0, 1.1 * d3.max groupedData, (d) -> d.count])

      axis =
        x : d3.svg.axis().scale(scale.x).orient 'bottom'
        y : d3.svg.axis().scale(scale.y).orient 'left'


      svg
        .attr 'width', layout.container.width
        .attr 'height', layout.container.height

      scale.x.rangeRoundBands([0, layout.inner.width], 0.05)
      scale.y.range [layout.inner.height, 0]

      bars = chart
        .selectAll '.bar'
        .data groupedData
        .enter()
        .append 'g'
        .attr 'class', 'bar'
        .attr 'transform', (d) -> "translate(#{scale.x d.value}, 0)"

      bars
        .selectAll 'rect'
        .data (d)-> d.data
        .enter()
        .append 'rect'
        .attr 'x', 0
        .attr 'y', (d) -> scale.y d.end
        .attr "width", scale.x.rangeBand()
        .attr 'height', (d) -> scale.y(d.start) - scale.y(d.end)
        .style 'fill', (d) -> colorScale d.index

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

      inner.append 'text'
        .attr 'x', (layout.inner.width/2)
        .attr 'y',  layout.inner.height + layout.innerMargin.bottom
        .attr 'dy', '-0.4em'  # Account for descenders
        .attr 'class', 'axis-label axis-label--x'
        .style 'text-anchor', 'middle'
        .text spec.xLabel + if spec.xUnits then " [#{state.data.bins[0].units}]" else ''

