
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
    var data, filteredData, focus, label, labelShad, line, result, scale, svg, updatepoi;
    svg = null;
    label = null;
    labelShad = null;
    line = null;
    focus = null;
    updatepoi = null;
    data = null;
    filteredData = null;
    scale = null;
    return result = {
      update: function(state, params) {
        var end, getNeighbours, start;
        data = state.data;
        data = data.filter(function(d) {
          return d[spec.field] != null;
        });
        getNeighbours = neighbours(data, function(d) {
          return d.time;
        });
        start = getNeighbours(params.domain[0])[0];
        if (!start) {
          start = {
            time: params.domain[0]
          };
        }
        end = getNeighbours(params.domain[1]);
        end = end[end.length - 1];
        if (!end) {
          end = {
            time: params.domain[1]
          };
        }
        filteredData = data.filter(function(d) {
          return +d.time >= +start.time && +d.time <= +end.time;
        });
        return result.resize(params.dimensions);
      },
      render: function(dom, state, params) {
        var end, getNeighbours, poi, start;
        svg = dom.append('g');
        scale = params.scale;
        data = state.data;
        line = svg.append('path').attr('class', "" + spec.style + " " + spec.type).attr('d', '');
        labelShad = svg.append('text').attr('class', 'label-shad').attr('text-anchor', 'start').attr('dy', 12).text("" + spec.text + " (" + spec.units + ")");
        label = svg.append('text').attr('class', 'label').attr('text-anchor', 'start').attr('dy', 12).text("" + spec.text + " (" + spec.units + ")");
        focus = svg.append('g').attr('class', 'focus');
        focus.append('circle').attr('class', 'poi-circle').attr('display', 'none').attr('r', 4);
        focus.append('text').attr('class', 'poi-y-val-shad').attr('display', 'none').attr('dy', '-0.3em');
        focus.append('text').attr('class', 'poi-y-val').attr('display', 'none').attr('dy', '-0.3em');
        data = data.filter(function(d) {
          return d[spec.field] != null;
        });
        getNeighbours = neighbours(data, function(d) {
          return d.time;
        });
        start = getNeighbours(params.domain[0])[0];
        if (!start) {
          start = {
            time: params.domain[0]
          };
        }
        end = getNeighbours(params.domain[1]);
        end = end[end.length - 1];
        if (!end) {
          end = {
            time: params.domain[1]
          };
        }
        filteredData = data.filter(function(d) {
          return +d.time >= +start.time && +d.time <= +end.time;
        });
        poi = null;
        params.hub.on('poi', function(p) {
          poi = p;
          return updatepoi();
        });
        updatepoi = function() {
          var Neighbours, d, d0, d1, dxAttr, halfway, poiNeighbours, yValWidth;
          if (poi == null) {
            focus.select('.poi-circle').attr('display', 'none');
            focus.select('.poi-y-val-shad').attr('display', 'none');
            focus.select('.poi-y-val').attr('display', 'none');
            return;
          }
          yValWidth = +focus.select('.poi-y-val').node().getComputedTextLength();
          if ((params.dimensions[0] - (scale.x(poi)) - yValWidth) < yValWidth) {
            dxAttr = -yValWidth - 8;
          } else {
            dxAttr = 8;
          }
          Neighbours = neighbours(filteredData, function(d) {
            return d.time;
          });
          poiNeighbours = Neighbours(poi);
          d;
          if (poiNeighbours.length === 1) {
            d = poiNeighbours[0];
          } else if (+poiNeighbours[0].time < +params.domain[0]) {
            d = poiNeighbours[1];
          } else if (+poiNeighbours[1].time > +params.domain[1]) {
            d = poiNeighbours[0];
          } else {
            d0 = poiNeighbours[0];
            d1 = poiNeighbours[1];
            halfway = d0.time + (d1.time - d0.time) / 2;
            d = poi.isBefore(halfway) ? d0 : d1;
          }
          focus.select('.poi-circle').attr('display', null).attr('transform', "translate(" + (scale.x(d.time)) + ", " + (scale.y(d[spec.field])) + ")");
          focus.select('.poi-y-val-shad').attr('display', null).attr('transform', "translate(" + (scale.x(d.time)) + ", " + (scale.y(d[spec.field])) + ")").attr('dx', dxAttr).text("" + (d[spec.field].toPrecision(3)) + " (" + spec.units + ")");
          return focus.select('.poi-y-val').attr('display', null).attr('transform', "translate(" + (scale.x(d.time)) + ", " + (scale.y(d[spec.field])) + ")").attr('dx', dxAttr).text("" + (d[spec.field].toPrecision(3)) + " (" + spec.units + ")");
        };
        return result.resize(params.dimensions);
      },
      provideMax: function() {
        return d3.max(filteredData, function(d) {
          return d[spec.field];
        });
      },
      resize: function(dimensions) {
        var labelWidth, path;
        dimensions = dimensions;
        path = d3.svg.line().x(function(d) {
          return scale.x(d.time);
        }).y(function(d) {
          return scale.y(d[spec.field]);
        });
        line.attr('d', path(filteredData));
        labelWidth = +label.node().getComputedTextLength();
        labelShad.attr('transform', "translate(" + (dimensions[0] - labelWidth) + ", " + (scale.y(filteredData[filteredData.length - 2][spec.field])) + ")");
        label.attr('transform', "translate(" + (dimensions[0] - labelWidth) + ", " + (scale.y(filteredData[filteredData.length - 2][spec.field])) + ")");
        return updatepoi();
      }
    };
  };

}).call(this);
