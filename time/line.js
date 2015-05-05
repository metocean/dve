// Generated by CoffeeScript 1.9.1
var d3, moment, neighbours;

d3 = require('d3');

moment = require('moment');

neighbours = require('../util/neighbours');

module.exports = function(dom, options) {
  var axis, components, data, dimensions, domain, end, filteredData, focus, getNeighbours, hub, label, labelShad, line, poi, provideMax, resize, scale, spec, start, svg, updatepoi;
  components = options.components, spec = options.spec, dimensions = options.dimensions, data = options.data, domain = options.domain, hub = options.hub, scale = options.scale, axis = options.axis;
  svg = dom.append('g');
  data = data.map(function(d) {
    var result;
    result = {
      time: d.time
    };
    result[spec.field] = +d[spec.field];
    if (result[spec.field] === 0) {
      result[spec.field] = null;
    }
    return result;
  });
  line = svg.append('path').attr('class', spec.style + " " + spec.type).attr('d', '');
  labelShad = svg.append('text').attr('class', 'label-shad').attr('text-anchor', 'start').attr('dy', 12).text(spec.text + " (" + spec.units + ")");
  label = svg.append('text').attr('class', 'label').attr('text-anchor', 'start').attr('dy', 12).text(spec.text + " (" + spec.units + ")");
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
  start = getNeighbours(domain[0])[0];
  end = getNeighbours(domain[1]);
  end = end[end.length - 1];
  filteredData = data.filter(function(d) {
    return +d.time >= +start.time && +d.time <= +end.time;
  });
  poi = null;
  hub.on('poi', function(p) {
    poi = p;
    return updatepoi();
  });
  provideMax = function() {
    return d3.max(filteredData, function(d) {
      return d[spec.field];
    });
  };
  updatepoi = function() {
    var Neighbours, d, d0, d1, dxAttr, halfway, poiNeighbours, yValWidth;
    if (poi == null) {
      focus.select('.poi-circle').attr('display', 'none');
      focus.select('.poi-y-val-shad').attr('display', 'none');
      focus.select('.poi-y-val').attr('display', 'none');
      return;
    }
    yValWidth = +focus.select('.poi-y-val').node().getComputedTextLength();
    if ((dimensions[0] - (scale.x(poi)) - yValWidth) < yValWidth) {
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
    } else if (+poiNeighbours[0].time < +domain[0]) {
      d = poiNeighbours[1];
    } else if (+poiNeighbours[1].time > +domain[1]) {
      d = poiNeighbours[0];
    } else {
      d0 = poiNeighbours[0];
      d1 = poiNeighbours[1];
      halfway = d0.time + (d1.time - d0.time) / 2;
      d = poi.isBefore(halfway) ? d0 : d1;
    }
    focus.select('.poi-circle').attr('display', null).attr('transform', "translate(" + (scale.x(d.time)) + ", " + (scale.y(d[spec.field])) + ")");
    focus.select('.poi-y-val-shad').attr('display', null).attr('transform', "translate(" + (scale.x(d.time)) + ", " + (scale.y(d[spec.field])) + ")").attr('dx', dxAttr).text((d[spec.field].toPrecision(3)) + " (" + spec.units + ")");
    return focus.select('.poi-y-val').attr('display', null).attr('transform', "translate(" + (scale.x(d.time)) + ", " + (scale.y(d[spec.field])) + ")").attr('dx', dxAttr).text((d[spec.field].toPrecision(3)) + " (" + spec.units + ")");
  };
  resize = function(dimensions) {
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
  };
  return {
    resize: resize,
    provideMax: provideMax
  };
};