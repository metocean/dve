d3 = require 'd3'

calculate_layout = (dimensions) =>
  margin =
    top: 0
    right: 0
    bottom: 0
    left: 0

  dimensions =
    width: dimensions[0]
    height: 25

  canvas =
    top: margin.top
    right: margin.right
    bottom: margin.bottom
    left: margin.left
    width: dimensions.width - margin.left - margin.right
    height: dimensions.height - margin.top - margin.bottom

  margin: margin
  dimensions: dimensions
  canvas: canvas

module.exports = (dom, options) ->
  { spec, dimensions } = options
  layout = calculate_layout dimensions

  svg = d3.select dom
    .append 'svg'
    .attr 'class', 'item title'
  svg
    .append 'g'
    .attr 'class', 'title'
    .attr 'transform', "translate(#{layout.canvas.left},#{layout.canvas.top})"
    .append 'text'
    .attr 'class', 'infotext'
    .attr 'dy', 20
    .attr 'dx', 5
    .text spec.text

  resize = (dimensions) ->
    layout = calculate_layout dimensions
    svg
      .attr 'width', layout.dimensions.width
      .attr 'height', layout.dimensions.height

  resize dimensions

  resize: resize