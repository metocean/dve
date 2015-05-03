class ERtime
  constructor: (svg, dimensions, options, domain) ->
    @svg = svg
    @options = options
    @domain = domain

    @cycle =
      every: moment.duration @options.every
      offset: moment.duration @options.offset
      duration: moment.duration @options.every

    accessors =
      utc: (d) -> d.utc()
      local: (d) -> d.local()
      offset: (d) -> d.zone - @options.utcoffset

    @accessor = accessors[@options.format]

    @data = @build_date @accessor

    @calculate_layout dimensions

    @svg
      .append 'rect'
      .attr 'class', 'background'
      .attr 'x', @canvas.left
      .attr 'y', @canvas.top
      .attr 'height', @canvas.height

    @svg
      .append 'g'
      .attr 'class', "canvas #{@options.format}"
      .attr 'transform', "translate(#{@canvas.left},#{@canvas.top})"

    @svg
      .append 'line'
      .attr 'class', 'poi'
      .attr 'display', 'none'
      .attr 'x1', 0
      .attr 'x2', 0
      .attr 'y1', 0
      .attr 'y2', @dimensions.height

    @svg
      .append 'text'
      .attr 'class', 'poi'
      .attr 'display', 'none'
      .attr 'x', 0
      .attr 'y', @canvas.top + @canvas.height / 2.8
      .text 'AWESOME'

    hub.on 'poi', @setpoi
    hub.on 'window dimensions changed', @resize

    @poifsm =
      hide: =>
        return if @poi is null
        hub.emit 'poi', null

      show: (x) =>
        range = @scale.range()
        return @poifsm.hide() if range[0] > x or range[1] < x
        d = @scale.invert x

        return if @poi is d
        hub.emit 'poi', moment d

      update: =>
        x = d3.mouse(@svg.node())[0] - @canvas.left
        # Only update if enough drag
        if @poifsm.startx?
          dist = Math.abs @poifsm.startx - x
          return if dist < 10
        @poifsm.startx = null
        @poifsm.show x
      mousedown: =>
        x = d3.mouse(@svg.node())[0] - @canvas.left
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
        x = d3.mouse(@svg.node())[0] - @canvas.left
        @poifsm.show x

    drag = d3.behavior.drag()
      .on 'drag', @poifsm.update
    @svg
      .append 'rect'
      .attr 'class', 'foreground'
      .attr 'x', @canvas.left
      .attr 'y', @canvas.top
      .attr 'height', @canvas.height
      .on 'mousedown', @poifsm.mousedown
      .on 'mouseup', @poifsm.mouseup
      .on 'click', @poifsm.click
      .call drag

    @resize dimensions

  build_date: (accessor) =>
    startoflocalday = accessor(@domain[0].clone().subtract(1, 'days')).startOf('day')
    offset = moment.duration startoflocalday.diff @domain[0]
    daycycle =
      offset: offset
      every: moment.duration '24h'
      duration: moment.duration '24h'
    timecycle =
      every: @cycle.every
      offset: @cycle.offset
      duration: @cycle.duration
    localdomain = [
      accessor @domain[0].clone()
      accessor @domain[1].clone()
    ]
    days: moment.cycle(daycycle).expand localdomain
    times: moment.cycle(timecycle).expand localdomain

  calculate_layout: (dimensions) =>
    @margin =
      top: 2
      right: 20
      bottom: 2
      left: 20

    @dimensions =
      width: dimensions[0]
      height: 52

    @canvas =
      top: @margin.top
      right: @margin.right
      bottom: @margin.bottom
      left: @margin.left
      width: @dimensions.width - @margin.left - @margin.right
      height: @dimensions.height - @margin.top - @margin.bottom

  setpoi: (poi) =>
    @poi = poi
    @updatepoi()

  updatepoi: =>
    if !@poi?
      @poifsm.currentx = @scale @poi
      @svg
        .select 'line.poi'
        .attr 'display', 'none'
      @svg
        .select 'text.poi'
        .attr 'display', 'none'
        .text ''
      @svg
        .select '.canvas'
        .selectAll 'text.date'
        .style 'display', null
      return

    @poifsm.currentx = @scale @poi
    @svg
      .select 'line.poi'
      .attr 'display', null
      .attr 'x1', @canvas.left + @scale @poi
      .attr 'x2', @canvas.left + @scale @poi

    @svg
      .select 'text.poi'
      .attr 'display', null
      .attr 'x', 3 + @canvas.left + @scale @poi
      .text @accessor(@poi.clone()).format 'HH:mm ddd DD MMM ZZ'

    @svg
      .select '.canvas'
      .selectAll 'text.date'
      .style 'display', 'none'

  resize: (dimensions) =>
    @calculate_layout dimensions
    @scale = d3.time.scale()
      .range [0, @canvas.width]
      .domain @domain

    @svg
      .attr 'width', @dimensions.width
      .attr 'height', @dimensions.height

    @svg
      .select '.background'
      .attr 'width', @canvas.width

    @svg
      .select '.foreground'
      .attr 'width', @canvas.width

    inner = @svg.select 'g.canvas'

    sep = inner.selectAll '.sep'
      .data @data.days

    sep.enter()
      .append 'line'
      .attr 'class', 'sep'

    sep
      .attr 'x1', (d) => @scale d.start
      .attr 'x2', (d) => @scale d.start
      .attr 'y1', 0
      .attr 'y2', @canvas.height

    date = inner.selectAll 'text.date'
      .data @data.days

    date.enter()
      .append 'text'
      .attr 'class', 'date'

    date
      .attr 'x', (d) => @scale d.start
      .attr 'dx', 6
      .attr 'y', @canvas.height / 2.8
      .text (d) -> d.start.format 'ddd DD MMM ZZ'

    line = inner.selectAll '.line'
      .data @data.times

    line.enter()
      .append 'line'
      .attr 'class', 'line'

    line
      .attr 'x1', (d) => -1 + @scale d.start
      .attr 'x2', (d) => -1 + @scale d.start
      .attr 'y1', (d) =>
        if d.index % 6 is 0
          @canvas.height / 1.85
        else
          @canvas.height / 1.15
      .attr 'y2', @canvas.height

    time = inner.selectAll 'text.time'
      .data @data.times

    time.enter()
      .append 'text'
      .attr 'class', 'time'

    time
      .attr 'x', (d) => @scale d.start
      .attr 'y', @canvas.height / 1.4
      .attr 'dx', 3
      .text (d) ->
        if d.index % 6 is 0
          d.start.format 'HH'
        else
          ''

    @updatepoi()
