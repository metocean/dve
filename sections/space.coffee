class ERspace
  constructor: (svg, dimensions, options) ->
    @svg = svg
    @options = options
    @calculate_layout dimensions
    @resize dimensions
    hub.on 'window dimensions changed', @resize

  calculate_layout: (dimensions) =>
    @margin =
      top: 0
      right: 20
      bottom: 0
      left: 20

    @dimensions =
      width: dimensions[0]
      height: @options.height

    @canvas =
      top: @margin.top
      right: @margin.right
      bottom: @margin.bottom
      left: @margin.left
      width: @dimensions.width - @margin.left - @margin.right
      height: @dimensions.height - @margin.top - @margin.bottom

  resize: (dimensions) =>
    @calculate_layout dimensions
    @svg
      .attr 'width', @dimensions.width
      .attr 'height', @dimensions.height
