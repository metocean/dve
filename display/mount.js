// Generated by CoffeeScript 1.9.1

/*

Mount a component or group of components into the dom.
Keep them resized based on window resize events.

TODO: Optional offset (e.g. remove hardcoded 42)
 */
var d3, debounce, getwindowdimensions, windowdimensions;

d3 = require('d3');

windowdimensions = require('../util/windowdimensions');

debounce = require('../util/debounce');

getwindowdimensions = function() {
  var dimensions;
  dimensions = windowdimensions();
  dimensions[0] -= 42;
  return dimensions;
};

module.exports = function(dom, options) {
  var components, dimensions, items, j, len, s, spec;
  components = options.components, spec = options.spec;
  dimensions = getwindowdimensions();
  if (!(spec instanceof Array)) {
    spec = [spec];
  }
  items = [];
  for (j = 0, len = spec.length; j < len; j++) {
    s = spec[j];
    if (components[s.type] == null) {
      return console.error(s.type + " component not found");
    }
    items.push(components[s.type](dom, {
      components: components,
      spec: s,
      dimensions: dimensions
    }));
  }
  return d3.select(window).on('resize', debounce(125, function() {
    var i, k, len1, results;
    dimensions = getwindowdimensions();
    results = [];
    for (k = 0, len1 = items.length; k < len1; k++) {
      i = items[k];
      if (i.resize == null) {
        continue;
      }
      results.push(i.resize(dimensions));
    }
    return results;
  }));
};
