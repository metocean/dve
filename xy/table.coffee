###

Plot an xy table with heatmap.

TODO: Work out how to position these xy visualisations.
TODO: Allow the different categories and values to be specified.

###

d3 = require 'd3'
colorbrewer = require 'colorbrewer'

calculate_layout = (dimensions) ->
  dimensions =
    width: dimensions[0]
    height: 450

  info =
    top: 0
    right: 0
    bottom: 13
    left: 200

  canvas =
    top: info.top
    right: info.right
    bottom: info.bottom
    left: info.left
    width: dimensions.width - info.left - info.right
    height: dimensions.height - info.top - info.bottom

  dimensions: dimensions
  info: info
  canvas: canvas

module.exports = (spec, components) ->
  result =
    render: (dom, state, params) ->
      layout = calculate_layout params.dimensions

      svg = d3.select dom
        .append 'svg'
        .attr 'class', 'item table'

      # data = data.map (d) ->
      #   result =
      #     time : d.time
      #     wsp : +d.wsp
      #   result

      # data = data.filter (d) -> return d.wsp?

      # filteredData = data.filter (d) ->
      #   +d.time >= +@domain[0] and +d.time <= +@domain[1]

      svg
        .attr 'width', layout.dimensions.width
        .attr 'height', layout.dimensions.height

      svg
        .append 'g'
        .attr 'class', 'title'
        .append 'text'
        .attr 'class', 'infotext'
        .text spec.text
        .attr 'dy', 20

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

       # need to make these equal to the longest string in the data set
      field =
        height: 30
        width: 70

      container =  inner
        .append 'g'
        .attr 'class', 'container'
        .attr 'transform', "translate(10, 10)"

      topheaderGrp = container
        .append 'g'
        .attr 'class', 'topheaderGrp'

      sideheaderGrp = container
        .append 'g'
        .attr 'class', 'sideheaderGrp'

      rowsGrp = container
        .append 'g'
        .attr 'class', 'rowsGrp'
        .attr 'transform', "translate(#{field.width*0.75}, #{field.height*0.85})"

      data = {
        dir: {
          N: [
            0.90
            2.74
            3.12
            1.98
            0.93
            0.42
            0.16
            0.03
            0.00
            0.00
            0.00
            0.00
            0.00
          ]
          NE: [
            0.89
            3.14
            5.51
            4.38
            1.68
            0.48
            0.09
            0.01
            0.00
            0.00
            0.00
            0.00
            0.00
          ]
          E: [
            0.80
            2.43
            4.07
            3.84
            2.08
            0.70
            0.13
            0.02
            0.01
            0.00
            0.00
            0.00
            0.00
          ]
          SE: [
            0.71
            1.53
            1.63
            0.95
            0.46
            0.13
            0.04
            0.01
            0.00
            0.00
            0.00
            0.00
            0.00
          ]
          S: [
            0.67
            1.45
            1.73
            1.30
            0.70
            0.39
            0.16
            0.05
            0.01
            0.00
            0.00
            0.00
            0.00
          ]
          SW: [
            0.72
            2.35
            3.67
            4.05
            3.23
            2.18
            1.17
            0.47
            0.17
            0.05
            0.01
            0.00
            0.00
          ]
          W: [
            0.91
            2.72
            4.00
            4.08
            2.94
            1.77
            0.85
            0.31
            0.10
            0.02
            0.00
            0.00
            0.00
          ]
          NW: [
            0.83
            2.61
            3.17
            2.56
            1.45
            0.72
            0.30
            0.11
            0.02
            0.01
            0.00
            0.00
            0.00
          ]
        }
        cat: [
          '0-5'
          '5-10'
          '10-15'
          '15-20'
          '20-25'
          '25-30'
          '30-35'
          '35-40'
          '40-45'
          '45-50'
          '50-55'
          '55-60'
          '60-65'
        ]
      }

      rowData = []
      dirkeys = Object.keys data.dir
      for cat, index in data.cat
        rowData.push dirkeys.map (dir) -> data.dir[dir][index]

      colorScale = d3.scale.quantize()
        .range colorbrewer.Blues[9]
        .domain [-0.75, 9]

      textcolorScale = d3.scale.quantize()
        .range ["#000000", "#000000", "#000000", "#ffffff", "#ffffff"]
        .domain [-0.75, 9]

      topheader = topheaderGrp
        .selectAll 'g'
        .data d3.keys data.dir
        .enter()
        .append 'g'
        .attr 'class', 'header top'
        .attr 'transform', (d, i) -> "translate(#{(i + 0.65)*field.width},0)"

      topheader.append 'rect'
        .attr 'width', field.width - 1
        .attr 'height', field.height

      topheader.append 'text'
        .attr 'x', field.width/2
        .attr 'y', field.height/2
        .attr 'dy', '0.35em'
        .text String

      sideheader = sideheaderGrp
        .selectAll 'g'
        .data data.cat, (d) -> d3.values d
        .enter()
        .append 'g'
        .attr 'class', 'header side'
        .attr 'transform', (d, i) -> "translate(0, #{(i + 0.75)*(field.height)})"

      sideheader.append 'rect'
        .attr 'width', field.width - 1
        .attr 'height', field.height

      sideheader.append 'text'
        .attr 'x', field.width/2
        .attr 'y', field.height/2
        .attr 'dy', '0.35em'
        .text String

      row = rowsGrp
        .selectAll 'g.row'
        .data rowData

      row
        .enter()
        .append 'g'
        .attr 'class', 'row'
        .attr 'transform', (d, i) -> "translate(0, #{i*field.height})"

      cells = row.selectAll 'g.cell'
        .data (d) -> d

      cellsEnter = cells
        .enter()
        .append 'g'
        .attr 'class', 'cell'
        .attr 'transform', (d, i) -> "translate(#{i*field.width}, 0)"

      cellsEnter
        .append 'rect'
        .attr 'width', field.width - 1
        .attr 'height', field.height - 1
        .style 'fill', colorScale

      cellsEnter
        .append 'text'
        .attr 'x', field.width/2
        .attr 'y', field.height/2
        .attr 'dy', '0.35em'
        .text String
        .style 'fill', textcolorScale
