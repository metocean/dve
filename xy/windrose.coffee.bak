###

Plot a windrose with additional categories for each direction.

TODO: Work out how to position these xy visualisations.
TODO: Allow the different categories and values to be specified.

###


d3 = require 'd3'

calculate_layout = (dimensions) ->
  dimensions =
    width: 600
    height: 400

  info =
    top: 0
    right: 0
    bottom: 0
    left: 200

  title =
    top: 0
    right: dimensions.width - info.left
    bottom: 0
    left: 0
    height: dimensions.height
    width: info.left

  canvas =
    top: info.top + 25
    right: info.right - 50
    bottom: info.bottom - 50
    left: info.left + 25
    width: dimensions.width - info.left - info.right - 50
    height: dimensions.height - info.top - info.bottom - 50

  dimensions: dimensions
  info: info
  title: title
  canvas: canvas

module.exports = (spec, components) ->
  result =
    render: (dom, state, params) ->
      layout = calculate_layout params.dimensions

      svg = d3.select dom
        .append 'svg'
        .attr 'class', 'item windrose'

      data = state.data.map (d) ->
        time: d.time
        wsp: +d.wsp
        wd: +d.wd

      data = data.filter (d) -> return d if d.wd? and d.wsp?

      filteredData = data

      svg
        .attr 'width', layout.dimensions.width
        .attr 'height', layout.dimensions.height

      svg
        .append 'g'
        .attr 'class', 'title'
        .attr 'transform', "translate(#{layout.title.left},#{layout.title.top})"
        .append 'text'
        .attr 'class', 'infotext'
        .text spec.text
        .attr 'dy', 18

      inner = svg
        .append 'g'
        .attr 'class', 'inner'
        .attr 'transform', "translate(#{layout.canvas.left + layout.canvas.width/2},#{layout.canvas.top + layout.canvas.height/2})"

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

      for d in filteredData
        dir = calculate_direction d.wd
        frequency[dir].push d

      getSpeeds = (dir, items) ->
        speedArray =
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

        for i in items
          cat = calculate_speed_category i.wsp
          speedArray[cat].push i

        start = 0
        count = 0
        for cat, bits of speedArray
          result =
            index: count
            start: start
            end: start + bits.length
          start = result.end
          count++
          result

      groupedData = []
      angle = 0

      for dir, items of frequency
        groupedData.push
          key: angle
          value: dir
          count: items.length
          speeds: getSpeeds(dir, items)
        angle += 22.5

      scale = d3
        .scale
        .linear()
        .domain [0, 1.1 * d3.max groupedData, (d) -> d.count]
        .range [0, layout.canvas.width/2]

      diameter = (scale scale.domain()[1]) - 5

      circlecontainer = inner
        .append 'g'
        .attr 'class', 'circlecontainer'

      circlecontainer
        .append 'circle'
        .attr 'cx', 0
        .attr 'cy', 0
        .attr 'r', diameter - 120

      circlecontainer
        .append 'circle'
        .attr 'cx', 0
        .attr 'cy', 0
        .attr 'r', diameter - 80

      circlecontainer
        .append 'circle'
        .attr 'cx', 0
        .attr 'cy', 0
        .attr 'r', diameter - 40
        .text diameter - 40

      circlecontainer
        .append 'circle'
        .attr 'cx', 0
        .attr 'cy', 0
        .attr 'r', diameter

      axis = inner
        .selectAll '.axis'
        .data [
            { key: 0, value: 'N' }
            { key: 45, value: 'NE' }
            { key: 90, value: 'E' }
            { key: 135, value: 'SE' }
            { key: 180, value: 'S' }
            { key: 225, value: 'SW' }
            { key: 270, value: 'W' }
            { key: 315, value: 'NW' }
          ]
        .enter()
        .append 'g'
        .attr 'class', 'axis'
        .attr 'transform', (d) -> "rotate(#{d.key})"

      arc = (o) ->
        d3
        .svg
        .arc()
        .startAngle (d) ->(- o.width / 2) * Math.PI/180
        .endAngle (d) -> (+ o.width / 2) * Math.PI/180
        .innerRadius o.from
        .outerRadius o.to

      axis
        .append 'line'
        .attr 'class', 'spoke'
        .attr 'x1', scale 0
        .attr 'y1', scale 0
        .attr 'x2', scale 0
        .attr 'y2', layout.canvas.width/2

      axis
        .append 'g'
        .attr 'transform', (d) -> "translate(#{scale 0},#{(layout.canvas.height * (-0.53))})"
        .append 'text'
        .attr 'transform', (d) -> "rotate(#{-d.key})"
        .attr 'style', 'text-anchor: middle'
        .attr 'dy', '0.25em'
        .text (d) -> d.value


      segment = inner
        .selectAll '.segment'
        .data groupedData
        .enter()
        .append 'g'
        .attr 'class', 'segment'
        .attr 'transform', (d) -> "rotate(#{d.key})"
        .selectAll 'path'
        .data (d) -> d.speeds
        .enter()
        .append 'path'
        .attr('d', arc
          width: 360 / 24 * 0.8
          from: (d) -> scale d.start
          to: (d) -> scale d.end
        )
        .style 'fill', (d) -> colorScale d.index

      circlecontainer
        .append 'text'
        .text 0
        .attr 'x', 0
        .attr 'y', 0

      circlecontainer
        .append 'text'
        .text diameter - 120
        .attr 'x', 0
        .attr 'y', -(diameter - 120)

      circlecontainer
        .append 'text'
        .text diameter - 80
        .attr 'x', 0
        .attr 'y', -(diameter - 80)

      circlecontainer
        .append 'text'
        .text diameter - 40
        .attr 'x', 0
        .attr 'y', -(diameter - 40)

      circlecontainer
        .append 'text'
        .text diameter
        .attr 'x', 0
        .attr 'y', -diameter