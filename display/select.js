// Generated by CoffeeScript 1.9.2
var extend, listcomponent;

listcomponent = require('./list');

extend = require('extend');

module.exports = function(spec, components) {
  var list, select;
  list = listcomponent(spec.spec, components);
  return select = {
    render: function(dom, state, params) {
      var data;
      data = state[spec.dataset];
      state = extend({}, state, {
        data: data
      });
      return list.render(dom, state, params);
    },
    resize: function(dimensions) {
      return list.resize(dimensions);
    },
    query: function(params) {
      return list.query(params);
    }
  };
};
