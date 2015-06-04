// Generated by CoffeeScript 1.9.2

/*

Create some breathing room in your visualisations.
Has a default height, or height can be specified.

- type: space
  height: 50
 */
var d3;

d3 = require('d3');

module.exports = function(spec, components) {
  var el, space;
  el = null;
  return space = {
    render: function(dom, state, params) {
      el = d3.select(dom).append('div').attr('class', 'item space');
      return space.resize(params.dimensions);
    },
    resize: function(dimensions) {
      return el.style('width', dimensions[0] + "px").style('height', (spec.height || 15) + "px");
    }
  };
};
