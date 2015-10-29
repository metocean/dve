// Generated by CoffeeScript 1.9.3

/*

Show a cell heatmap of cells of data on a timeline.
Great for visually seeing highlights.

TODO: Add poi.
 */
var calculate_layout, colorbrewer, d3;

d3 = require('d3');

colorbrewer = require('colorbrewer');

calculate_layout = function(dimensions) {
  var canvas, info, title;
  dimensions = {
    width: dimensions[0],
    height: 30
  };
  info = {
    top: 0,
    right: 0,
    bottom: 0,
    left: 0
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
    dimensions: dimensions,
    info: info,
    title: title,
    canvas: canvas
  };
};

module.exports = function(spec, components) {
  var cells, cellsEnter, colorScale, container, create_cells, data, field, filteredData, results, scale, svg, textcolorScale;
  svg = null;
  data = null;
  filteredData = null;
  cells = null;
  cellsEnter = null;
  container = null;
  scale = null;
  field = null;
  colorScale = null;
  textcolorScale = null;
  create_cells = function() {
    var bisector;
    bisector = d3.bisector(function(d) {
      return d.time;
    }).left;
    data = scale.ticks(d3.time.hour, 3).map(function(d) {
      var index;
      index = bisector(filteredData, d);
      return filteredData[index];
    }).filter(function(d) {
      return d != null;
    });
    cells = container.selectAll('g.cell').data(data);
    cellsEnter = cells.enter().append('g').attr('class', 'cell').attr('class', function(d) {
      var hour;
      hour = d.time.local().get('hour');
      if (hour % 12 === 0) {
        return 'cell priority1';
      } else if (hour % 6 === 0) {
        return 'cell priority2';
      } else if (hour % 3 === 0) {
        return 'cell priority3';
      }
    });
    cellsEnter.append('rect').attr('height', field.height - 1).style('fill', function(d) {
      return colorScale(d[spec.field]);
    });
    return cellsEnter.append('text').attr('y', field.height / 2).attr('dy', '0.35em').text(function(d) {
      return d[spec.field];
    }).style('fill', function(d) {
      return textcolorScale(d[spec.field]);
    });
  };
  return results = {
    render: function(dom, state, params) {
      var dataDom, inner, layout;
      layout = calculate_layout(params.dimensions);
      svg = d3.select(dom).append('svg').attr('class', 'item tablebytime');
      data = state.data.map(function(d) {
        var result;
        result = {
          time: d.time
        };
        result[spec.field] = +d[spec.field];
        return result;
      });
      filteredData = data.filter(function(d) {
        return +d.time >= +params.domain[0] && +d.time <= +params.domain[1];
      });
      scale = d3.time.scale().domain(params.domain).range([0, layout.canvas.width]);
      field = {
        height: 30,
        width: 0
      };
      dataDom = [
        d3.min(filteredData, function(d) {
          return d[spec.field];
        }), d3.max(filteredData, function(d) {
          return d[spec.field];
        })
      ];
      colorScale = d3.scale.quantize().range(colorbrewer.Blues[9]).domain(dataDom);
      textcolorScale = d3.scale.quantize().range(["#000000", "#000000", "#ffffff", "#ffffff"]).domain(dataDom);
      inner = svg.append('g').attr('class', 'inner').attr('transform', "translate(" + layout.canvas.left + "," + layout.canvas.top + ")");
      inner.append('line').attr('class', 'divider').attr('x1', 0).attr('x2', 0).attr('y1', 0).attr('y2', layout.dimensions.height);
      container = inner.append('g').attr('class', 'container');
      cells = null;
      create_cells();
      return results.resize(params.dimensions);
    },
    resize: function(dimensions) {
      var bisector, layout, minLabelWidth, p1, p1widths, p2, p2widths, p3, p3widths;
      layout = calculate_layout(dimensions);
      svg.attr('width', layout.dimensions.width).attr('height', layout.dimensions.height);
      scale.range([0, layout.canvas.width]);
      bisector = d3.bisector(function(d) {
        return d.time;
      }).left;
      data = scale.ticks(d3.time.hour, 3).map(function(d) {
        var index;
        index = bisector(filteredData, d);
        return filteredData[index];
      }).filter(function(d) {
        return d != null;
      });
      p1 = container.selectAll('.priority1');
      p2 = container.selectAll('.priority2');
      p3 = container.selectAll('.priority3');
      minLabelWidth = 31;
      p1widths = p1[0].length * minLabelWidth;
      p2widths = p2[0].length * minLabelWidth;
      p3widths = p3[0].length * minLabelWidth;
      switch (false) {
        case !(p1widths + p2widths + p3widths <= layout.canvas.width):
          p2.attr('display', 'inline');
          p3.attr('display', 'inline');
          field.width = layout.canvas.width / (p1[0].length + p2[0].length + p3[0].length);
          break;
        case !(p1widths + p2widths <= layout.canvas.width):
          p2.attr('display', 'inline');
          p3.attr('display', 'none');
          field.width = layout.canvas.width / (p1[0].length + p2[0].length);
          break;
        case !(p1widths <= layout.canvas.width):
          p3.attr('display', 'none');
          p2.attr('display', 'none');
          field.width = layout.canvas.width / p1[0].length;
      }
      cells = container.selectAll('g.cell').data(data);
      cells.attr('transform', function(d) {
        return "translate(" + (scale(d.time) - field.width / 2) + ", 0)";
      });
      container.selectAll('.cell rect').attr('width', field.width - 1);
      return container.selectAll('.cell text').attr('x', field.width / 2);
    }
  };
};
