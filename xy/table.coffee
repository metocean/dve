###

Plot an xy table with heatmap.

TODO: Work out how to position these xy visualisations.
TODO: Allow the different categories and values to be specified.

###

d3 = require 'd3'
colorbrewer = require 'colorbrewer'

calculate_layout = (dimensions, nRows, nCols, params) ->

  innerMargin = 
    top: 60
    right: 0
    bottom: 0
    left: 70

  if params.megaMargin
    innerMargin.left *= 2

  maxContainerWidth = 800
  minContainerWidth = 400
  maxFieldWidth = 120

  field = 
    height: 30

  container = 
    width: Math.min(dimensions[0], maxContainerWidth)
  container.width = Math.max(container.width, minContainerWidth)

  inner = 
    left: innerMargin.left
    top: innerMargin.top
    width: Math.min(container.width - innerMargin.left - innerMargin.right, maxFieldWidth*nCols)
    height: field.height * nRows

  container.height = innerMargin.top + innerMargin.bottom + inner.height
  inner.bottom = inner.top + inner.height
  inner.right = inner.left + inner.width
  field.width = inner.width / nCols
  
  container: container
  inner: inner
  innerMargin: innerMargin
  field: field

module.exports = (spec, components) ->
  result =
    render: (dom, state, params) ->

      console.log 'state', state


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

      # Rear-strip rows that are all zeros (leaving the last one)
      nRows = rowData.length
      nCols = spec.columns.length
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
        nRows = rowData[0].length


      if params.roundToDp?
        for row, i in rowData
          for value, j in row
            value = parseFloat(value).toFixed(params.roundToDp).toString()
            rowData[i][j] = value



      layout = calculate_layout params.dimensions, nRows, nCols, params
      field =  layout.field

      svg = d3.select dom
        .append 'svg'
        .attr 'class', 'item table'
      svg
        .attr 'width', layout.container.width
        .attr 'height', layout.container.height

      inner = svg
        .append 'g'
        .attr 'class', 'inner'
        .attr 'transform', "translate(#{layout.inner.left},#{layout.inner.top})"
      inner.append 'text'
        .attr 'x', layout.inner.width / 2
        .attr 'y',  -1 * layout.innerMargin.top
        .attr 'dy', '1em'
        .style 'text-anchor', 'middle'
        .text spec.columnLabel
      inner.append 'text'
        .attr 'text-anchor', 'middle'
        .attr 'x', (-1 * layout.inner.height / 2)
        .attr 'y', -1 * layout.innerMargin.left
        .attr 'dy', '1em'
        .attr 'transform', 'rotate(-90)'
        .text spec.categoryLabel

      container =  inner
        .append 'g'
        .attr 'class', 'container'



      rowsGrp = container
        .append 'g'
        .attr 'class', 'rowsGrp'
        .attr 'transform', "translate(#{field.width*0.5}, 0)"

      colorScale = d3.scale.quantize()
        .range colorbrewer.Blues[9]
        .domain [globalMin, globalMax]
      textcolorScale = d3.scale.quantize()
        .range ["#000000", "#000000", "#000000", "#ffffff", "#ffffff"]
        .domain [globalMin, globalMax]

      if params.disableColoring
        colorScale = d3.scale.quantize()
          .range ["#fff"]
          .domain [globalMin, globalMax]
        textcolorScale = d3.scale.quantize()
          .range ["#000"]
          .domain [globalMin, globalMax]


      topheaderGrp = container
        .append 'g'
        .attr 'class', 'topheaderGrp'
      topheader = topheaderGrp
        .selectAll 'g'
        .data d3.keys data.dir
        .enter()
        .append 'g'
        .attr 'class', 'header top'
        .attr 'transform', (d, i) -> "translate(#{(i)*field.width}, #{-1 * field.height})"
      topheader.append 'rect'
        .attr 'width', field.width - 1
        .attr 'height', field.height
      topheader.append 'text'
        .attr 'x', field.width/2
        .attr 'y', field.height/2
        .attr 'dy', '0.35em'
        .text String

      headerWidth = 35
      if params.megaMargin
        headerWidth = layout.innerMargin.left
      sideheaderGrp = container
        .append 'g'
        .attr 'class', 'sideheaderGrp'
      sideheader = sideheaderGrp
        .selectAll 'g'
        .data data.cat, (d) -> d3.values d
        .enter()
        .append 'g'
        .attr 'class', 'header side'
        .attr 'transform', (d, i) -> "translate(#{-1 * headerWidth}, #{(i)*(field.height)})"
      sideheader.append 'rect'
        .attr 'width', headerWidth - 2
        .attr 'height', field.height
      sideheader.append 'text'
        .attr 'x', 0
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
        .attr 'transform', (d, i) -> "translate(#{i*field.width-field.width/2}, 0)"
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
