// Generated by CoffeeScript 1.9.3

/*

Mount a component or group of components into the dom.
Keep them resized based on window resize events.
 */
var d3, debounce, domdimensions, extend, listcomponent;

d3 = require('d3');

domdimensions = require('../util/domdimensions');

debounce = require('../util/debounce');

extend = require('extend');

listcomponent = require('./list');

module.exports = function(spec, components) {
  var list, mount;
  list = listcomponent(spec, components);
  return mount = {
    render: function(dom, state, params) {
      var namespacedListener;
      params = extend({}, params, {
        dimensions: domdimensions(dom)
      });
      list.render(dom, state, params);
      namespacedListener = 'resize' + '.' + params.id;
      d3.select(window).on(namespacedListener, debounce(125, function() {
        params.dimensions = domdimensions(dom);
        dom.innerHTML = '';
        return list.render(dom, state, params);
      }));
      return setTimeout(function() {
        var dimensions;
        dimensions = domdimensions(dom);
        return mount.resize(dimensions);
      }, 1000);
    },
    resize: function(dimensions) {
      return list.resize(dimensions);
    },
    query: function(params) {
      return list.query(params);
    }
  };
};
