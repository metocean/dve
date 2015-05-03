class ERchart
  constructor: (svg, data, dimensions, options, domain) ->
    @svg = svg
    @data = data
    @calculate_layout dimensions
    @options = options
    @domain = domain

    @options.hub.on 'poi', @setpoi
    @options.hub.on 'window dimensions changed', @resize

    @svg
      .append 'g'
      .attr 'class', 'title'
      .append 'text'
      .attr 'class', 'infotext'
      .text @options.text
      .attr 'dy', 20
      .attr 'dx', 5

    @inner = @svg
      .append 'g'
      .attr 'class', 'inner'
      .attr 'transform', "translate(#{@canvas.left},#{@canvas.top})"

    @inner
      .append 'g'
      .attr 'class', 'x axis'
      .attr 'transform', "translate(0,#{@canvas.height})"

    @inner
      .append 'g'
      .attr 'class', 'y axis'

    clipId = "clip-#{Math.floor(Math.random() * 1000000)}"

    @chart = @inner
      .append 'g'
      .attr 'class', 'chart'
      .attr 'clip-path', "url(##{clipId})"

    @chart
      .append 'defs'
      .append 'clipPath'
      .attr 'id', clipId
      .append 'rect'
      .attr 'x', '0'
      .attr 'y', '0'

    @scale= {
      x : d3.time.scale().domain @domain
      y : d3.scale.linear()
    }

    @axis = {
      x : d3.svg.axis().scale(@scale.x).orient("bottom").ticks(d3.time.hour)
      y : d3.svg.axis().scale(@scale.y).orient("left").ticks(6)
    }

    @poifsm =
      hide: =>
        return if @poi is null
        @options.hub.emit 'poi', null

      show: (x) =>
        range = @scale.x.range()
        return @poifsm.hide() if range[0] > x or range[1] < x
        d = @scale.x.invert x

        return if @poi is d
        @options.hub.emit 'poi', moment d

      update: =>
        x = d3.mouse(@inner.node())[0]
        # Only update if enough drag
        if @poifsm.startx?
          dist = Math.abs @poifsm.startx - x
          return if dist < 10
        @poifsm.startx = null
        @poifsm.show x
      mousedown: =>
        x = d3.mouse(@inner.node())[0]
        return @poifsm.show x if !@poifsm.currentx?
        @poifsm.startx = x
      mouseup: =>
        return if !@poifsm.startx?
        if !@poifsm.currentx
          @poifsm.startx = null
          return @poifsm.hide()
        dist = Math.abs @poifsm.startx - @poifsm.currentx
        if dist < 10
          @poifsm.startx = null
          return @poifsm.hide()
        x = d3.mouse(@inner.node())[0]
        @poifsm.show x

    drag = d3.behavior.drag()
      .on 'drag', @poifsm.update

    @series = []
    @maxDomains = []

    for soption in @options.series

      g = @chart.append 'g'
      params =
        svg: g
        data: data
        scale: @scale
        axis: @axis
        dimensions: [@canvas.width, @canvas.height]
        hub: @options.hub
        domain: domain
      s = new window["SR#{soption.type}"] soption, params
      @series.push s
      @maxDomains.push s.provideMax()

    @focus = @inner
      .append 'g'
      .attr 'class', 'focus'

    @focus
      .append 'line'
      .attr 'class', 'poi'
      .attr 'display', 'none'
      .attr 'y1', 0
      .attr 'y2', @canvas.height

    @focus
      .append 'rect'
      .attr 'class', 'foreground'
      .style 'fill', 'none'
      .on 'mousedown', @poifsm.mousedown
      .on 'mouseup', @poifsm.mouseup
      .call drag

    @resize dimensions

  calculate_layout: (dimensions) =>
    @dimensions =
      width: dimensions[0]
      height: 120

    @info =
      top: 0
      right: 0
      bottom: 3
      left: 200

    @canvas =
      top: @info.top
      right: @info.right
      bottom: @info.bottom
      left: @info.left
      width: @dimensions.width - @info.left - @info.right
      height: @dimensions.height - @info.top - @info.bottom

  setpoi: (poi) =>
    @poi = poi
    @updatepoi()

  updatepoi: =>
    if !@poi?
      @poifsm.currentx = @scale.x @poi
      @focus
        .select 'line.poi'
        .attr 'display', 'none'
      return

    @poifsm.currentx = @scale.x @poi

    @focus
      .select 'line.poi'
      .attr 'display', null
      .attr 'x1', @scale.x @poi
      .attr 'x2', @scale.x @poi

  resize: (dimensions) =>
    @calculate_layout dimensions

    @svg
      .attr 'width', @dimensions.width
      .attr 'height', @dimensions.height

    @chart
      .select 'rect'
      .attr 'width', @canvas.width
      .attr 'height', @canvas.height

    @scale.y.domain [0, 1.1 * d3.max @maxDomains]

    @scale.x.range [0, @canvas.width]
    @scale.y.range [@canvas.height, 0]

    @inner
      .select '.x.axis'
      .call(
        @axis.x
          .tickSize -@canvas.height, 0, 0
          .tickFormat ''
      )

    @inner
      .selectAll '.x.axis .tick line'
      .data @scale.x.ticks @axis.x.ticks()[0]
      .attr 'class', (d) ->
        d = moment(d).format('HH')
        if d is '00'
          'major'
        else if d is '12'
          'minor'
        else
          'sub-minor'

    @inner
      .select '.y.axis'
      .call @axis.y.tickSize -@canvas.width, 0, 0

    @inner
      .select '.y.axis .tick text'
      .text ' '

    @inner
      .selectAll '.y.axis .tick line'
      .data @scale.y.ticks @axis.y.ticks()[0]
      .attr 'class', (d) ->
        if d is 0 then 'zero' else null

    @focus
      .select '.foreground'
      .attr 'height', @canvas.height
      .attr 'width', @canvas.width

    for s in @series
      s.resize [
        @canvas.width
        @canvas.height
      ]

    @updatepoi()