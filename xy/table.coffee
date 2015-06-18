###

Plot an xy table with heatmap.

TODO: Work out how to position these xy visualisations.
TODO: Allow the different categories and values to be specified.

###

d3 = require 'd3'
colorbrewer = require 'colorbrewer'

calculate_layout = (dimensions, field, rowData) ->
  dimensions =
    width: dimensions[0]
    height: field.height * (rowData.length + 2)

  info =
    top: 0
    right: 0
    bottom: 13
    left: 200

  canvas =
    top: info.top + 30
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

      cat = (d[spec.category] for d in state.data)
      dir = {}
      for col in spec.columns
        dir[col] = (d[col] for d in state.data)
      data = cat: cat, dir: dir
      globalMin = d3.min((d3.min((+x for x in v)) for k, v of data.dir))
      globalMax = d3.max((d3.max((+x for x in v)) for k, v of data.dir))


      makeRows = (data) ->
        dirkeys = Object.keys data.dir
        for cat, index in data.cat
          dirkeys.map (dir) -> data.dir[dir][index]

      rowData = makeRows data

      # Rear-strip rows that are all zeros
      nRows = rowData.length
      nCols = spec.columns.length
      console.log 'nCols', nCols
      do ->
        zeroRows = (i for row, i in rowData when row.every (c) -> +c==0)
        return if zeroRows.length == 0
        finalNonZeroRow = nRows - 1
        while finalNonZeroRow in zeroRows
          finalNonZeroRow -= 1
        finalRow = finalNonZeroRow + 1  # Leave one zero row
        return if finalRow >= nRows
        data.cat = data.cat.slice 0, finalRow+1
        for k, v of data.dir
          v = v.slice 0, finalRow+1
        rowData = makeRows data


      field =
        height: 30
        width: 70


      layout = calculate_layout params.dimensions, field, rowData

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


      # X label
      svg.append 'text'
        .attr 'x', layout.info.left + (nCols + 1) * field.width / 2
        .attr 'y',  20 
        # .attr 'y',  layout.canvas.height + 50 
        .style 'text-anchor', 'middle'
        .text spec.columnLabel

      # Y label
      svg.append 'text'
        .attr 'text-anchor', 'middle'
        .attr 'x', (-1 * layout.canvas.height / 2)
        .attr 'y', layout.info.left
        .attr 'dy', '-2em'
        .attr 'transform', 'rotate(-90)'
        .text spec.categoryLabel

      svg.append 'a'
        .attr 'transform', "translate(0,50)"
        .attr 'xlink:href', 'https://hcd.metoceanview.com'
        .append 'text'
        .attr 'class', 'infotext'
        .attr 'dy', 20
        .text 'Download'

      # # Y label
      # svg.append 'text'
      #   .attr 'text-anchor', 'middle'
      #   .attr 'x', (-1 * layout.canvas.height / 2)
      #   .attr 'y', layout.info.left
      #   .attr 'dy', '-2em'
      #   .attr 'transform', 'rotate(-90)'
      #   .text spec.yLabel

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

      colorScale = d3.scale.quantize()
        .range colorbrewer.Blues[9]
        .domain [globalMin, globalMax]

      textcolorScale = d3.scale.quantize()
        .range ["#000000", "#000000", "#000000", "#ffffff", "#ffffff"]
        .domain [globalMin, globalMax]

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
        .attr 'transform', (d, i) -> "translate(0, #{(i + 0.85)*(field.height)})"

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
