###

Add a series plotting area.

TODO: Add height as an attribute so it's not hardcoded
TODO: Region series for areas. E.g. probabilities, min and max.

- type: chart
  text: Wind Speed
  spec:
  - type: line
    style: primary
    text: Wind Speed 10m
    field: wsp
    units: kts
  - type: line
    style: secondary
    text: Gust 10m
    field: gst
    units: kts

###


d3 = require 'd3'
extend = require 'extend'
moment = require 'moment-timezone'
chrono = require 'chronological'
moment = chrono moment
require 'd3-chronological'

calculate_layout = (dimensions) ->
  dimensions =
    width: dimensions[0]
    height: 120

  info =
    top: 0
    right: 0
    bottom: 3
    left: 20

  canvas =
    top: info.top
    right: info.right
    bottom: info.bottom
    left: info.left
    width: dimensions.width - info.left - info.right
    height: dimensions.height - info.top - info.bottom

  dimensions: dimensions
  info: info
  canvas: canvas

module.exports = (spec, components) ->
  svg = null
  inner = null
  scale = null
  axis = null
  focus = null
  data = null
  chart = null
  items = []
  maxDomains = []
  result =
    init: (state, params) ->
      for s in spec.spec
        unless components[s.type]?
          return console.error "#{s.type} component not found"
        newparams = extend {}, params,
          axis: axis
          scale: scale
        item = components[s.type] s, components
        item.init state, params if item.init?
        items.push item
    update: (state, params) ->
      newparams = extend {}, params,
        axis: axis
        scale: scale
      items.forEach (item) ->
        item.update && item.update(state, newparams)
    render: (dom, state, params) ->
      layout = calculate_layout params.dimensions

      svg = d3.select dom
        .append 'svg'
        .attr 'class', 'item chart'

      inner = svg
        .append 'g'
        .attr 'class', 'inner'
        .attr 'transform', "translate(#{layout.canvas.left},#{layout.canvas.top})"

      inner
        .append 'g'
        .attr 'class', 'x axis'
        .attr 'transform', "translate(0,#{layout.canvas.height})"

      inner
        .append 'g'
        .attr 'class', 'y axis'

      clipId = "clip-#{Math.floor(Math.random() * 1000000)}"

      chart = inner
        .append 'g'
        .attr 'class', 'chart'
        .attr 'clip-path', "url(##{clipId})"

      chart
        .append 'defs'
        .append 'clipPath'
        .attr 'id', clipId
        .append 'rect'
        .attr 'x', '0'
        .attr 'y', '0'

      everyDay = moment()
        .tz('Australia/Sydney')
        .startOf('d')
        .every(1, 'd')

      scale =
        x: d3.chrono.scale('Australia/Sydney').domain(params.domain).nice(everyDay)
        y: d3.scale.linear()
      axis =
        x: d3.svg.axis().scale(scale.x).orient("bottom")
        y: d3.svg.axis().scale(scale.y).orient("left").ticks(6)

      for item in items
        newparams = extend {}, params,
          axis: axis
          scale: scale
        item.render chart, state, newparams
        maxDomains.push item.provideMax()

      focus = inner
        .append 'g'
        .attr 'class', 'focus'

      result.resize params.dimensions

    resize: (dimensions) ->
      layout = calculate_layout dimensions

      svg
        .attr 'width', layout.dimensions.width
        .attr 'height', layout.dimensions.height

      chart
        .select 'rect'
        .attr 'width', layout.canvas.width
        .attr 'height', layout.canvas.height

      scale.y.domain [0, 1.1 * d3.max maxDomains]

      scale.x.range [0, layout.canvas.width]
      scale.y.range [layout.canvas.height, 0]

      inner
        .select '.x.axis'
        .call(
          axis.x
            .tickSize -layout.canvas.height, 0, 0
            .tickFormat ''
        )

      inner
        .selectAll '.x.axis .tick line'
        .data scale.x.ticks axis.x.ticks()[0]
        .attr 'class', (d) ->
          d = moment(d).format('HH')
          if d is '00'
            'major'
          else if d is '12'
            'minor'
          else
            'sub-minor'

      inner
        .select '.y.axis'
        .call axis.y.tickSize -layout.canvas.width, 0, 0

      inner
        .select '.y.axis .tick text'
        .text ' '

      inner
        .selectAll '.y.axis .tick line'
        .data scale.y.ticks axis.y.ticks()[0]
        .attr 'class', (d) ->
          if d is 0 then 'zero' else null

      focus
        .select '.foreground'
        .attr 'height', layout.canvas.height
        .attr 'width', layout.canvas.width

      for i in items
        continue unless i.resize?
        i.resize [
          layout.canvas.width
          layout.canvas.height
        ]
