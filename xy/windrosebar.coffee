###

Plot a windrose with additional categories for each direction.

TODO: Work out how to position these xy visualisations.
TODO: Allow the different categories and values to be specified.

###


d3 = require 'd3'

calculate_layout = (dimensions) ->
  container = 
    width: 600

  legend = 
    height: 200
    width: 100
  legend.top = 0
  legend.bottom = legend.top + legend.height

  innerMargin = 
    top: 25
    right: 20
    bottom: 20
    left: 20

  inner =
    left: innerMargin.left
    right: container.width - legend.width - innerMargin.right
    top: innerMargin.top
  inner.width = inner.right - inner.left
  inner.height = inner.width
  inner.bottom = inner.top + inner.height
  container.height = inner.height + innerMargin.top + innerMargin.bottom

  container: container
  inner: inner
  legend: legend

module.exports = (spec, components) ->
  result =
    render: (dom, state, params) ->
      layout = calculate_layout params.dimensions
      console.log 'layout', layout

      svg = d3.select dom
        .append 'svg'
        .attr 'class', 'item windrose'


      console.log 'crunching data'
      nCategories = state.data.length
      groupedData = []
      for d, i in state.data
        obj = {}
        obj.angle = i * (360 / nCategories)
        obj.key = obj.angle
        obj.category = d[spec.category]
        obj.value = obj.category
        obj.speeds = []
        start = 0
        for bin, j in spec.bins
          sobj = {}
          sobj.index = j
          sobj.start = start
          start += +d[bin]
          sobj.end = start
          obj.speeds.push sobj
        obj.count = start
        groupedData.push obj

      dataMax = d3.max (d.count for d in groupedData)


      svg = d3.select dom
        .append 'svg'
        .attr 'class', 'item histogram'


      inner = svg
        .append 'g'
        .attr 'class', 'inner'
        .attr 'transform', "translate(#{layout.inner.left},#{layout.inner.top})"

      inner
        .append 'line'
        .attr 'class', 'divider'
        .attr 'x1', 0
        .attr 'x2', 0
        .attr 'y1', 0
        .attr 'y2', layout.container.height

      inner
        .append 'g'
        .attr 'class', 'x axis'
        .attr 'transform', "translate(0,#{layout.inner.height})"

      inner
        .append 'g'
        .attr 'class', 'y axis'

      clipId = "clip-#{Math.floor(Math.random() * 1000000)}"

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
        .domain [0, nCategories]

      textcolorScale = d3.scale.quantize()
        .range ['#000000', '#000000', '#ffffff', '#ffffff']
        .domain [0, nCategories]

      scale =
        x: d3.scale.ordinal().domain(groupedData.map (d) -> d.value)
        y: d3.scale.linear().domain([0, 1.1 * d3.max groupedData, (d) -> d.count])

      axis =
        x : d3.svg.axis().scale(scale.x).orient 'bottom'
        y : d3.svg.axis().scale(scale.y).orient 'left'

      chart
        .append 'text'
        .attr 'class', 'legend'
        .attr 'text-anchor', 'end'

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
        .data (d)-> d.speeds
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