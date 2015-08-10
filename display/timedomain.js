var createhub, d3, extend, listcomponent, moment;

d3 = require('d3');

moment = require('timespanner');

createhub = require('../util/hub');

listcomponent = require('./list');

extend = require('extend');

module.exports = function(spec, components) {
  var list, timedomain;
  list = listcomponent(spec.spec, components);
  return timedomain = {
    render: function(dom, state, params) {
      var d, data, domain, hub, i, j, len, len1, newparams, poi, tz;
      data = state.data;
      for (i = 0, len = data.length; i < len; i++) {
        d = data[i];
        d.time = moment.utc(d.time, moment.ISO_8601);
      }
      domain = d3.extent(data, function(d) {
        return d.time;
      });
      if (spec.start != null) {
        domain[0] = spec.start;
        if (typeof domain[0] === 'string') {
          domain[0] = moment.spanner(domain[0]);
        }
      }
      if (spec.end != null) {
        domain[1] = spec.end;
        if (typeof domain[1] === 'string') {
          domain[1] = moment.spanner(domain[1]);
        }
      }
      poi = null;
      if (moment.utc().isBetween(domain[0], domain[1])) {
        poi = moment.utc();
      }
      if (spec.timezone != null) {
        tz = spec.timezone;
        domain[0] = domain[0].tz(tz);
        domain[1] = domain[1].tz(tz);
        for (j = 0, len1 = data.length; j < len1; j++) {
          d = data[j];
          d.time = d.time.tz(tz);
        }
        if (poi != null) {
          poi = poi.tz(tz);
        }
      }
      hub = createhub();
      newparams = extend({}, params, {
        domain: domain,
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
