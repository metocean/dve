
/*

Plot a single line on a chart.
Great for continuous data.
Not great for observations or direction.
Can include style for css based line styles.

TODO: Add points of interest such as local maxima and minima.
TODO: Push series labels to chart for overlapping adjustment.
 */

(function() {
  var d3, neighbours;

  d3 = require('d3');

  neighbours = require('../util/neighbours');

  module.exports = function(spec, components) {
    var data, line, negative, positive, prevdimensions, result, scale, selectdata, svg;
    svg = null;
    line = null;
    positive = null;
    negative = null;
    data = null;
    scale = null;
    prevdimensions = null;
    selectdata = function(state, params) {
      var end, getNeighbours, start;
      data = state.data.filter(function(d) {
        return d[spec.lower] != null;
      });
      getNeighbours = neighbours(data, function(d) {
        return d.time;
      });
      start = getNeighbours(params.domain[0])[0];
      end = getNeighbours(params.domain[1]);
      end = end[end.length - 1];
      return data.filter(function(d) {
        return +d.time >= +start.time && +d.time <= +end.time;
      });
    };
    return result = {
      id: spec.id,
      update: function(state, params) {
        selectdata(state, params);
        return result.resize(prevdimensions);
      },
      init: function(state, params) {
        if (params.hub != null) {
          return params.hub.on('state updated', function(state) {
            data = selectdata(state, params);
            return result.resize(prevdimensions);
          });
        }
      },
      render: function(dom, state, params) {
        svg = dom.append('g');
        scale = params.scale;
        positive = svg.append('path').attr('class', "" + spec.style + " " + spec.type).attr('d', '');
        data = selectdata(state, params);
        prevdimensions = params.dimensions;
        return result.resize(prevdimensions);
      },
      provideMax: function() {
        return d3.max(data, function(d) {
          return d[spec.upper];
        });
      },
      resize: function(dimensions) {
        var positivearea;
        prevdimensions = dimensions;
        positivearea = d3.svg.area().x(function(d) {
          return scale.x(d.time);
        }).y0(function(d) {
          return scale.y(d[spec.lower]);
        }).y1(function(d) {
          return scale.y(d[spec.upper]);
        });
        positive.attr('d', positivearea(data));
        return true;
      }
    };
  };

}).call(this);
