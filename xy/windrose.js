// Generated by CoffeeScript 1.9.3

/*

Plot a windrose with additional categories for each direction.

TODO: Work out how to position these xy visualisations.
TODO: Allow the different categories and values to be specified.
 */
var calculate_layout, d3;

d3 = require('d3');

calculate_layout = function(dimensions, spec) {
  var container, inner, innerMargin, legend, maxContainerWidth;
  inner = {};
  innerMargin = {
    top: 20,
    right: 60,
    bottom: 50,
    left: 80
  };
  legend = {
    top: 0,
    width: 150
  };
  legend.height = 30 + 30 * spec.bins.length;
  legend.bottom = legend.top + legend.height;
  maxContainerWidth = 700;
  container = {};
  container.width = Math.min(dimensions[0], maxContainerWidth);
  container.right = container.width;
  container.left = 0;
  legend.right = container.width;
  legend.left = legend.right - legend.width;
  inner.right = container.right - legend.width - innerMargin.right;
  inner.left = 0 + innerMargin.left;
  inner.width = inner.right - inner.left;
  inner.height = inner.width;
  inner.top = 0 + innerMargin.top;
  inner.bottom = inner.top + inner.height;
  container.height = Math.max(inner.bottom + innerMargin.bottom, legend.height);
  return {
    container: container,
    inner: inner,
    legend: legend
  };
};

module.exports = function(spec, components) {
  var result;
  return result = {
    render: function(dom, state, params) {
      var arc, axis, bin, circlecontainer, colorScale, d, dataMax, diameter, groupedData, i, inner, j, k, l, layout, legend, legendHeading, legendRectSize, legendSpacing, len, len1, m, n, nBins, nCategories, nTicks, obj, radialScale, ref, ref1, ref2, results, scale, segment, sobj, start, svg;
      layout = calculate_layout(params.dimensions, spec);
      svg = d3.select(dom).append('svg').attr('class', 'item windrose');
      nCategories = state.data.length;
      nBins = spec.bins.length;
      groupedData = [];
      ref = state.data;
      for (i = k = 0, len = ref.length; k < len; i = ++k) {
        d = ref[i];
        obj = {};
        obj.angle = i * (360 / nCategories);
        obj.key = obj.angle;
        obj.category = d[spec.category];
        obj.value = obj.category;
        obj.speeds = [];
        start = 0;
        ref1 = spec.bins;
        for (j = l = 0, len1 = ref1.length; l < len1; j = ++l) {
          bin = ref1[j];
          sobj = {};
          sobj.index = j;
          sobj.start = start;
          start += +d[bin];
          sobj.end = start * 1.00001;
          obj.speeds.push(sobj);
        }
        obj.count = start;
        groupedData.push(obj);
      }
      dataMax = d3.max((function() {
        var len2, m, results;
        results = [];
        for (m = 0, len2 = groupedData.length; m < len2; m++) {
          d = groupedData[m];
          results.push(d.count);
        }
        return results;
      })());
      svg.attr('width', layout.container.width).attr('height', layout.container.height);
      inner = svg.append('g').attr('class', 'inner').attr('transform', "translate(" + (layout.inner.left + layout.inner.width / 2) + "," + (layout.inner.top + layout.inner.height / 2) + ")");
      colorScale = d3.scale.quantize().range(['#E4EAF1', '#D1D8E3', '#BEC7D5', '#ABB6C7', '#98A5B9', '#8594AB', '#73829E', '#607190', '#4D6082', '#3A4E74', '#273D66', '#142C58', '#122851', '#102448']).domain([0, nBins]);
      scale = d3.scale.linear().domain([
        0, 1.1 * d3.max(groupedData, function(d) {
          return d.count;
        })
      ]).range([0, layout.inner.width / 2]);
      diameter = (scale(scale.domain()[1])) - 5;
      circlecontainer = inner.append('g').attr('class', 'circlecontainer');
      axis = inner.selectAll('.axis').data(groupedData).enter().append('g').attr('class', 'axis').attr('transform', function(d) {
        return "rotate(" + d.key + ")";
      });
      arc = function(o) {
        return d3.svg.arc().startAngle(function(d) {
          return (-o.width / 2) * Math.PI / 180;
        }).endAngle(function(d) {
          return (+o.width / 2) * Math.PI / 180;
        }).innerRadius(o.from).outerRadius(o.to);
      };
      axis.append('line').attr('class', 'spoke').attr('x1', scale(0)).attr('y1', scale(0)).attr('x2', scale(0)).attr('y2', layout.inner.width / 2);
      axis.append('g').attr('transform', function(d) {
        return "translate(" + (scale(0)) + "," + (layout.inner.height * (-0.53)) + ")";
      }).append('text').attr('transform', function(d) {
        return "rotate(" + (-d.key) + ")";
      }).attr('style', 'text-anchor: middle').attr('dy', '0.25em').text(function(d) {
        return d.value;
      });
      segment = inner.selectAll('.segment').data(groupedData).enter().append('g').attr('class', 'segment').attr('transform', function(d) {
        return "rotate(" + d.key + ")";
      }).selectAll('path').data(function(d) {
        return d.speeds;
      }).enter().append('path').attr('d', arc({
        width: 360 / nCategories * 0.8,
        from: function(d) {
          return scale(d.start);
        },
        to: function(d) {
          return scale(d.end);
        }
      })).style('fill', function(d) {
        return colorScale(d.index);
      });
      nTicks = 4;
      radialScale = d3.scale.linear().domain([0, nTicks]).range([0, dataMax]);
      for (i = m = 1, ref2 = nTicks + 1; 1 <= ref2 ? m < ref2 : m > ref2; i = 1 <= ref2 ? ++m : --m) {
        circlecontainer.append('text').text(+radialScale(i).toPrecision(5)).attr('x', 0).attr('y', -(i * diameter / nTicks));
        circlecontainer.append('circle').attr('cx', 0).attr('cy', 0).attr('r', i * diameter / nTicks);
      }
      legendRectSize = 20;
      legendSpacing = 10;
      legend = svg.selectAll('.legend').data((function() {
        results = [];
        for (var n = 0; 0 <= nBins ? n < nBins : n > nBins; 0 <= nBins ? n++ : n--){ results.push(n); }
        return results;
      }).apply(this)).enter().append('g').attr('class', 'legend').attr('transform', function(d, i) {
        return "translate(" + layout.legend.left + "," + ((layout.legend.top + legendRectSize + legendSpacing) * i + 30) + ")";
      });
      legend.append('rect').attr('width', legendRectSize).attr('height', legendRectSize).style('fill', colorScale).style('stroke', colorScale);
      legend.append('text').attr('x', legendRectSize + legendSpacing).attr('y', legendRectSize - legendSpacing + 5).text(function(d) {
        return spec.bins[d];
      });
      return legendHeading = svg.append('text').attr('x', layout.legend.left).attr('y', layout.legend.top).attr('dy', '1em').text(spec.binLabel);
    }
  };
};
