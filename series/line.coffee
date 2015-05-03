class SRline
  constructor: (options, params) ->
    @options = options
    { @svg, @data, @scale, @axis, @dimensions, @hub, @domain } = params

    @data = @data.map (d) ->
      result = time: d.time
      result[options.field] = +d[options.field]
      result[options.field] = null if result[options.field] is 0
      result

    @line = @svg
      .append 'path'
      .attr 'class', "#{@options.style} #{@options.type}"
      .attr 'd', ''

    @labelShad = @svg
      .append 'text'
      .attr 'class', 'label-shad'
      .attr 'text-anchor', 'start'
      .attr 'dy', 12
      .text "#{@options.text} (#{@options.units})"

    @label = @svg
      .append 'text'
      .attr 'class', 'label'
      .attr 'text-anchor', 'start'
      .attr 'dy', 12
      .text "#{@options.text} (#{@options.units})"

    #---creation: createpoi----#
    @focus = @svg
      .append 'g'
      .attr 'class', 'focus'

    @focus
      .append 'circle'
      .attr 'class', 'poi-circle'
      .attr 'display', 'none'
      .attr 'r', 4

    @focus
      .append 'text'
      .attr 'class', 'poi-y-val-shad'
      .attr 'display', 'none'
      .attr 'dy', '-0.3em'

    @focus
      .append 'text'
      .attr 'class', 'poi-y-val'
      .attr 'display', 'none'
      .attr 'dy', '-0.3em'

    @data = @data.filter (d) => d[@options.field]?

    getNeighbours = neighbours @data, (d) -> d.time

    start = getNeighbours(@domain[0])[0]
    end = getNeighbours(@domain[1])
    end = end[end.length-1]

    @filteredData = @data.filter (d) =>
      +d.time >= +start.time and +d.time <= +end.time

    @hub.on 'poi', @setpoi
    @hub.on 'window dimensions changed', @resize

  provideMax: =>
    d3.max @filteredData, (d) => d[@options.field]

  setpoi: (poi) =>
    @poi = poi
    @updatepoi()

  updatepoi: =>
    if !@poi?
      @focus
        .select '.poi-circle'
        .attr 'display', 'none'
      @focus
        .select '.poi-y-val-shad'
        .attr 'display', 'none'
      @focus
        .select '.poi-y-val'
        .attr 'display', 'none'
      return

    yValWidth = +@focus.select('.poi-y-val').node().getComputedTextLength()

    if (@dimensions[0] - (@scale.x @poi)-yValWidth) < yValWidth
      dxAttr = - yValWidth - 8
    else
      dxAttr = 8

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

    @focus
      .select '.poi-circle'
      .attr 'display', null
      .attr 'transform', "translate(#{@scale.x(d.time)}, #{@scale.y(d[@options.field])})"

    @focus
      .select '.poi-y-val-shad'
      .attr 'display', null
      .attr 'transform', "translate(#{@scale.x(d.time)}, #{@scale.y(d[@options.field])})"
      .attr 'dx', dxAttr
      .text "#{d[@options.field].toPrecision(3)} (#{@options.units})"

    @focus
      .select '.poi-y-val'
      .attr 'display', null
      .attr 'transform', "translate(#{@scale.x(d.time)}, #{@scale.y(d[@options.field])})"
      .attr 'dx', dxAttr
      .text "#{d[@options.field].toPrecision(3)} (#{@options.units})"

  resize: (dimensions) =>
    @dimensions = dimensions

    path =  d3.svg.line()
      .x (d) => @scale.x d.time
      .y (d) => @scale.y d[@options.field]

    @line
      .attr 'd', path @filteredData

    labelWidth = +@label.node().getComputedTextLength()

    @labelShad
      .attr 'transform', "translate(#{@dimensions[0] - labelWidth}, #{@scale.y(@filteredData[@filteredData.length-2][@options.field])})"

    @label
      .attr 'transform', "translate(#{@dimensions[0] - labelWidth}, #{@scale.y(@filteredData[@filteredData.length-2][@options.field])})"

    @updatepoi()
