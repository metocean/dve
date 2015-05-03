class ERsegments
  constructor: (svg, dimensions, options, domain) ->
    @svg = svg
    @options = options
    @domain = domain

    duration = @options.mean + @options.max
    duration /= 2
    duration = Math.max 10, duration

    @cycle =
      every: moment.duration @options.every
      offset: moment.duration @options.offset
      duration: moment.duration "#{duration}m"
    @segments = moment
      .cycle @cycle
      .expand [
        @domain[0].clone().subtract 12, 'h'
        @domain[1]
      ]

    @segments = @segments.filter (s) =>
      return no if s.end.isBefore @domain[0]
      return no if s.start.isAfter @domain[1]
      yes

    for s in @segments
      if s.start.isBefore @domain[0]
        s.start = @domain[0].clone()
      if s.end.isAfter @domain[1]
        s.end = @domain[1].clone()

    @calculate_layout dimensions
    @svg
      .append 'g'
      .attr 'class', "canvas #{@options.style}"
      .attr 'transform', "translate(#{@canvas.left},#{@canvas.top})"
      .append 'line'
      .attr 'x1', 0
      .attr 'x2', @canvas.width
      .attr 'y1', 4
      .attr 'y2', 4

    @svg
      .append 'line'
      .attr 'class', 'poi'
      .attr 'display', 'none'
      .attr 'x1', 0
      .attr 'x2', 0
      .attr 'y1', 0
      .attr 'y2', @dimensions.height

    hub.on 'poi', @setpoi
    hub.on 'window dimensions changed', @resize

    @resize dimensions

  calculate_layout: (dimensions) =>
    @margin =
      top: 1
      right: 20
      bottom: 1
      left: 20

    @dimensions =
      width: dimensions[0]
      height: 10

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
    inner = @svg.select '.canvas'

    inner
      .selectAll '.segment'
      .data @segments
      .attr 'class', (d) =>
        if d.start <= @poi < d.end
          return "segment selected"
        'segment'

    inner
      .selectAll '.label'
      .data @segments
      .attr 'x', (d) =>
        return @scale @poi if @poi?
        0
      .style 'display', (d) =>
        return null if d.start <= @poi < d.end
        'none'

    inner
      .select 'line'
      .attr 'class', =>
        return null if !@poi?
        for d in @segments
          return 'selected' if d.start <= @poi < d.end
        null

    @svg
      .select 'line.poi'
      .attr 'display', =>
        return 'none' if !@poi?
        null
      .attr 'x1', =>
        return 0 if !@poi?
        @canvas.left + @scale @poi
      .attr 'x2', =>
        return 0 if !@poi?
        @canvas.left + @scale @poi

  resize: (dimensions) =>
    @calculate_layout dimensions
    @scale = d3.time.scale()
      .range [0, @canvas.width]
      .domain @domain

    @svg
      .attr 'width', @dimensions.width
      .attr 'height', @dimensions.height

    inner = @svg.select 'g.canvas'

    inner
      .select 'line'
      .attr 'x2', @canvas.width

    segment = inner
      .selectAll '.segment'
      .data @segments

    segment.enter()
      .append 'rect'
      .attr 'class', 'segment'
      .attr 'y', 0
      .attr 'rx', 2
      .attr 'ry', 2
      .attr 'height', 7

    segment
      .attr 'class', 'segment'
      .attr 'x', (d) => @scale d.start
      .attr 'width', (d) => @scale(d.end) - @scale(d.start) - 1

    label = inner
      .selectAll '.label'
      .data @segments

    label.enter()
      .append 'text'
      .attr 'class', 'label'
      .attr 'y', 7
      .attr 'dx', 3
      .text @options.name

    @updatepoi()
