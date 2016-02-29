
/*

Add a series plotting area.

TODO: Add height as an attribute so it's not hardcoded
TODO: Region series for areas. E.g. probabilities, min and max.

- type: chart
  text: Wind Speed
  spec:
  - type: line
    style: primary
    text: Wind Speed 10m
    field: wsp
    units: kts
  - type: line
    style: secondary
    text: Gust 10m
    field: gst
    units: kts
 */

(function() {
  var calculate_layout, chrono, d3, d3Chrono, extend, moment, neighbours;

  d3 = require('d3');

  extend = require('extend');

  neighbours = require('../util/neighbours');

  moment = require('moment-timezone');

  chrono = require('chronological');

  moment = chrono(moment);

  d3 = require('d3');

  d3Chrono = require('d3-chronological');

  d3 = d3Chrono(d3);

  calculate_layout = function(dimensions) {
    var canvas, info;
    dimensions = {
      width: dimensions[0],
      height: 120
    };
    info = {
      top: 0,
      right: 0,
      bottom: 3,
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
      dimensions: dimensions,
      info: info,
      canvas: canvas
    };
  };

  module.exports = function(spec, components) {
    var Neighbours, average, axis, chart, focus, inner, items, maxDomains, range, result, roundtoclosest, scale, svg, updaterange;
    svg = null;
    inner = null;
    scale = null;
    axis = null;
    focus = null;
    updaterange = null;
    range = null;
    chart = null;
    items = [];
    maxDomains = [];
    roundtoclosest = null;
    Neighbours = null;
    average = null;
    return result = {
      init: function(state, params) {
        var item, s, _i, _len, _ref;
        _ref = spec.spec;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          s = _ref[_i];
          if (components[s.type] == null) {
            return console.error("" + s.type + " component not found");
          }
          item = components[s.type](s, components);
          if (item.init != null) {
            item.init(state, params);
          }
          items.push(item);
        }
        Neighbours = neighbours(state.data, function(d) {
          return d.time;
        });
        average = function(p, fn) {
          var pn, total, _j, _len1;
          pn = Neighbours(p);
          total = 0;
          for (_j = 0, _len1 = pn.length; _j < _len1; _j++) {
            item = pn[_j];
            total += fn(item);
          }
          return total / pn.length;
        };
        params.hub.on('range', function(p) {
          if (!p) {
            range = null;
            updaterange();
            return;
          }
          range = p;
          return updaterange();
        });
        params.hub.on('range nudge back', function(p) {
          var d, i, m, newp1, newp2, p1index, p2index, _j, _k, _len1, _len2, _ref1, _ref2;
          if (range == null) {
            return;
          }
          newp1 = range.p1;
          p1index = null;
          _ref1 = state.data;
          for (i = _j = 0, _len1 = _ref1.length; _j < _len1; i = ++_j) {
            d = _ref1[i];
            if (d.time.isSame(range.p1)) {
              if (i === 0) {
                break;
              }
              newp1 = state.data[i - 1].time.clone();
              break;
            }
          }
          newp2 = range.p2;
          p2index = null;
          _ref2 = state.data;
          for (i = _k = 0, _len2 = _ref2.length; _k < _len2; i = ++_k) {
            d = _ref2[i];
            if (d.time.isSame(range.p2)) {
              if (i === 0) {
                break;
              }
              newp2 = state.data[i - 1].time.clone();
              break;
            }
          }
          if (newp1.isBefore(params.domain[0])) {
            newp1 = params.domain[0].clone();
          }
          if (newp2.isBefore(params.domain[0])) {
            newp2 = params.domain[0].clone();
          }
          m = newp1 + (newp2 - newp1) / 2;
          return params.hub.emit('range', {
            p1: newp1,
            p2: newp2,
            m: m,
            ma: average(m, function(d) {
              return d.valueOffset;
            })
          });
        });
        return params.hub.on('range nudge forward', function(p) {
          var d, i, m, newp1, newp2, p1index, p2index, _j, _k, _len1, _len2, _ref1, _ref2;
          if (range == null) {
            return;
          }
          newp1 = range.p1;
          p1index = null;
          _ref1 = state.data;
          for (i = _j = 0, _len1 = _ref1.length; _j < _len1; i = ++_j) {
            d = _ref1[i];
            if (d.time.isSame(range.p1)) {
              if (i === state.data.length - 1) {
                break;
              }
              newp1 = state.data[i + 1].time.clone();
              break;
            }
          }
          newp2 = range.p2;
          p2index = null;
          _ref2 = state.data;
          for (i = _k = 0, _len2 = _ref2.length; _k < _len2; i = ++_k) {
            d = _ref2[i];
            if (d.time.isSame(range.p2)) {
              if (i === state.data.length - 1) {
                break;
              }
              newp2 = state.data[i + 1].time.clone();
              break;
            }
          }
          if (newp1.isAfter(params.domain[1])) {
            newp1 = params.domain[1].clone();
          }
          if (newp2.isAfter(params.domain[1])) {
            newp2 = params.domain[1].clone();
          }
          m = newp1 + (newp2 - newp1) / 2;
          return params.hub.emit('range', {
            p1: newp1,
            p2: newp2,
            m: m,
            ma: average(m, function(d) {
              return d.valueOffset;
            })
          });
        });
      },
      updateField: function(itemId, state, params) {
        var newMa;
        items.forEach(function(item) {
          if (item.id === itemId) {
            return item.updateData(state, params);
          }
        });
        Neighbours = neighbours(state.data, function(d) {
          return d.time;
        });
        if (range) {
          newMa = average(range.m, function(d) {
            return d.valueOffset;
          });
          if (range.ma !== newMa) {
            range.ma = newMa;
            return params.onRangeSelect({
              start: range.p1,
              center: range.ma,
              end: range.p2
            });
          }
        }
      },
      render: function(dom, state, params) {
        var clipId, drag, everyDay, item, layout, newparams, rangefsm, _i, _len;
        layout = calculate_layout(params.dimensions);
        svg = d3.select(dom).append('svg').attr('class', 'item chart');
        inner = svg.append('g').attr('class', 'inner').attr('transform', "translate(" + layout.canvas.left + "," + layout.canvas.top + ")");
        inner.append('g').attr('class', 'x axis').attr('transform', "translate(0," + layout.canvas.height + ")");
        inner.append('g').attr('class', 'y axis');
        clipId = "clip-" + (Math.floor(Math.random() * 1000000));
        chart = inner.append('g').attr('class', 'chart').attr('clip-path', "url(#" + clipId + ")");
        chart.append('defs').append('clipPath').attr('id', clipId).append('rect').attr('x', '0').attr('y', '0');
        everyDay = moment().tz('Australia/Sydney').startOf('d').every(1, 'd');
        scale = {
          x: d3.chrono.scale('Australia/Sydney').domain(params.domain).nice(everyDay),
          y: d3.scale.linear()
        };
        axis = {
          x: d3.svg.axis().scale(scale.x).orient("bottom"),
          y: d3.svg.axis().scale(scale.y).orient("left").ticks(6)
        };
        roundtoclosest = function(p) {
          var d0, d1, halfway, pn;
          pn = Neighbours(p);
          if (pn.length === 1) {
            return pn[0];
          } else if (+pn[0].time < +params.domain[0]) {
            return pn[1];
          } else if (+pn[1].time > +params.domain[1]) {
            return pn[0];
          } else {
            d0 = pn[0];
            d1 = pn[1];
            halfway = d0.time + (d1.time - d0.time) / 2;
            if (p.isBefore(halfway)) {
              return d0;
            } else {
              return d1;
            }
          }
        };
        rangefsm = {
          hide: function() {
            rangefsm.startx = null;
            rangefsm.p1 = null;
            rangefsm.p2 = null;
            if (range === null) {
              return;
            }
            return params.hub.emit('range', null);
          },
          show: function(x) {
            var m, p1, p1d, p2, p2d;
            rangefsm.p2 = x;
            p1d = moment(scale.x.invert(rangefsm.p1));
            p2d = moment(scale.x.invert(rangefsm.p2));
            p1 = roundtoclosest(p1d);
            p2 = roundtoclosest(p2d);
            m = p1.time + (p2.time - p1.time) / 2;
            return params.hub.emit('range', {
              p1: p1.time,
              p2: p2.time,
              m: m,
              ma: average(m, function(d) {
                return d.valueOffset;
              })
            });
          },
          getx: function() {
            var x;
            x = d3.mouse(inner.node())[0];
            return x;
          },
          update: function() {
            var x;
            x = rangefsm.getx();
            if (rangefsm.startx != null) {
              if (Math.abs(rangefsm.startx - x) < 10) {
                return;
              }
              rangefsm.p1 = rangefsm.startx;
              rangefsm.startx = null;
            }
            return rangefsm.show(x);
          },
          touchstart: function() {
            var x;
            x = rangefsm.getx();
            if (rangefsm.p1 != null) {
              return rangefsm.startx = x;
            }
            rangefsm.p1 = x;
            return rangefsm.show(x);
          },
          mousedown: function() {
            var x;
            if (rangefsm.ignorenextdown) {
              rangefsm.ignorenextdown = null;
              return;
            }
            x = rangefsm.getx();
            if (rangefsm.p1 != null) {
              return rangefsm.startx = x;
            }
            rangefsm.p1 = x;
            return rangefsm.show(x);
          },
          touchend: function() {
            return rangefsm.ignorenextdown = true;
          },
          mouseup: function() {
            var x;
            if (rangefsm.startx != null) {
              return rangefsm.hide();
            }
            x = rangefsm.getx();
            return rangefsm.show(x);
          }
        };
        drag = d3.behavior.drag().on('drag', rangefsm.update);
        for (_i = 0, _len = items.length; _i < _len; _i++) {
          item = items[_i];
          newparams = extend({}, params, {
            axis: axis,
            scale: scale
          });
          item.render(chart, state, newparams);
          if (item.provideMax) {
            maxDomains.push(item.provideMax());
          }
        }
        focus = inner.append('g').attr('class', 'focus');
        focus.append('line').attr('class', 'rangestart').attr('display', 'none').attr('y1', 0).attr('y2', layout.canvas.height);
        focus.append('line').attr('class', 'rangeend').attr('display', 'none').attr('y1', 0).attr('y2', layout.canvas.height);
        focus.append('line').attr('class', 'rangemiddle').attr('display', 'none').attr('y1', 0).attr('y2', layout.canvas.height);
        focus.append('rect').attr('class', 'foreground').style('fill', 'none').on('touchstart', rangefsm.touchstart).on('touchend', rangefsm.touchend).on('mousedown', rangefsm.mousedown).on('mouseup', rangefsm.mouseup).call(drag);
        updaterange = function() {
          if (range == null) {
            params.onRangeSelect && params.onRangeSelect(null);
            focus.select('line.rangestart').attr('display', 'none');
            focus.select('line.rangeend').attr('display', 'none');
            focus.select('line.rangemiddle').attr('display', 'none');
            return;
          }
          if (params.onRangeSelect) {
            params.onRangeSelect({
              start: range.p1,
              center: range.ma,
              end: range.p2
            });
          }
          focus.select('line.rangestart').attr('display', null).attr('x1', scale.x(range.p1)).attr('x2', scale.x(range.p1));
          focus.select('line.rangeend').attr('display', null).attr('x1', scale.x(range.p2)).attr('x2', scale.x(range.p2));
          return focus.select('line.rangemiddle').attr('display', null).attr('x1', scale.x(range.m)).attr('x2', scale.x(range.m));
        };
        result.resize(params.dimensions);
        updaterange();
        if (range != null) {
          return params.hub.emit('range', {
            p1: range.p1,
            p2: range.p2,
            m: range.m,
            ma: average(range.m, function(d) {
              return d.valueOffset;
            })
          });
        }
      },
      resize: function(dimensions) {
        var i, layout, _i, _len, _results;
        layout = calculate_layout(dimensions);
        svg.attr('width', layout.dimensions.width).attr('height', layout.dimensions.height);
        chart.select('rect').attr('width', layout.canvas.width).attr('height', layout.canvas.height);
        scale.y.domain([0, 1.1 * d3.max(maxDomains)]);
        scale.x.range([0, layout.canvas.width]);
        scale.y.range([layout.canvas.height, 0]);
        inner.select('.x.axis').call(axis.x.tickSize(-layout.canvas.height, 0, 0).tickFormat(''));
        inner.selectAll('.x.axis .tick line').data(scale.x.ticks(axis.x.ticks()[0])).attr('class', function(d) {
          d = d.format('HH');
          if (d === '00') {
            return 'major';
          } else if (d === '12') {
            return 'minor';
          } else {
            return 'sub-minor';
          }
        });
        inner.select('.y.axis').call(axis.y.tickSize(-layout.canvas.width, 0, 0));
        inner.select('.y.axis .tick text').text(' ');
        inner.selectAll('.y.axis .tick line').data(scale.y.ticks(axis.y.ticks()[0])).attr('class', function(d) {
          if (d === 0) {
            return 'zero';
          } else {
            return null;
          }
        });
        focus.select('.foreground').attr('height', layout.canvas.height).attr('width', layout.canvas.width);
        _results = [];
        for (_i = 0, _len = items.length; _i < _len; _i++) {
          i = items[_i];
          if (i.provideMax() <= d3.max(maxDomains)) {
            continue;
          }
          maxDomains = [i.provideMax()];
          if (i.resize == null) {
            continue;
          }
          _results.push(i.resize([layout.canvas.width, layout.canvas.height]));
        }
        return _results;
      }
    };
  };

}).call(this);
