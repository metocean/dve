
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
var calculate_layout, d3, extend, moment;

d3 = require('d3');

moment = require('timespanner');

extend = require('extend');

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
    left: 200
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
  var axis, chart, data, focus, inner, items, maxDomains, result, scale, svg, updatepoi;
  svg = null;
  inner = null;
  scale = null;
  axis = null;
  focus = null;
  updatepoi = null;
  data = null;
  chart = null;
  items = [];
  maxDomains = [];
  return result = {
    render: function(dom, state, params) {
      var clipId, drag, item, j, layout, len, newparams, poi, poifsm, ref, s;
      layout = calculate_layout(params.dimensions);
      svg = d3.select(dom).append('svg').attr('class', 'item chart');
      svg.append('g').attr('class', 'title').append('text').attr('class', 'infotext').attr('y', 0).attr('x', 0).text(spec.text).style('fill', '#142c58').attr('dy', '20px');
      inner = svg.append('g').attr('class', 'inner').attr('transform', "translate(" + layout.canvas.left + "," + layout.canvas.top + ")");
      inner.append('g').attr('class', 'x axis').attr('transform', "translate(0," + layout.canvas.height + ")");
      inner.append('g').attr('class', 'y axis');
      clipId = "clip-" + (Math.floor(Math.random() * 1000000));
      chart = inner.append('g').attr('class', 'chart').attr('clip-path', "url(#" + clipId + ")");
      chart.append('defs').append('clipPath').attr('id', clipId).append('rect').attr('x', '0').attr('y', '0');
      scale = {
        x: d3.time.scale().domain(params.domain),
        y: d3.scale.linear()
      };
      axis = {
        x: d3.svg.axis().scale(scale.x).orient("bottom").ticks(d3.time.hour),
        y: d3.svg.axis().scale(scale.y).orient("left").ticks(6)
      };
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
          range = scale.x.range();
          if (range[0] > x || range[1] < x) {
            return poifsm.hide();
          }
          d = scale.x.invert(x);
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
      ref = spec.spec;
      for (j = 0, len = ref.length; j < len; j++) {
        s = ref[j];
        if (components[s.type] == null) {
          return console.error(s.type + " component not found");
        }
        newparams = extend({}, params, {
          axis: axis,
          scale: scale
        });
        item = components[s.type](s, components);
        item.render(chart, state, newparams);
        maxDomains.push(item.provideMax());
        items.push(item);
      }
      focus = inner.append('g').attr('class', 'focus');
      focus.append('line').attr('class', 'poi').attr('display', 'none').attr('y1', 0).attr('y2', layout.canvas.height);
      focus.append('rect').attr('class', 'foreground').style('fill', 'none').on('mousedown', poifsm.mousedown).on('mouseup', poifsm.mouseup).call(drag);
      updatepoi = function() {
        if (poi == null) {
          poifsm.currentx = scale.x(poi);
          focus.select('line.poi').attr('display', 'none');
          return;
        }
        poifsm.currentx = scale.x(poi);
        return focus.select('line.poi').attr('display', null).attr('x1', scale.x(poi)).attr('x2', scale.x(poi));
      };
      return result.resize(params.dimensions);
    },
    resize: function(dimensions) {
      var i, j, layout, len;
      layout = calculate_layout(dimensions);
      svg.attr('width', layout.dimensions.width).attr('height', layout.dimensions.height);
      chart.select('rect').attr('width', layout.canvas.width).attr('height', layout.canvas.height);
      scale.y.domain([0, 1.1 * d3.max(maxDomains)]);
      scale.x.range([0, layout.canvas.width]);
      scale.y.range([layout.canvas.height, 0]);
      inner.select('.x.axis').call(axis.x.tickSize(-layout.canvas.height, 0, 0).tickFormat(''));
      inner.selectAll('.x.axis .tick line').data(scale.x.ticks(axis.x.ticks()[0])).attr('class', function(d) {
        d = moment(d).format('HH');
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
      for (j = 0, len = items.length; j < len; j++) {
        i = items[j];
        if (i.resize == null) {
          continue;
        }
        i.resize([layout.canvas.width, layout.canvas.height]);
      }
      return updatepoi();
    }
  };
};