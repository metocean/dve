###

Plot a windrose with additional categories for each direction.

TODO: Work out how to position these xy visualisations.
TODO: Allow the different categories and values to be specified.

###


d3 = require 'd3'

calculate_layout = (dimensions) ->
  # dimensions =
  #   width: 700
  #   height: 300

  console.log 'rose dimensions', dimensions

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


      svg
        .attr 'width', layout.container.width
        .attr 'height', layout.container.height



      inner = svg
        .append 'g'
        .attr 'class', 'inner'
        .attr 'transform', "translate(#{layout.inner.left + layout.inner.width/2},#{layout.inner.top + layout.inner.height/2})"

      colorScale = d3.scale.quantize()
        .range ['#E4EAF1', '#D1D8E3', '#BEC7D5', '#ABB6C7', '#98A5B9', '#8594AB', '#73829E', '#607190', '#4D6082', '#3A4E74', '#273D66', '#142C58', '#122851', '#102448']
        .domain [0, nCategories]

      textcolorScale = d3.scale.quantize()
        .range ['#000000', '#000000', '#ffffff', '#ffffff']
        .domain [0, nCategories]

      console.log 'building scale'
      scale = d3
        .scale
        .linear()
        .domain [0, 1.1 * d3.max groupedData, (d) -> d.count]
        .range [0, layout.inner.width/2]

      diameter = (scale scale.domain()[1]) - 5

      circlecontainer = inner
        .append 'g'
        .attr 'class', 'circlecontainer'

      console.log 'making axis', axis
      axis = inner
        .selectAll '.axis'
        .data groupedData
        .enter()
        .append 'g'
        .attr 'class', 'axis'
        .attr 'transform', (d) -> "rotate(#{d.key})"

      console.log 'making arc', arc
      arc = (o) ->
        d3
        .svg
        .arc()
        .startAngle (d) ->(- o.width / 2) * Math.PI/180
        .endAngle (d) -> (+ o.width / 2) * Math.PI/180
        .innerRadius o.from
        .outerRadius o.to

      axis
        .append 'line'
        .attr 'class', 'spoke'
        .attr 'x1', scale 0
        .attr 'y1', scale 0
        .attr 'x2', scale 0
        .attr 'y2', layout.inner.width/2

      axis
        .append 'g'
        .attr 'transform', (d) -> "translate(#{scale 0},#{(layout.inner.height * (-0.53))})"
        .append 'text'
        .attr 'transform', (d) -> "rotate(#{-d.key})"
        .attr 'style', 'text-anchor: middle'
        .attr 'dy', '0.25em'
        .text (d) -> d.value

      console.log 'sevment', segment
      segment = inner
        .selectAll '.segment'
        .data groupedData
        .enter()
        .append 'g'
        .attr 'class', 'segment'
        .attr 'transform', (d) -> "rotate(#{d.key})"
        .selectAll 'path'
        .data (d) -> d.speeds
        .enter()
        .append 'path'
        .attr('d', arc
          width: 360 / nCategories * 0.8
          from: (d) -> scale d.start
          to: (d) -> scale d.end
        )
        .style 'fill', (d) -> colorScale d.index


      nTicks = 4
      radialScale = d3.scale
        .linear()
        .domain [0, nTicks]  # The number of 
        .range [0, dataMax]


      console.log 'making circles'
      for i in [1...nTicks+1]
        circlecontainer
          .append 'text'
          .text +radialScale(i).toPrecision(5)
          .attr 'x', 0
          .attr 'y', -(i * diameter / nTicks)
        circlecontainer
          .append 'circle'
          .attr 'cx', 0
          .attr 'cy', 0
          .attr 'r', i * diameter / nTicks
        
