###

Create some breathing room in your visualisations.
Has a default height, or height can be specified.

- type: space
  height: 50

###

d3 = require 'd3'

module.exports = (dom, options) ->
  { dimensions, spec } = options
  dom = d3.select dom
    .append 'div'
    .attr 'class', 'item space'

  resize = (dimensions) ->
    dom
      .style 'width', "#{dimensions[0]}px"
      .style 'height', "#{spec.height or 15}px"

  resize dimensions

  resize: resize
