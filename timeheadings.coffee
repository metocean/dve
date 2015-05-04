class ERtimeheadings
  constructor: (svg, data, dimensions, options, domain) ->
    @svg = svg
    @data = data
    @calculate_layout dimensions
    @options = options
    @domain = domain

    @svg
      .append 'g'
      .attr 'class', 'title'
      .attr 'transform', "translate(#{@title.left},#{@title.top})"
      .append 'text'
      .attr 'class', 'infotext'
      .attr 'dy', 20
      .attr 'dx', 5

    @inner = @svg
      .append 'g'
      .attr 'class', 'inner'
      .attr 'transform', "translate(#{@canvas.left},#{@canvas.top})"

    @inner
      .append 'line'
      .attr 'class', 'divider'
      .attr 'x1', 0
      .attr 'x2', 0
      .attr 'y1', 0
      .attr 'y2', @dimensions.height

    @inner
      .append 'g'
      .attr 'class', 'axis'
      .attr "transform", "translate(0,#{-@canvas.top})"

    @scale = d3.time.scale().domain @domain

    @axis = d3
      .svg
      .axis()
      .scale @scale
      .ticks(d3.time.hour, 6)
      .tickFormat(d3.time.format '%H')

    @focus = @inner
      .append 'g'
      .attr 'class', 'focus'

    @focus
      .append 'line'
      .attr 'class', 'poi'
      .attr 'display', 'none'
      .attr 'y1', 0
      .attr 'y2', @dimensions.height

    @focus
      .append 'text'
      .attr 'class', 'poi-y-val-shad'
      .attr 'display', 'none'
      .attr 'dx', '-1.3em'
      .attr 'dy', 2

    @focus
      .append 'text'
      .attr 'class', 'poi-y-val'
      .attr 'display', 'none'
      .attr 'dx', '-1.3em'

    getTimezone = moment @scale.domain()[0]

    @svg
      .select '.infotext'
      .text @options.name + ' (GMT' + getTimezone.format('Z') + ')' # or ZZ for +1300

    @options.hub.on 'poi', @setpoi
    @options.hub.on 'window dimensions changed', @resize

    @poifsm =
      hide: =>
        return if @poi is null
        @options.hub.emit 'poi', null

      show: (x) =>
        range = @scale.range()
        return @poifsm.hide() if range[0] > x or range[1] < x
        d = @scale.invert x

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

    @focus
      .append 'rect'
      .attr 'class', 'foreground'
      .style 'fill', 'none'
      .on 'mousedown', @poifsm.mousedown
      .on 'mouseup', @poifsm.mouseup
      .call drag

    @resize dimensions

  calculate_layout: (dimensions) =>
    @margin =
      top: 0
      right: 0
      bottom: 0
      left: 0

    @dimensions =
      width: dimensions[0]
      height: 25

    @info =
      top: 0
      right: 0
      bottom: 0
      left: 200

    @title =
      top: 0
      right: @dimensions.width - @info.left
      bottom: 0
      left: 0
      height: @dimensions.height
      width: @info.left

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
      @poifsm.currentx = @scale @poi
      @focus
        .select 'line.poi'
        .attr 'display', 'none'

      @focus
        .select '.poi-y-val-shad'
        .attr 'display', 'none'

      @focus
        .select '.poi-y-val'
        .attr 'display', 'none'
      return

    @poifsm.currentx = @scale @poi

    @focus
      .select 'line.poi'
      .attr 'display', null
      .attr 'x1', @scale @poi
      .attr 'x2', @scale @poi

    if (@canvas.width - @scale @poi) < 20
      xVal = @canvas.width - 20
    else if (@canvas.left + @scale @poi) < 225
      xVal =  25
    else
      xVal = @scale @poi

    @focus
      .select '.poi-y-val-shad'
      .attr 'display', null
      .attr 'transform', "translate(#{xVal},#{@canvas.height - 6})"
      .text @poi.format('HH:mm')

    @focus
      .select '.poi-y-val'
      .attr 'display', null
      .attr 'transform', "translate(#{xVal},#{@canvas.height - 6})"
      .text @poi.format('HH:mm')

  resize: (dimensions) =>
    @calculate_layout dimensions

    @svg
      .attr 'width', @dimensions.width
      .attr 'height', @dimensions.height

    @scale.range [0, @canvas.width]

    @inner
      .select '.axis'
      .call (@axis.tickSize @canvas.height/4, -@canvas.height)

    @focus
      .select '.foreground'
      .attr 'height', @canvas.height
      .attr 'width', @canvas.width

    @inner.select '.axis .domain'
      .remove()

    @updatepoi()