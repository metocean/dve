class SRscatter
  constructor: (options, params) ->
    @options = options
    { @svg, @data, @scale, @axis, @dimensions, @hub, @domain } = params

    @data = @data.map (d) ->
      result = time: d.time
      result[options.field] = +d[options.field]
      result

    @data = @data.filter (d) => d[@options.field]?

    getNeighbours = neighbours @data, (d) -> d.time

    start = getNeighbours(@domain[0])[0]
    end = getNeighbours(@domain[1])
    end = end[end.length-1]

    @filteredData = @data.filter (d) =>
      +d.time >= +start.time and +d.time <= +end.time

    @value = {
      x : (d)=> d.time
      y : (d)=> d[options.field]
    }

    @dotContainer = @svg
      .append 'g'

    @dotContainer
      .selectAll ".dot"
      .data @filteredData
      .enter()
      .append "circle"
      .attr "class", "dot"
      .attr "r", 3.5

    @focus = @svg
      .append 'g'
      .attr 'class', 'focus'

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

    @hub.on 'poi', @setpoi

  provideMax: =>
    d3.max @filteredData, (d) => d[@options.field]

  drawDots : (svg, data) =>
    svg.selectAll ".dot"
      .data data
      .attr "cx", (d) => @scale.x @value.x d
      .attr "cy", (d) => @scale.y @value.y d

  setpoi: (poi) =>
    @poi = poi
    @updatepoi()

  updatepoi: =>
    if !@poi?
      @focus
        .select '.poi-y-val-shad'
        .attr 'display', 'none'
      @focus
        .select '.poi-y-val'
        .attr 'display', 'none'
      @svg
        .selectAll '.dot'
        .data @filteredData
        .style 'fill', 'rgb(20, 44, 88)'
      return

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

    @svg
      .selectAll '.dot'
      .data @filteredData
      .style 'fill', (f) =>
        return 'rgb(216, 34, 42)' if f.time == d.time

    yValWidth = +@focus.select('.poi-y-val').node().getComputedTextLength()

    if (@dimensions[0] - (@scale.x @poi)-yValWidth) < yValWidth
      dxAttr = - yValWidth - 8
    else
      dxAttr = 8

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

    @drawDots @dotContainer, @filteredData

    @updatepoi()
