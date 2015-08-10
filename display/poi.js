// Generated by CoffeeScript 1.9.2
var createhub, d3, extend, listcomponent, moment;

d3 = require('d3');

moment = require('timespanner');

createhub = require('../util/hub');

listcomponent = require('./list');

extend = require('extend');

module.exports = function(spec, components) {
  var list;
  list = listcomponent(spec.spec, components);
  return {
    render: function(dom, state, params) {
      var hub, newparams, poi, tz;
      poi = null;
      if (moment.utc().isBetween(params.domain[0], params.domain[1])) {
        tz = params.domain[0].tz();
        poi = moment.utc().tz(tz);
      }
      hub = createhub();
      newparams = extend({}, params, {
        hub: hub
      });
      list.render(dom, state, newparams);
      return hub.emit('poi', poi);
    },
    resize: function(dimensions) {
      return list.resize(dimensions);
    },
    query: function(params) {
      return spec.queries;
    }
  };
};