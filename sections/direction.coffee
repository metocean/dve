class ERdirection
  constructor: (svg, data, dimensions, options, domain) ->
    @svg = svg
    @calculate_layout dimensions
    @options = options
    @domain = domain

    @data = data.map (d) ->
      result = time: d.time
      result[options.field] = +d[options.field]
      result

    @svg
      .append 'g'
      .attr 'class', 'title'
      .attr 'transform', "translate(#{@title.left},#{@title.top})"
      .append 'text'
      .attr 'class', 'infotext'
      .text @options.text
      .attr 'dy', 18
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

    @filteredData = @data.filter (d) =>
      +d.time >= +@domain[0] and +d.time <= +@domain[1]

    @scale = d3.time.scale().domain @domain
      .range [0, @canvas.width]

    @create_directions()

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
      .append 'circle'
      .attr 'class', 'arrow-background'
      .attr 'r', 25
      .attr 'display', 'none'

    @focus
      .append 'g'
      .attr 'class', 'foc-section'
      .attr 'display', 'none'

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
        @options.hub.emit 'poi', moment.utc d

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
      .attr 'height', @canvas.height
      .attr 'width', @canvas.width
      .style 'fill', 'none'
      .on 'mousedown', @poifsm.mousedown
      .on 'mouseup', @poifsm.mouseup
      .call drag

    @resize dimensions

  calculate_layout: (dimensions) =>
    @dimensions =
      width: dimensions[0]
      height: 60

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
      @focus
        .select 'line.poi'
        .attr 'display', 'none'
      @focus
        .select '.foc-section'
        .attr 'display', 'none'
      @focus
        .select '.arrow-background'
        .attr 'display', 'none'
      return

    @poifsm.currentx = @scale @poi

    @focus
      .select 'line.poi'
      .attr 'display', null
      .attr 'x1', @scale @poi
      .attr 'x2', @scale @poi

    Neighbours = neighbours @filteredData, (d) -> d.time
    poiNeighbours = Neighbours @poi

    d

    if poiNeighbours.length is 1
      d = poiNeighbours[0]
    else if +poiNeighbours[0].time < +@domain[0]
      d = poiNeighbours[1]
    else if +poiNeighbours[1].time > +@domain[1]
      d = poiNeighbours[0]
    else
      d0 = poiNeighbours[0]
      d1 = poiNeighbours[1]
      halfway = d0.time + (d1.time - d0.time)/2
      d = if @poi.isBefore(halfway) then d0 else d1

    @drawArrow d[@options.field], @focus.select '.foc-section'

    if (@canvas.width - @scale @poi) < 27
      xVal = @canvas.width - 27
    else if (@canvas.left + @scale @poi) < 227
      xVal =  27
    else
      xVal = @scale d.time

    @focus
      .select '.arrow-background'
      .attr 'display', null
      .attr 'transform', "translate(#{xVal}, #{@canvas.height/2})"

    @focus
      .select '.foc-section'
      .attr 'display', null
      .attr 'transform', "translate(#{xVal}, #{(@canvas.height/2)- 17})"

  drawArrow: (dir, section) =>
    section
      .selectAll '*'
      .remove()

    arrow = section
      .append 'g'
      .attr 'transform', 'rotate(' + (dir + 180) + ', 0, 10)'

    arrow
      .append 'path'
      .attr 'class', 'arrowhead'
      .attr 'd', d3.svg.symbol().type('triangle-up').size 20

    arrow
      .append 'line'
      .attr 'class', 'arrowline'
      .attr 'x1', 0
      .attr 'x2', 0
      .attr 'y1', 3
      .attr 'y2', 20

    section
      .append 'text'
      .attr 'class', 'label'
      .text "#{dir.toFixed(0)}#{@options.units}"
      .attr 'text-anchor', 'middle'
      .attr 'transform', "translate(0,35)"

  create_directions: =>
    bisector = d3.bisector((d) -> d.time).left
    data = @scale
      .ticks d3.time.hour, 3
      .map (d) =>
        index = bisector @filteredData, d
        @filteredData[index]
      .filter (d) -> d?

    @sections = @svg
      .select '.inner'
      .selectAll '.section'
      .data data

    section = @sections
      .enter()
      .append 'g'
      .attr 'class', (d) =>
        hour = d.time.local().get('hour')
        if hour % 12 is 0
          'section priority1'
        else if hour % 6 is 0
          'section priority2'
        else if hour % 3 is 0
          'section priority3'

    arrow = section
      .append 'g'
      .attr 'transform', (d) => "rotate(#{d[@options.field] + 180}, 0, 9)"
    arrow
      .append 'path'
      .attr 'class', 'arrowhead'
      .attr 'd', d3.svg.symbol().type('triangle-up').size 20

    arrow
      .append 'line'
      .attr 'class', 'arrowline'
      .attr 'x1', 0
      .attr 'x2', 0
      .attr 'y1', 3
      .attr 'y2', 20

    section
      .append 'text'
      .attr 'class', 'label'
      .text (d) => @calculate_direction d[@options.field]
      .attr 'text-anchor', 'middle'
      .attr 'transform', "translate(0,40)"

  resize: (dimensions) =>
    @calculate_layout dimensions

    @svg
      .attr 'width', @dimensions.width
      .attr 'height', @dimensions.height

    @scale.range [0, @canvas.width]

    @sections
      .attr 'transform', (d) => "translate(#{@scale(d.time)}, 10)"

    p1 = @inner.selectAll '.priority1'
    p2 = @inner.selectAll '.priority2'
    p3 = @inner.selectAll '.priority3'

    minLabelWidth = 31
    p1widths = p1[0].length * minLabelWidth
    p2widths = p2[0].length * minLabelWidth
    p3widths = p3[0].length * minLabelWidth

    switch
      when p1widths + p2widths + p3widths <= @canvas.width
        p2.attr 'display', 'inline'
        p3.attr 'display', 'inline'
      when p1widths + p2widths <= @canvas.width
        p2.attr 'display', 'inline'
        p3.attr 'display', 'none'
      when p1widths <= @canvas.width
        p3.attr 'display', 'none'
        p2.attr 'display', 'none'

    @updatepoi()

  calculate_direction: (degree) =>
    direction = Math.floor (degree/22.5) + 0.5
    text = [
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSW',
      'SW',
      'WSW',
      'W',
      'WNW',
      'NW',
      'NNW'
    ]

    textDirection = text[(direction %% 16)]