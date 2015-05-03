class ERcontinuous
  constructor: (svg, data, dimensions, options, domain) ->
    @svg = svg
    @data = data
    @calculate_layout dimensions
    @options = options
    @domain = domain

    #---creation: createlayout----#

    @svg
      .append 'g'
      .attr 'class', 'title'
      .attr 'transform', "translate(#{@title.left},#{@title.top})"
      .append 'text'
      .attr 'class', 'infotext'
      .text @options.name
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

    #---creation: createaxies----#

    @inner
      .append 'g'
      .attr 'class', 'x axis'
      .attr 'transform', "translate(0,#{@canvas.height})"

    @inner
      .append 'g'
      .attr 'class', 'y axis'

    #---creation: createdata----#

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
      .attr 'width', @canvas.width
      .attr 'height', @canvas.height

    @windLine = @chart
      .append 'path'
      .attr 'class', 'line'
      .attr 'class', 'wind'
      .attr 'd', ''

    @gustLine = @chart
      .append 'path'
      .attr 'class', 'line'
      .attr 'class', 'gust'
      .attr 'd', ''

    @chart
      .append 'text'
      .attr 'class', 'wind-label-shad'
      .attr 'dy', '10'
      .attr 'text-anchor', 'end'
      .text 'WSpd 10m (' + @options.units + ')'

    @chart
      .append 'text'
      .attr 'class', 'wind-label'
      .attr 'dy', '10'
      .attr 'text-anchor', 'end'
      .text 'WSpd 10m (' + @options.units + ')'
    @chart
      .append 'text'
      .attr 'class', 'gust-label-shad'
      .attr 'dy', '10'
      .attr 'text-anchor', 'end'
      .text 'Gust 10m (' + @options.units + ')'

    @chart
      .append 'text'
      .attr 'class', 'gust-label'
      .attr 'dy', '10'
      .attr 'text-anchor', 'end'
      .text 'Gust 10m (' + @options.units + ')'
    @focus = @inner
      .append 'g'
      .attr 'class', 'focus'


    #---creation: createpoi----#

    @focus
      .append 'line'
      .attr 'class', 'poi'
      .attr 'display', 'none'
      .attr 'y1', 0
      .attr 'y2', @dimensions.height

    @focus
      .append 'circle'
      .attr 'class', 'wind poi-circle'
      .attr 'display', 'none'
      .attr 'r', 4

    @focus
      .append 'text'
      .attr 'class', 'wind poi-y-val-shad'
      .attr 'display', 'none'
      .attr 'dy', '-0.3em'

    @focus
      .append 'text'
      .attr 'class', 'wind poi-y-val'
      .attr 'display', 'none'
      .attr 'dy', '-0.3em'

    @focus
      .append 'circle'
      .attr 'class', 'gust poi-circle'
      .attr 'display', 'none'
      .attr 'r', 4

    @focus
      .append 'text'
      .attr 'class', 'gust poi-y-val-shad'
      .attr 'display', 'none'
      .attr 'dy', '-0.3em'

    @focus
      .append 'text'
      .attr 'class', 'gust poi-y-val'
      .attr 'display', 'none'
      .attr 'dy', '-0.3em'


    #---creation: createdata----#

    @options.data = data.values.filter (d) =>
      +d.time >= +@domain[0] and +d.time <= +@domain[1]

    @gust = data.values.filter (d) => d.Gust10m?

    gustNeighbours = neighbours @gust, (d) -> d.time

    start = gustNeighbours(@domain[0])[0]
    end = gustNeighbours(@domain[1])
    end = end[end.length-1]

    @filteredGust = @gust.filter (d) =>
      +d.time >= +start.time and +d.time <= +end.time

    @maxWind = d3.max @options.data, (d) -> d.WSpd10m
    @maxGust = d3.max @filteredGust, (d) -> d.Gust10m

    @scale = {}
    @scale.x = d3
      .time
      .scale()
      .domain @domain
    @scale.y = d3
      .scale
      .linear()
      .domain [0, 1.1 * d3.max [@maxGust, @maxWind]]

    #---creation: createaxies----#

    @axis = {}
    @axis.x = d3
      .svg
      .axis()
      .scale @scale.x
      .orient "bottom"
      .ticks d3.time.hour

    @axis.y = d3
      .svg
      .axis()
      .scale @scale.y
      .orient "left"
      .ticks 6

    #---creation/setpositions??: dynamicstuffs---#
    @options.hub.on 'poi', @setpoi
    @options.hub.on 'window dimensions changed', @resize

    #---creation: createpoibehaviour----#
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

    #---creation: createpoibehaviour----#
    drag = d3.behavior.drag()
      .on 'drag', @poifsm.update

    #---creation: createpoi----#
    @focus
      .append 'rect'
      .attr 'class', 'foreground'
      .style 'fill', 'none'
      .on 'mousedown', @poifsm.mousedown
      .on 'mouseup', @poifsm.mouseup
      .call drag

    @resize dimensions #updatewidth

#---buildlayout---#
  calculate_layout: (dimensions) =>
    @dimensions =
      width: dimensions[0]
      height: 250

    @info =
      top: 0
      right: 0
      bottom: 1
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

#---creation: createpoi----#
  setpoi: (poi) =>
    @poi = poi
    @updatepoi()

#---updatepoi---#
  updatepoi: =>
    #---updatepoi: change poi data---#
    if !@poi?
      @poifsm.currentx = @scale.x @poi
      @focus
        .select 'line.poi'
        .attr 'display', 'none'
      @focus
        .select '.wind.poi-circle'
        .attr 'display', 'none'
      @focus
        .select '.gust.poi-circle'
        .attr 'display', 'none'
      @focus
        .select '.wind.poi-y-val-shad'
        .attr 'display', 'none'
      @focus
        .select '.wind.poi-y-val'
        .attr 'display', 'none'
      @focus
        .select '.gust.poi-y-val-shad'
        .attr 'display', 'none'
      @focus
        .select '.gust.poi-y-val'
        .attr 'display', 'none'
      return

    @poifsm.currentx = @scale.x @poi
    @focus
      .select 'line.poi'
      .attr 'display', null
      .attr 'x1', @scale.x @poi
      .attr 'x2', @scale.x @poi

    #---updatepoi: find data points----#

    if (@canvas.width - @scale.x @poi) < 70
      dxAttr = - 70
    else
      dxAttr = 8

    bisectDate = d3.bisector((d)-> d.time).left
    windDomain = d3.extent @options.data, (d) -> d.time

    windNeighbours = neighbours @options.data, (d) -> d.time
    poiWindNeighbours = windNeighbours @poi

    d

    if poiWindNeighbours.length is 1
      d = poiWindNeighbours[0]
    else if +poiWindNeighbours[0].time < +@domain[0]
      d = poiWindNeighbours[1]
    else if +poiWindNeighbours[1].time > +@domain[1]
      d = poiWindNeighbours[0]
    else
      d0 = poiWindNeighbours[0]
      d1 = poiWindNeighbours[1]
      halfway = d0.time + (d1.time - d0.time)/2
      d = if @poi.isBefore(halfway) then d0 else d1


    # if @poi.isSame(@domain[0], 'hour') or @poi.isBefore(@options.data[0].time)
    #   i = bisectDate @options.data, @domain[0]
    #   d = @options.data[0]
    # else if @poi.isSame(@domain[1], 'hour') or @poi.isAfter(@options.data[@options.data.length-1].time)
    #   i = bisectDate @options.data, @domain[1]
    #   d = @options.data[i]
    # else
    #   i = bisectDate @options.data, @poi
    #   d0 = @options.data[i-1]
    #   d1 = @options.data[i]
    #   halfway = d0.time + (d1.time - d0.time)/2
    #   d = if @poi.isBefore(halfway) then d0 else d1

    #---updatepoi: change poi data---#

    @focus
      .select '.wind.poi-circle'
      .attr 'display', null
      .attr 'transform', 'translate(' + @scale.x(d.time) + ',' + @scale.y(d.WSpd10m) + ')'

    @focus
      .select '.wind.poi-y-val-shad'
      .attr 'display', null
      .attr 'transform', 'translate(' + @scale.x(d.time) + ',' + @scale.y(d.WSpd10m) + ')'
      .attr 'dx', dxAttr
      .text d.WSpd10m + ' (' + @options.units + ')'

    @focus
      .select '.wind.poi-y-val'
      .attr 'display', null
      .attr 'transform', 'translate(' + @scale.x(d.time) + ',' + @scale.y(d.WSpd10m) + ')'
      .attr 'dx', dxAttr
      .text d.WSpd10m + ' (' + @options.units + ')'

    gustDomain = d3.extent @filteredGust, (d) -> d.time

    #---updatepoi: find data points----#

    gustNeighbours = neighbours @filteredGust, (d) -> d.time
    poiGustNeighbours = gustNeighbours @poi

    d

    if poiGustNeighbours.length is 1
      d = poiGustNeighbours[0]
    else if +poiGustNeighbours[0].time < +@domain[0]
      d = poiGustNeighbours[1]
    else if +poiGustNeighbours[1].time > +@domain[1]
      d = poiGustNeighbours[0]
    else
      d0 = poiGustNeighbours[0]
      d1 = poiGustNeighbours[1]
      halfway = d0.time + (d1.time - d0.time)/2
      d = if @poi.isBefore(halfway) then d0 else d1

    #---updatepoi: change poi data---#

    @focus
      .select '.gust.poi-circle'
      .attr 'display', null
      .attr 'transform', 'translate(' + @scale.x(d.time) + ',' + @scale.y(d.Gust10m) + ')'

    @focus
      .select '.gust.poi-y-val-shad'
      .attr 'display', null
      .attr 'transform', 'translate(' + @scale.x(d.time) + ',' + @scale.y(d.Gust10m) + ')'
      .attr 'dx', dxAttr
      .text d.Gust10m + ' (' + @options.units + ')'

    @focus
      .select '.gust.poi-y-val'
      .attr 'display', null
      .attr 'transform', 'translate(' + @scale.x(d.time) + ',' + @scale.y(d.Gust10m) + ')'
      .attr 'dx', dxAttr
      .text d.Gust10m + ' (' + @options.units + ')'

#---updatewidth---#
  resize: (dimensions) =>
  #---updatewidth: buildlayout---#
    @calculate_layout dimensions

  #---updatewidth: setpositions---#
    @svg
      .attr 'width', @dimensions.width
      .attr 'height', @dimensions.height

    @scale.x.range [0, @canvas.width]
    @scale.y.range [@canvas.height, 0]

    @focus
      .select '.foreground'
      .attr 'height', @canvas.height
      .attr 'width', @canvas.width

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

    (@inner.select '.y.axis .tick text').text ' '

    @inner
      .selectAll '.y.axis .tick line'
      .data @scale.y.ticks @axis.y.ticks()[0]
      .attr 'class', (d) ->
        if d is 0 then 'zero' else null

    wSpdline =  d3.svg.line()
      .x (d) => @scale.x d.time
      .y (d) => @scale.y d.WSpd10m

    @windLine
      .attr 'd', wSpdline @options.data

    gustline =  d3.svg.line()
      .x (d) => @scale.x d.time
      .y (d) => @scale.y d.Gust10m

    @gustLine
      .attr 'd', gustline @filteredGust

    @inner
      .select '.y.axis .domain'
      .remove()

    @inner
      .select '.wind-label-shad'
      .attr 'transform', 'translate(' + @canvas.width + ', '+ @scale.y(@options.data[@options.data.length-1].WSpd10m) + ')'

    @inner
      .select '.wind-label'
      .attr 'transform', 'translate(' + @canvas.width + ', '+ @scale.y(@options.data[@options.data.length-1].WSpd10m) + ')'

    @inner
      .select '.gust-label-shad'
      .attr 'transform', 'translate(' + @canvas.width + ',' + @scale.y(@filteredGust[@filteredGust.length-1].Gust10m) + ')'

    @inner
      .select '.gust-label'
      .attr 'transform', 'translate(' + @canvas.width + ',' + @scale.y(@filteredGust[@filteredGust.length-1].Gust10m) + ')'

    @updatepoi()
