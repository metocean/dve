
/*

Shows days of the week on a timeline.

TODO: Allow any resolution of time, e.g. seconds, hours, days, weeks, months and years.
TODO: Merge with timeheadings.

- type: dayheadings
  text: Date
 */

(function() {
  var calculate_layout, chrono, d3, d3Chrono, moment;

  d3 = require('d3');

  moment = require('moment-timezone');

  chrono = require('chronological');

  moment = chrono(moment);

  d3 = require('d3');

  d3Chrono = require('d3-chronological');

  d3 = d3Chrono(d3);

  calculate_layout = function(dimensions) {
    var canvas, info, margin;
    margin = {
      top: 0,
      right: 0,
      bottom: 0,
      left: 0
    };
    dimensions = {
      width: dimensions[0],
      height: 25
    };
    info = {
      top: 0,
      right: 0,
      bottom: 0,
      left: 20
    };
    canvas = {
      top: info.top,
      right: info.right,
      bottom: info.bottom,
      left: info.left,
      width: dimensions.width - info.left - info.right,
      height: dimensions.height - info.top - info.bottom
    };
    return {
      margin: margin,
      dimensions: dimensions,
      info: info,
      canvas: canvas
    };
  };

  module.exports = function(spec, components) {
    var axis, dayheadings, focus, inner, scale, svg, updatepoi;
    svg = null;
    inner = null;
    scale = null;
    axis = null;
    focus = null;
    updatepoi = null;
    return dayheadings = {
      render: function(dom, state, params) {
        var drag, everyDay, layout, poi, poifsm;
        layout = calculate_layout(params.dimensions);
        svg = d3.select(dom).append('svg').attr('class', 'item dayheadings');
        inner = svg.append('g').attr('class', 'inner').attr('transform', "translate(" + layout.canvas.left + "," + layout.canvas.top + ")");
        inner.append('line').attr('class', 'divider').attr('x1', 0).attr('x2', 0).attr('y1', 0).attr('y2', layout.dimensions.height);
        inner.append('g').attr('class', 'axis').attr("transform", "translate(0," + (-layout.canvas.top + 3 * layout.canvas.height / 4) + ")");
        everyDay = moment().tz('Australia/Sydney').startOf('d').every(1, 'd');
        scale = d3.chrono.scale('Australia/Sydney').domain(params.domain).nice(everyDay);
        axis = d3.svg.axis().scale(scale).tickFormat(function(d) {
          return d.format('ddd DD');
        });
        focus = inner.append('g').attr('class', 'focus');
        focus.append('line').attr('class', 'poi').attr('display', 'none').attr('y1', 0).attr('y2', layout.dimensions.height);
        focus.append('text').attr('class', 'poi-y-val-shad').attr('display', 'none').attr('dx', '-3em').attr('dy', 2);
        focus.append('text').attr('class', 'poi-y-val').attr('display', 'none').attr('dx', '-3em');
        poi = null;
        params.hub.on('poi', function(p) {
          poi = p;
          return updatepoi();
        });
        poifsm = {
          hide: function() {
            if (poi === null) {
              return;
            }
            return params.hub.emit('poi', null);
          },
          show: function(x) {
            var d, range;
            range = scale.range();
            if (range[0] > x || range[1] < x) {
              return poifsm.hide();
            }
            d = scale.invert(x);
            if (poi === d) {
              return;
            }
            return params.hub.emit('poi', moment(d));
          },
          update: function() {
            var dist, x;
            x = d3.mouse(inner.node())[0];
            if (poifsm.startx != null) {
              dist = Math.abs(poifsm.startx - x);
              if (dist < 10) {
                return;
              }
            }
            poifsm.startx = null;
            return poifsm.show(x);
          },
          mousedown: function() {
            var x;
            x = d3.mouse(inner.node())[0];
            if (poifsm.currentx == null) {
              return poifsm.show(x);
            }
            return poifsm.startx = x;
          },
          mouseup: function() {
            var dist, x;
            if (poifsm.startx == null) {
              return;
            }
            if (!poifsm.currentx) {
              poifsm.startx = null;
              return poifsm.hide();
            }
            dist = Math.abs(poifsm.startx - poifsm.currentx);
            if (dist < 10) {
              poifsm.startx = null;
              return poifsm.hide();
            }
            x = d3.mouse(inner.node())[0];
            return poifsm.show(x);
          }
        };
        drag = d3.behavior.drag().on('drag', poifsm.update);
        focus.append('rect').attr('class', 'foreground').style('fill', 'none').on('mousedown', poifsm.mousedown).on('mouseup', poifsm.mouseup).call(drag);
        updatepoi = function() {
          var xVal;
          if (poi == null) {
            focus.select('line.poi').attr('display', 'none');
            focus.select('.poi-y-val-shad').attr('display', 'none');
            focus.select('.poi-y-val').attr('display', 'none');
            return;
          }
          poifsm.currentx = scale(poi);
          focus.select('line.poi').attr('display', null).attr('x1', scale(poi)).attr('x2', scale(poi));
          if ((layout.canvas.width - scale(poi)) < 48) {
            xVal = layout.canvas.width - 48;
          } else if ((layout.canvas.left + scale(poi)) < 248) {
            xVal = 53;
          } else {
            xVal = scale(poi);
          }
          focus.select('.poi-y-val-shad').attr('display', null).attr('transform', "translate(" + (xVal + 3) + "," + (layout.canvas.height - 8) + ")").text(poi.format('ddd DD MMM'));
          return focus.select('.poi-y-val').attr('display', null).attr('transform', "translate(" + (xVal + 3) + "," + (layout.canvas.height - 7) + ")").text(poi.format('ddd DD MMM'));
        };
        return dayheadings.resize(params.dimensions);
      },
      resize: function(dimensions) {
        var layout;
        layout = calculate_layout(dimensions);
        svg.attr('width', layout.dimensions.width).attr('height', layout.dimensions.height);
        scale.range([0, layout.canvas.width]);
        inner.selectAll('.axis .tick line').data(scale.ticks(axis.ticks()[0])).attr('class', function(d) {
          if (d === 0) {
            return 'zero';
          } else {
            return null;
          }
        });
        inner.select('.axis').call(axis.tickSize(layout.canvas.height / 4));
        focus.select('.foreground').attr('height', layout.canvas.height).attr('width', layout.canvas.width);
        inner.selectAll('.axis text').data(scale.ticks(axis.ticks()[0])).attr('x', function(d) {
          var first;
          first = scale(d);
          d = moment(d).add(12, 'hours');
          return scale(d) - first;
        }).attr('dy', -layout.canvas.height / 2.5).style('font-size', 14);
        inner.select('.axis .domain').remove();
        return updatepoi();
      }
    };
  };

}).call(this);
