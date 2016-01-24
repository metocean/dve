
/*

Plot a series of dots on a chart.
Great for discontinuous like observations.

TODO: Same todos as line
 */

(function() {
  var d3, neighbours;

  d3 = require('d3');

  neighbours = require('../util/neighbours');

  module.exports = function(spec, components) {
    var data, dotContainer, drawDots, filteredData, focus, label, labelShad, prevDimensions, result, scale, svg, updatepoi, value;
    svg = null;
    label = null;
    labelShad = null;
    dotContainer = null;
    focus = null;
    updatepoi = null;
    data = null;
    filteredData = null;
    scale = null;
    prevDimensions = null;
    value = {
      x: function(d) {
        return d.time;
      },
      y: function(d) {
        return d[spec.field];
      }
    };
    drawDots = function(svg, data) {
      return svg.selectAll(".dot").data(data).attr("cx", function(d) {
        return scale.x(value.x(d));
      }).attr("cy", function(d) {
        return scale.y(value.y(d));
      });
    };
    return result = {
      update: function(state, params) {
        var end, getNeighbours, start;
        data = state.data.filter(function(datum) {
          return datum[spec.field] != null;
        });
        getNeighbours = neighbours(data, function(d) {
          return d.time;
        });
        start = getNeighbours(params.domain[0])[0];
        end = getNeighbours(params.domain[1]);
        end = end[end.length - 1];
        filteredData = data.filter(function(d) {
          return +d.time >= +start.time && +d.time <= +end.time;
        });
        return drawDots(svg, filteredData);
      },
      render: function(dom, state, params) {
        var end, getNeighbours, poi, start;
        svg = dom.append('g');
        scale = params.scale;
        data = state.data.filter(function(d) {
          return d[spec.field] != null;
        });
        getNeighbours = neighbours(data, function(d) {
          return d.time;
        });
        start = getNeighbours(params.domain[0])[0];
        end = getNeighbours(params.domain[1]);
        end = end[end.length - 1];
        filteredData = data.filter(function(d) {
          return +d.time >= +start.time && +d.time <= +end.time;
        });
        dotContainer = svg.append('g');
        dotContainer.selectAll(".dot").data(filteredData).enter().append("circle").attr("class", "dot").attr("r", 3.5);
        focus = svg.append('g').attr('class', 'focus');
        focus.append('text').attr('class', 'poi-y-val-shad').attr('display', 'none').attr('dy', '-0.3em');
        focus.append('text').attr('class', 'poi-y-val').attr('display', 'none').attr('dy', '-0.3em');
        poi = null;
        params.hub.on('poi', function(p) {
          poi = p;
          return updatepoi();
        });
        updatepoi = function() {
          var Neighbours, d, d0, d1, dxAttr, halfway, poiNeighbours, yValWidth;
          if (poi == null) {
            focus.select('.poi-y-val-shad').attr('display', 'none');
            focus.select('.poi-y-val').attr('display', 'none');
            svg.selectAll('.dot').data(filteredData).style('fill', 'rgb(20, 44, 88)');
            return;
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
          svg.selectAll('.dot').data(filteredData).style('fill', function(f) {
            if (f.time === d.time) {
              return 'rgb(216, 34, 42)';
            }
          });
          yValWidth = +focus.select('.poi-y-val').node().getComputedTextLength();
          if ((params.dimensions[0] - (scale.x(poi)) - yValWidth) < yValWidth) {
            dxAttr = -yValWidth - 8;
          } else {
            dxAttr = 8;
          }
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
        drawDots(dotContainer, filteredData);
        return updatepoi();
      }
    };
  };

}).call(this);
