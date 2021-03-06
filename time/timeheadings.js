// Generated by CoffeeScript 1.9.3

/*

TODO: Merge with dayheadings

- type: timeheadings
  text: Time
 */
var calculate_layout, d3, moment;

d3 = require('d3');

moment = require('timespanner');

calculate_layout = function(dimensions) {
  var canvas, info, margin, title;
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
    left: 200
  };
  title = {
    top: 0,
    right: dimensions.width - info.left,
    bottom: 0,
    left: 0,
    height: dimensions.height,
    width: info.left
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
    title: title,
    canvas: canvas
  };
};

module.exports = function(spec, components) {
  var axis, focus, inner, scale, svg, timeheadings, updatepoi;
  svg = null;
  inner = null;
  scale = null;
  axis = null;
  focus = null;
  updatepoi = null;
  return timeheadings = {
    render: function(dom, state, params) {
      var drag, getTimezone, layout, poi, poifsm;
      layout = calculate_layout(params.dimensions);
      svg = d3.select(dom).append('svg').attr('class', 'item timeheadings');
      svg.append('g').attr('class', 'title').attr('transform', "translate(" + layout.title.left + "," + layout.title.top + ")").append('text').attr('class', 'infotext').attr('dy', 20);
      inner = svg.append('g').attr('class', 'inner').attr('transform', "translate(" + layout.canvas.left + "," + layout.canvas.top + ")");
      inner.append('line').attr('class', 'divider').attr('x1', 0).attr('x2', 0).attr('y1', 0).attr('y2', layout.dimensions.height);
      inner.append('g').attr('class', 'axis').attr("transform", "translate(0," + (-layout.canvas.top) + ")");
      scale = d3.time.scale().domain(params.domain);
      axis = d3.svg.axis().scale(scale).ticks(d3.time.hour, 6).tickFormat(d3.time.format('%H'));
      focus = inner.append('g').attr('class', 'focus');
      focus.append('line').attr('class', 'poi').attr('display', 'none').attr('y1', 0).attr('y2', layout.dimensions.height);
      focus.append('text').attr('class', 'poi-y-val-shad').attr('display', 'none').attr('dx', '-1.3em').attr('dy', 2);
      focus.append('text').attr('class', 'poi-y-val').attr('display', 'none').attr('dx', '-1.3em');
      getTimezone = moment(scale.domain()[0]);
      svg.select('.infotext').text(spec.text + " " + (getTimezone.format('ZZ')));
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
          poifsm.currentx = scale(poi);
          focus.select('line.poi').attr('display', 'none');
          focus.select('.poi-y-val-shad').attr('display', 'none');
          focus.select('.poi-y-val').attr('display', 'none');
          return;
        }
        poifsm.currentx = scale(poi);
        focus.select('line.poi').attr('display', null).attr('x1', scale(poi)).attr('x2', scale(poi));
        if ((layout.canvas.width - scale(poi)) < 20) {
          xVal = layout.canvas.width - 20;
        } else if ((layout.canvas.left + scale(poi)) < 225) {
          xVal = 25;
        } else {
          xVal = scale(poi);
        }
        focus.select('.poi-y-val-shad').attr('display', null).attr('transform', "translate(" + xVal + "," + (layout.canvas.height - 6) + ")").text(poi.format('HH:mm'));
        return focus.select('.poi-y-val').attr('display', null).attr('transform', "translate(" + xVal + "," + (layout.canvas.height - 6) + ")").text(poi.format('HH:mm'));
      };
      return timeheadings.resize(params.dimensions);
    },
    resize: function(dimensions) {
      var layout;
      layout = calculate_layout(dimensions);
      svg.attr('width', layout.dimensions.width).attr('height', layout.dimensions.height);
      scale.range([0, layout.canvas.width]);
      inner.select('.axis').call(axis.tickSize(layout.canvas.height / 4, -layout.canvas.height));
      focus.select('.foreground').attr('height', layout.canvas.height).attr('width', layout.canvas.width);
      inner.select('.axis .domain').remove();
      return updatepoi();
    }
  };
};
