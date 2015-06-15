###

Plot a frequency histogram with additional buckets for each point.

TODO: Work out how to position these xy visualisations.
TODO: Allow the different categories and values to be specified.

###

d3 = require 'd3'

calculate_layout = (dimensions) ->
  dimensions =
    width: dimensions[0]/1.5
    height: 400

  info =
    top: 0
    right: 0
    bottom: 20
    left: 200

  title =
    top: 0
    right: dimensions.width - info.left
    bottom: 0
    left: 0
    height: dimensions.height
    width: info.left

  canvas =
    top: info.top
    right: info.right
    bottom: info.bottom
    left: info.left
    width: dimensions.width - info.left - info.right
    height: dimensions.height - info.top - info.bottom

  dimensions: dimensions
  info: info
  title: title
  canvas: canvas

module.exports = (spec, components) ->
  svg = null
  data = null
  filteredData = null
  inner = null
  scale = null
  axis = null
  chart = null
  groupedData = null
  colorScale = null
  textcolorScale = null

  getMaxObj = ->
    for d in groupedData
      if d.count == (d3.max groupedData, (d) -> d.count)
        return d

  result =
    render: (dom, state, params) ->
      layout = calculate_layout params.dimensions

      svg = d3.select dom
        .append 'svg'
        .attr 'class', 'item histogram'

      data = state.data.map (d) ->
        time: d.time
        wsp: +d.wsp
        wd: +d.wd

      data = data.filter (d) -> return d if d.wd? and d.wsp?

      filteredData = data
      svg
        .append 'g'
        .attr 'class', 'title'
        .attr 'transform', "translate(#{layout.title.left},#{layout.title.top})"
        .append 'text'
        .attr 'class', 'infotext'
        .text "#{spec.text}"
        .attr 'dy', 20
        .attr 'dx', 5

      inner = svg
        .append 'g'
        .attr 'class', 'inner'
        .attr 'transform', "translate(#{layout.canvas.left},#{layout.canvas.top})"

      inner
        .append 'line'
        .attr 'class', 'divider'
        .attr 'x1', 0
        .attr 'x2', 0
        .attr 'y1', 0
        .attr 'y2', layout.dimensions.height

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

      chart
        .append 'defs'
        .append 'rect'
        .attr 'x', '0'
        .attr 'y', '0'
        .attr 'width', layout.canvas.width
        .attr 'height', layout.canvas.height

      frequency =
        N: []
        NNE: []
        NE: []
        ENE: []
        E: []
        ESE: []
        SE: []
        SSE: []
        S: []
        SSW: []
        SW: []
        WSW: []
        W: []
        WNW: []
        NW: []
        NNW: []

      colorScale = d3.scale.quantize()
        .range ['#E4EAF1', '#D1D8E3', '#BEC7D5', '#ABB6C7', '#98A5B9', '#8594AB', '#73829E', '#607190', '#4D6082', '#3A4E74', '#273D66', '#142C58', '#122851', '#102448']
        .domain [0, 13]

      textcolorScale = d3.scale.quantize()
        .range ['#000000', '#000000', '#ffffff', '#ffffff']
        .domain [0, 13]

      calculate_direction = (degree) ->
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

      for d in filteredData
        dir = calculate_direction d.wd
        frequency[dir].push d

      _speedArray =
          '0-4': []
          '5-9': []
          '10-14': []
          '15-19': []
          '20-24': []
          '25-29': []
          '30-34': []
          '35-39': []
          '40-44': []
          '45-49': []
          '50-54': []
          '55-59': []
          '60-64': []
          '65+': []

      calculate_speed_category = (speed) ->
        cat = switch
          when speed < 5 then '0-4'
          when speed < 10 then '5-9'
          when speed < 15 then '10-14'
          when speed < 20 then '15-19'
          when speed < 25 then '20-24'
          when speed < 30 then '25-29'
          when speed < 35 then '30-34'
          when speed < 45 then '35-39'
          when speed < 50 then '40-44'
          when speed < 55 then '45-49'
          when speed < 60 then '50-54'
          when speed < 65 then '55-59'
          when speed < 70 then '60-64'
          else '65+'

      getSpeeds = (dir, items) ->
        speedArray = {}
        for cat, _ of _speedArray
          speedArray[cat] = []

        for i in items
          cat = calculate_speed_category i.wsp
          speedArray[cat].push i

        start = 0
        count = 0
        for cat, bits of speedArray
          res =
            index: count
            start: start
            end: start + bits.length
            value: bits.length
          start = res.end
          count++
          res

      groupedData = []
      angle = 0

      for dir, items of frequency
        groupedData.push
          key: angle
          value: dir
          count: items.length
          speeds: getSpeeds dir, items
        angle += 22.5

      for i, cat of Object.keys _speedArray
        max = null
        maxItem = null
        for dir in groupedData
          item = dir.speeds[i]
          if item.value isnt 0
            if maxItem is null or item.value > max
              max = item.value
              maxItem = item
        maxItem.legend = cat if maxItem?


      scale =
        x: d3.scale.ordinal().domain(groupedData.map (d) -> d.value)
        y: d3.scale.linear().domain([0, 1.1 * d3.max groupedData, (d) -> d.count])

      axis =
        x : d3.svg.axis().scale(scale.x).orient 'bottom'
        y : d3.svg.axis().scale(scale.y).orient 'left'

      chart
        .append 'text'
        .attr 'class', 'legend'
        .attr 'text-anchor', 'end'

      result.resize params.dimensions

    resize: (dimensions) ->
      layout = calculate_layout dimensions

      svg
        .attr 'width', layout.dimensions.width
        .attr 'height', layout.dimensions.height

      scale.x.rangeRoundBands([0, layout.canvas.width], 0.05)
      scale.y.range [layout.canvas.height, 0]

      bars = chart
        .selectAll '.bar'
        .data groupedData
        .enter()
        .append 'g'
        .attr 'class', 'bar'
        .attr 'transform', (d) -> "translate(#{scale.x d.value}, 0)"

      bars
        .selectAll 'rect'
        .data (d)-> d.speeds
        .enter()
        .append 'rect'
        .attr 'x', 0
        .attr 'y', (d) -> scale.y d.end
        .attr "width", scale.x.rangeBand()
        .attr 'height', (d) -> scale.y(d.start) - scale.y(d.end)
        .style 'fill', (d) -> colorScale d.index

      bars
        .selectAll 'text'
        .data (d) -> d.speeds.filter (s) -> s.legend
        .enter()
        .append 'text'
        .attr 'x', scale.x.rangeBand()/2
        .attr 'y', (d) -> scale.y d.end
        .attr 'dy', '1.1em'
        .style 'text-anchor', 'middle'
        .style 'fill', (d) -> textcolorScale d.index
        .text (d) -> d.legend

      inner
        .select '.x.axis'
        .call axis.x

      inner
        .select '.y.axis'
        .call axis.y.tickSize -layout.canvas.width, 0, 0

      inner
        .selectAll '.y.axis .tick line'
        .data scale.y.ticks axis.y.ticks()[0]
        .attr 'class', (d) ->
          if d is 0 then 'zero' else null

      inner
        .select '.y.axis .domain'
        .remove()

      max = getMaxObj()

      chart
        .select '.legend'
        .attr 'x', scale.x max.value
        .attr 'y', scale.y max.count
        .text "#{max.count}"