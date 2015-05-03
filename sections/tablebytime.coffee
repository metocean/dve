class ERtablebytime
  constructor: (svg, data, dimensions, options, domain) ->
    @svg = svg
    @calculate_layout dimensions
    @options = options
    @domain = domain

    @data = data.map (d) ->
      result = time: d.time
      result[options.field] = +d[options.field]
      result

    @filteredData = @data.filter (d) =>
      +d.time >= +@domain[0] and +d.time <= +@domain[1]

    @scale = d3.time.scale().domain @domain
      .range [0, @canvas.width]

    # need to make these equal to the longest string in the data set
    @field = {
      height: 30
      width: 0
    }

    dataDom = [(d3.min @filteredData, (d)=> d[@options.field]), (d3.max @filteredData, (d) => d[@options.field])]

    @colorScale = d3.scale.quantize()
      .range(colorbrewer.Blues[9])
      .domain dataDom   #scale decided by value extremes, maybe should be set values for different data types?

    @textcolorScale = d3.scale.quantize()
      .range(["#000000", "#000000", "#ffffff", "#ffffff"])
      .domain dataDom

    # @colorScale = d3.scale.quantize()
    #   .range(colorbrewer.Blues[9])
    #   .domain [0, 360]

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

    @container =  @inner
      .append 'g'
      .attr 'class', 'container'

    @create_cells()

    @options.hub.on 'window dimensions changed', @resize

    @resize dimensions

  calculate_layout: (dimensions) =>
    @dimensions =
      width: dimensions[0]
      height: 30

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

  create_cells: =>
    bisector = d3.bisector((d) -> d.time).left
    data = @scale
      .ticks d3.time.hour, 3
      .map (d) =>
        index = bisector @filteredData, d
        @filteredData[index]
      .filter (d) -> d?

    @cells = @container
      .selectAll 'g.cell'
      .data data

    cellsEnter = @cells
      .enter()
      .append 'g'
      .attr 'class', 'cell'
      .attr 'class', (d) =>
        hour = d.time.local().get('hour')
        if hour % 12 is 0
          'cell priority1'
        else if hour % 6 is 0
          'cell priority2'
        else if hour % 3 is 0
          'cell priority3'

    cellsEnter
      .append 'rect'
      .attr 'height', @field.height - 1
      .style 'fill', (d) =>  @colorScale d[@options.field]

    cellsEnter
      .append 'text'
      .attr 'y', @field.height/2
      .attr 'dy', '0.35em'
      .text (d) => d[@options.field]
      .style 'fill', (d) => @textcolorScale d[@options.field]

  resize: (dimensions) =>
    @calculate_layout dimensions

    @svg
      .attr 'width', @dimensions.width
      .attr 'height', @dimensions.height

    @scale.range [0, @canvas.width]

    bisector = d3.bisector((d) -> d.time).left

    data = @scale
      .ticks d3.time.hour, 3
      .map (d) =>
        index = bisector @filteredData, d
        @filteredData[index]
      .filter (d) -> d?

    p1 = @container.selectAll '.priority1'
    p2 = @container.selectAll '.priority2'
    p3 = @container.selectAll '.priority3'

    minLabelWidth = 31
    p1widths = p1[0].length * minLabelWidth
    p2widths = p2[0].length * minLabelWidth
    p3widths = p3[0].length * minLabelWidth
    switch
      when p1widths + p2widths + p3widths <= @canvas.width
        p2.attr 'display', 'inline'
        p3.attr 'display', 'inline'
        @field.width = @canvas.width / (p1[0].length + p2[0].length + p3[0].length)
      when p1widths + p2widths <= @canvas.width
        p2.attr 'display', 'inline'
        p3.attr 'display', 'none'
        @field.width = @canvas.width / (p1[0].length + p2[0].length)
      when p1widths <= @canvas.width
        p3.attr 'display', 'none'
        p2.attr 'display', 'none'
        @field.width = @canvas.width / p1[0].length

    @cells = @container
      .selectAll 'g.cell'
      .data data

    @cells
      .attr 'transform', (d) => "translate(#{@scale(d.time) - @field.width/2}, 0)"

    @container.selectAll '.cell rect'
      .attr 'width', @field.width - 1

    @container.selectAll '.cell text'
      .attr 'x', @field.width/2
