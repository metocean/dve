// Generated by CoffeeScript 1.9.2

/*

Using DVE with browserify is recommended but not required.
 */
var components, curve, d3, fixdata, i, jsyaml, len, moment, v, values;

curve = function(x) {
  if (x < 0.25) {
    return 8 * x * x;
  }
  if (x < 0.75) {
    return -8 * (x - 0.5) * (x - 0.5) + 1;
  }
  return 8 * (x - 1) * (x - 1);
};

values = ["0.00", "0.05", "0.10", "0.15", "0.20", "0.25", "0.30", "0.35", "0.40", "0.45", "0.50", "0.55", "0.60", "0.65", "0.70", "0.75", "0.80", "0.85", "0.90", "0.95", "1.00"];

for (i = 0, len = values.length; i < len; i++) {
  v = values[i];
  console.log(v + " - " + (curve(parseFloat(v))));
}

d3 = require('d3');

jsyaml = require('js-yaml');

components = require('dve');

moment = require('timespanner');

fixdata = function(data) {
  var d, j, len1, results;
  results = [];
  for (j = 0, len1 = data.length; j < len1; j++) {
    d = data[j];
    d.time = moment(d.time, 'DD-MM-YYYY HH:mm');
    d.wsp = parseFloat(d.wsp);
    d.wsp2 = parseFloat(d.wsp2);
    d.wd = parseFloat(d.wd);
    results.push(d.gust = parseFloat(d.gust));
  }
  return results;
};

d3.csv('/example3.csv', function(err, example3) {
  fixdata(example3);
  return d3.text('/test.yml', function(error, spec) {
    var adjustedrange, dom, scene;
    dom = document.querySelector('#root');
    spec = jsyaml.load(spec);
    scene = components[spec.type](spec, components);
    scene.render(dom, {
      data: example3
    }, {});
    adjustedrange = null;
    scene.hub.on('range', function(range) {
      if (range == null) {
        return;
      }
      return adjustedrange = range.p1 <= range.p2 ? {
        p1: range.p1,
        p2: range.p2
      } : {
        p1: range.p2,
        p2: range.p1
      };
    });
    document.querySelector('button.up').onclick = function(e) {
      var d, diff, j, len1, p1, p2, x;
      p1 = adjustedrange.p1.format('x');
      p2 = adjustedrange.p2.format('x');
      diff = p2 - p1;
      for (j = 0, len1 = example3.length; j < len1; j++) {
        d = example3[j];
        x = d.time.format('x') - p1;
        if (diff === 0) {
          if (x === 0) {
            d.wsp2 += 1;
          } else {
            continue;
          }
        }
        x /= diff;
        if (x >= 0 && x <= 1) {
          d.wsp2 += curve(x);
        }
      }
      return scene.hub.emit('state updated', {
        data: example3
      });
    };
    return document.querySelector('button.down').onclick = function(e) {
      var d, diff, j, len1, p1, p2, x;
      p1 = adjustedrange.p1.format('x');
      p2 = adjustedrange.p2.format('x');
      diff = p2 - p1;
      for (j = 0, len1 = example3.length; j < len1; j++) {
        d = example3[j];
        x = d.time.format('x') - p1;
        if (diff === 0) {
          if (x === 0) {
            d.wsp2 -= 1;
          } else {
            continue;
          }
        }
        x /= diff;
        if (x >= 0 && x <= 1) {
          d.wsp2 -= curve(x);
        }
      }
      return scene.hub.emit('state updated', {
        data: example3
      });
    };
  });
});
