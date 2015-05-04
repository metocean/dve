d3 = require 'd3'
moment = require 'moment'

calculate_layout = (dimensions) ->
  dimensions =
    width: dimensions[0]
    height: 120

  info =
    top: 0
    right: 0
    bottom: 3
    left: 200

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

module.exports = (dom, options) ->
  { components, spec, dimensions, data, domain, hub } = options
  layout = calculate_layout dimensions

  svg = d3.select dom
    .append 'svg'
    .attr 'class', 'item chart'

  svg
    .append 'g'
    .attr 'class', 'title'
    .append 'text'
    .attr 'class', 'infotext'
    .text spec.text
    .attr 'dy', 20
    .attr 'dx', 5

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

  scale =
    x: d3.time.scale().domain domain
    y: d3.scale.linear()

  axis =
    x: d3.svg.axis().scale(scale.x).orient("bottom").ticks(d3.time.hour)
    y: d3.svg.axis().scale(scale.y).orient("left").ticks(6)

  poi = null
  hub.on 'poi', (p) ->
    poi = p
    updatepoi()

  poifsm =
    hide: ->
      return if poi is null
      hub.emit 'poi', null

    show: (x) ->
      range = scale.x.range()
      return poifsm.hide() if range[0] > x or range[1] < x
      d = scale.x.invert x

      return if poi is d
      hub.emit 'poi', moment d

    update: ->
      x = d3.mouse(inner.node())[0]
      # Only update if enough drag
      if poifsm.startx?
        dist = Math.abs poifsm.startx - x
        return if dist < 10
      poifsm.startx = null
      poifsm.show x
    mousedown: ->
      x = d3.mouse(inner.node())[0]
      return poifsm.show x if !poifsm.currentx?
      poifsm.startx = x
    mouseup: ->
      return if !poifsm.startx?
      if !poifsm.currentx
        poifsm.startx = null
        return poifsm.hide()
      dist = Math.abs poifsm.startx - poifsm.currentx
      if dist < 10
        poifsm.startx = null
        return poifsm.hide()
      x = d3.mouse(inner.node())[0]
      poifsm.show x

  drag = d3.behavior.drag()
    .on 'drag', poifsm.update

  items = []
  maxDomains = []

  for s in spec.spec
    unless components[s.type]?
      return console.error "#{s.type} component not found"
    item = components[s.type] chart,
      components: components
      spec: s
      dimensions: dimensions
      hub: hub
      data: data
      domain: domain
      axis: axis
      scale: scale
    maxDomains.push item.provideMax()
    items.push item

  focus = inner
    .append 'g'
    .attr 'class', 'focus'

  focus
    .append 'line'
    .attr 'class', 'poi'
    .attr 'display', 'none'
    .attr 'y1', 0
    .attr 'y2', layout.canvas.height

  focus
    .append 'rect'
    .attr 'class', 'foreground'
    .style 'fill', 'none'
    .on 'mousedown', poifsm.mousedown
    .on 'mouseup', poifsm.mouseup
    .call drag

  updatepoi = ->
    if !poi?
      poifsm.currentx = scale.x poi
      focus
        .select 'line.poi'
        .attr 'display', 'none'
      return

    poifsm.currentx = scale.x poi

    focus
      .select 'line.poi'
      .attr 'display', null
      .attr 'x1', scale.x poi
      .attr 'x2', scale.x poi

  resize = (dimensions) ->
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

    updatepoi()

  resize dimensions
  resize: resize