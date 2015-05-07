// Generated by CoffeeScript 1.9.1

/*

1. Loads data from a csv file.
2. Translates variable names
3. Filters data points through include and exclude.
4. Filters time through start and end
5. Passes data to sub components
6. Provides a hub for communication
   e.g. Point Of Interest (poi)

TODO: Load and query data using odoql
TODO: Implement more types (csv, tsv, NetCDF, ascii)
TODO: Turn time range specification into library
TODO: Timezones

- type: data
  source:
    type: csv
    url: example2.csv
    translate:
      time: DateTime
      wsp: WSpd10m
      gst: Gust10m
      wd: WindDir
      location: Location
    timeformat: DD-MM-YYYY HH:mm
    include:
      location: Location 1
  display:
     * timezone:
    start: 2014-12-09
    end: 2014-12-13
  spec:
  - type: chart
    text: Wind Speed
    spec:
    - type: line
      style: primary
      text: Wind Speed 10m
      field: wsp
      units: kts
 */

/*

Parse strings of the form:

<variable> (+|-) digits unit
or
ISO 8601 (http://en.wikipedia.org/wiki/ISO_8601)

e.g.

day+5h = start of the current day + five hours in current timezone
utcmonth+1M = start of the next month in utc

Always returns utc times
 */
var createhub, d3, moment;

d3 = require('d3');

moment = require('@metocean/timelord');

createhub = require('../util/hub');

module.exports = function(dom, options) {
  var components, dimensions, items, spec;
  components = options.components, spec = options.spec, dimensions = options.dimensions;
  items = [];
  d3.csv(spec.source.url, function(error, data) {
    var d, domain, hub, j, k, l, len, len1, len2, len3, m, parse_time, poi, ref, ref1, s, source, target, tz, value;
    if (spec.source.translate != null) {
      for (j = 0, len = data.length; j < len; j++) {
        d = data[j];
        ref = spec.source.translate;
        for (target in ref) {
          source = ref[target];
          if (d[source] == null) {
            continue;
          }
          value = d[source];
          delete d[source];
          d[target] = value;
        }
      }
    }
    if (spec.source.include != null) {
      data = data.filter(function(d) {
        var key, ref1, shouldinclude;
        shouldinclude = true;
        ref1 = spec.source.include;
        for (key in ref1) {
          value = ref1[key];
          if (d[key] == null) {
            continue;
          }
          shouldinclude = shouldinclude && d[key] === value;
        }
        return shouldinclude;
      });
    }
    if (spec.source.exclude != null) {
      data = data.filter(function(d) {
        var key, ref1, shouldexclude;
        shouldexclude = false;
        ref1 = spec.source.exclude;
        for (key in ref1) {
          value = ref1[key];
          if (d[key] == null) {
            continue;
          }
          shouldexclude = shouldexclude && d[key] === value;
        }
        return !shouldexclude;
      });
    }
    parse_time = function(time) {
      return moment.utc(d.time, moment.ISO_8601);
    };
    if (spec.source.timeformat != null) {
      parse_time = function(time) {
        return moment.utc(d.time, spec.source.timeformat);
      };
    }
    for (k = 0, len1 = data.length; k < len1; k++) {
      d = data[k];
      d.time = parse_time(d.time);
    }
    domain = d3.extent(data, function(d) {
      return d.time;
    });
    if (spec.display.start != null) {
      domain[0] = spec.display.start;
      if (typeof domain[0] === 'string') {
        domain[0] = moment.tl(domain[0]);
      }
    }
    if (spec.display.end != null) {
      domain[1] = spec.display.end;
      if (typeof domain[1] === 'string') {
        domain[1] = moment.tl(domain[1]);
      }
    }
    poi = null;
    if (moment.utc().isBetween(domain[0], domain[1])) {
      poi = moment.utc();
    }
    if (spec.display.timezone != null) {
      tz = spec.display.timezone;
      domain[0] = domain[0].tz(tz);
      domain[1] = domain[1].tz(tz);
      for (l = 0, len2 = data.length; l < len2; l++) {
        d = data[l];
        d.time = d.time.tz(tz);
      }
      if (poi != null) {
        poi = poi.tz(tz);
      }
    }
    hub = createhub();
    ref1 = spec.spec;
    for (m = 0, len3 = ref1.length; m < len3; m++) {
      s = ref1[m];
      if (components[s.type] == null) {
        return console.error(s.type + " component not found");
      }
      items.push(components[s.type](dom, {
        components: components,
        spec: s,
        dimensions: dimensions,
        hub: hub,
        data: data,
        domain: domain
      }));
    }
    return hub.emit('poi', poi);
  });
  return {
    resize: function(dimensions) {
      var i, j, len, results;
      results = [];
      for (j = 0, len = items.length; j < len; j++) {
        i = items[j];
        if (i.resize == null) {
          continue;
        }
        results.push(i.resize(dimensions));
      }
      return results;
    }
  };
};
