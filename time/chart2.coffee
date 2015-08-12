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
moment = require 'timespanner'
extend = require 'extend'
neighbours = require '../util/neighbours'

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

module.exports = (spec, components) ->
  svg = null
  inner = null
  scale = null
  axis = null
  focus = null
  updaterange = null
  range = null
  chart = null
  items = []
  maxDomains = []
  roundtoclosest = null
  Neighbours = null
  average = null
  result =
    init: (state, params) ->
      for s in spec.spec
        unless components[s.type]?
          return console.error "#{s.type} component not found"
        item = components[s.type] s, components
        item.init state, params if item.init?
        items.push item

      Neighbours = neighbours state.data, (d) -> d.time

      average = (p, fn) ->
        pn = Neighbours p
        total = 0
        for item in pn
          total += fn item
        total / pn.length

      params.hub.on 'range', (p) ->
        range = p
        updaterange()

      params.hub.on 'range nudge back', (p) ->
        return if !range?
        newp1 = range.p1
        p1index = null

        for d, i in state.data
          if d.time.isSame range.p1
            break if i is 0
            newp1 = state.data[i - 1].time.clone()
            break
        newp2 = range.p2
        p2index = null
        for d, i in state.data
          if d.time.isSame range.p2
            break if i is 0
            newp2 = state.data[i - 1].time.clone()
            break

        if newp1.isBefore params.domain[0]
          newp1 = params.domain[0].clone()

        if newp2.isBefore params.domain[0]
          newp2 = params.domain[0].clone()

        m = newp1 + (newp2 - newp1) / 2
        params.hub.emit 'range',
          p1: newp1
          p2: newp2
          m: m
          ma: average m, (d) -> d.wsp2

      params.hub.on 'range nudge forward', (p) ->
        return if !range?
        newp1 = range.p1
        p1index = null

        for d, i in state.data
          if d.time.isSame range.p1
            break if i is state.data.length - 1
            newp1 = state.data[i + 1].time.clone()
            break
        newp2 = range.p2
        p2index = null
        for d, i in state.data
          if d.time.isSame range.p2
            break if i is state.data.length - 1
            newp2 = state.data[i + 1].time.clone()
            break

        if newp1.isAfter params.domain[1]
          newp1 = params.domain[1].clone()

        if newp2.isAfter params.domain[1]
          newp2 = params.domain[1].clone()

        m = newp1 + (newp2 - newp1) / 2
        params.hub.emit 'range',
          p1: newp1
          p2: newp2
          m: m
          ma: average m, (d) -> d.wsp2
    render: (dom, state, params) ->
      layout = calculate_layout params.dimensions

      svg = d3.select dom
        .append 'svg'
        .attr 'class', 'item chart'

      svg
        .append 'g'
        .attr 'class', 'title'
        .append 'text'
        .attr 'class', 'infotext'
        .attr 'y', 0
        .attr 'x', 0
        .text spec.text
        .style 'fill', '#142c58'
        .attr 'dy', '20px'

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
        x: d3.time.scale().domain params.domain
        y: d3.scale.linear()

      axis =
        x: d3.svg.axis().scale(scale.x).orient("bottom").ticks(d3.time.hour)
        y: d3.svg.axis().scale(scale.y).orient("left").ticks(6)

      roundtoclosest = (p) ->
        pn = Neighbours p
        if pn.length is 1
          pn[0]
        else if +pn[0].time < +params.domain[0]
          pn[1]
        else if +pn[1].time > +params.domain[1]
          pn[0]
        else
          d0 = pn[0]
          d1 = pn[1]
          halfway = d0.time + (d1.time - d0.time)/2
          if p.isBefore(halfway) then d0 else d1

      rangefsm =
        hide: ->
          rangefsm.startx = null
          rangefsm.p1 = null
          rangefsm.p2 = null
          return if range is null
          params.hub.emit 'range', null

        show: (x) ->
          rangefsm.p2 = x
          p1d = moment scale.x.invert rangefsm.p1
          p2d = moment scale.x.invert rangefsm.p2

          p1 = roundtoclosest p1d
          p2 = roundtoclosest p2d

          m = p1.time + (p2.time - p1.time) / 2
          params.hub.emit 'range',
            p1: p1.time
            p2: p2.time
            m: m
            ma: average m, (d) -> d.wsp2

        getx: ->
          x = d3.mouse(inner.node())[0]
          datarange = scale.x.range()
          if datarange[0] > x
            x = datarange[0]
          if datarange[1] < x
            x = datarange[1]
          x

        update: ->
          x = rangefsm.getx()
          if rangefsm.startx?
            return if Math.abs(rangefsm.startx - x) < 10
            rangefsm.p1 = rangefsm.startx
            rangefsm.startx = null
          rangefsm.show x

        touchstart: ->
          x = rangefsm.getx()
          return rangefsm.startx = x if rangefsm.p1?
          rangefsm.p1 = x
          rangefsm.show x

        mousedown: ->
          if rangefsm.ignorenextdown
            rangefsm.ignorenextdown = null
            return
          x = rangefsm.getx()
          return rangefsm.startx = x if rangefsm.p1?
          rangefsm.p1 = x
          rangefsm.show x

        touchend: ->
          rangefsm.ignorenextdown = true

        mouseup: ->
          return rangefsm.hide() if rangefsm.startx?
          x = rangefsm.getx()
          rangefsm.show x

      drag = d3.behavior.drag()
        .on 'drag', rangefsm.update

      for item in items
        newparams = extend {}, params,
          axis: axis
          scale: scale
        item.render chart, state, newparams
        maxDomains.push item.provideMax()

      focus = inner
        .append 'g'
        .attr 'class', 'focus'

      focus
        .append 'line'
        .attr 'class', 'rangestart'
        .attr 'display', 'none'
        .attr 'y1', 0
        .attr 'y2', layout.canvas.height

      focus
        .append 'line'
        .attr 'class', 'rangeend'
        .attr 'display', 'none'
        .attr 'y1', 0
        .attr 'y2', layout.canvas.height

      focus
        .append 'line'
        .attr 'class', 'rangemiddle'
        .attr 'display', 'none'
        .attr 'y1', 0
        .attr 'y2', layout.canvas.height

      focus
        .append 'rect'
        .attr 'class', 'foreground'
        .style 'fill', 'none'
        .on 'touchstart', rangefsm.touchstart
        .on 'touchend', rangefsm.touchend
        .on 'mousedown', rangefsm.mousedown
        .on 'mouseup', rangefsm.mouseup
        .call drag

      updaterange = ->
        if !range?
          focus
            .select 'line.rangestart'
            .attr 'display', 'none'
          focus
            .select 'line.rangeend'
            .attr 'display', 'none'
          focus
            .select 'line.rangemiddle'
            .attr 'display', 'none'
          return

        focus
          .select 'line.rangestart'
          .attr 'display', null
          .attr 'x1', scale.x range.p1
          .attr 'x2', scale.x range.p1

        focus
          .select 'line.rangeend'
          .attr 'display', null
          .attr 'x1', scale.x range.p2
          .attr 'x2', scale.x range.p2

        focus
          .select 'line.rangemiddle'
          .attr 'display', null
          .attr 'x1', scale.x range.m
          .attr 'x2', scale.x range.m

      result.resize params.dimensions

      if range?
        params.hub.emit 'range',
          p1: range.p1
          p2: range.p2
          m: range.m
          ma: average range.m, (d) -> d.wsp2

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

      updaterange()
