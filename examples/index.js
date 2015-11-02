
/*

Using DVE with browserify is recommended but not required.
 */

(function() {
  var components, curve, d3, fixdata, jsyaml, moment;

  curve = function(x) {
    if (x < 0.25) {
      return 8 * x * x;
    }
    if (x < 0.75) {
      return -8 * (x - 0.5) * (x - 0.5) + 1;
    }
    return 8 * (x - 1) * (x - 1);
  };

  d3 = require('d3');

  jsyaml = require('js-yaml');

  components = require('dve');

  moment = require('timespanner');

  fixdata = function(data) {
    var d, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = data.length; _i < _len; _i++) {
      d = data[_i];
      d.time = moment(d.time, 'DD-MM-YYYY HH:mm');
      d.wsp = parseFloat(d.wsp);
      d.wsp2 = parseFloat(d.wsp);
      d.wd = parseFloat(d.wd);
      _results.push(d.gust = parseFloat(d.gust));
    }
    return _results;
  };

  d3.csv('/example3.csv', function(err, example3) {
    fixdata(example3);
    return d3.text('/test.yml', function(error, spec) {
      var adjustrange, clearrange, copiedrange, dom, scene, targetrange;
      dom = document.querySelector('#root');
      spec = jsyaml.load(spec);
      scene = components[spec.type](spec, components);
      console.log(example3);
      scene.init({
        data: example3
      }, {});
      scene.render(dom, {
        data: example3
      }, {});
      copiedrange = null;
      scene.hub.on('range', function(range) {
        copiedrange = range;
        if (range == null) {
          document.querySelector('input.value').value = '';
          return document.querySelector('.editor').style.display = 'none';
        } else {
          document.querySelector('input.value').value = range.ma.toFixed(1);
          return document.querySelector('.editor').style.display = 'block';
        }
      });
      adjustrange = function(n) {
        var d, diff, p1, p2, x, _i, _j, _len, _len1, _results;
        if (copiedrange == null) {
          return;
        }
        p1 = copiedrange.p1.format('x');
        p2 = copiedrange.p2.format('x');
        diff = p2 - p1;
        for (_i = 0, _len = example3.length; _i < _len; _i++) {
          d = example3[_i];
          x = d.time.format('x') - p1;
          if (diff === 0) {
            if (x !== 0) {
              continue;
            }
            d.wsp2 += n;
          }
          x /= diff;
          if (x >= 0 && x <= 1) {
            d.wsp2 += n * curve(x);
          }
        }
        _results = [];
        for (_j = 0, _len1 = example3.length; _j < _len1; _j++) {
          d = example3[_j];
          _results.push(d.wsp2 = Math.max(0, d.wsp2));
        }
        return _results;
      };
      targetrange = function(n) {
        var d, diff, p1, p2, x, _i, _j, _len, _len1, _results;
        if (copiedrange == null) {
          return;
        }
        p1 = copiedrange.p1.format('x');
        p2 = copiedrange.p2.format('x');
        diff = p2 - p1;
        for (_i = 0, _len = example3.length; _i < _len; _i++) {
          d = example3[_i];
          x = d.time.format('x') - p1;
          if (diff === 0) {
            if (x !== 0) {
              continue;
            }
            d.wsp2 = n;
          }
          x /= diff;
          if (x >= 0 && x <= 1) {
            d.wsp2 += (n - d.wsp2) * curve(x);
          }
        }
        _results = [];
        for (_j = 0, _len1 = example3.length; _j < _len1; _j++) {
          d = example3[_j];
          _results.push(d.wsp2 = Math.max(0, d.wsp2));
        }
        return _results;
      };
      clearrange = function() {
        var d, diff, p1, p2, x, _i, _j, _len, _len1, _results;
        if (copiedrange == null) {
          return;
        }
        p1 = copiedrange.p1.format('x');
        p2 = copiedrange.p2.format('x');
        diff = p2 - p1;
        for (_i = 0, _len = example3.length; _i < _len; _i++) {
          d = example3[_i];
          x = d.time.format('x') - p1;
          if (diff === 0) {
            if (x !== 0) {
              continue;
            }
            d.wsp2 = d.wsp;
          }
          x /= diff;
          if (x >= 0 && x <= 1) {
            d.wsp2 += (d.wsp - d.wsp2) * curve(x);
          }
        }
        _results = [];
        for (_j = 0, _len1 = example3.length; _j < _len1; _j++) {
          d = example3[_j];
          _results.push(d.wsp2 = Math.max(0, d.wsp2));
        }
        return _results;
      };
      document.onkeydown = function(e) {
        var _ref;
        if ((document.activeElement != null) && ((_ref = document.activeElement.tagName) === 'TEXTAREA' || _ref === 'INPUT')) {
          return;
        }
        switch (e.keyCode) {
          case 38:
            adjustrange(1);
            return window.dispatchEvent(new Event('resize'));
          case 40:
            adjustrange(-1);
            return window.dispatchEvent(new Event('resize'));
          case 37:
            return scene.hub.emit('range nudge back');
          case 39:
            return scene.hub.emit('range nudge forward');
        }
      };
      document.querySelector('button.up').onclick = function(e) {
        adjustrange(1);
        return window.dispatchEvent(new Event('resize'));
      };
      document.querySelector('button.down').onclick = function(e) {
        adjustrange(-1);
        return window.dispatchEvent(new Event('resize'));
      };
      document.querySelector('button.back').onclick = function(e) {
        return scene.hub.emit('range nudge back');
      };
      document.querySelector('button.forward').onclick = function(e) {
        return scene.hub.emit('range nudge forward');
      };
      document.querySelector('button.reset').onclick = function(e) {
        var d, _i, _len;
        for (_i = 0, _len = example3.length; _i < _len; _i++) {
          d = example3[_i];
          d.wsp2 = d.wsp;
        }
        return scene.hub.emit('state updated', {
          data: example3
        });
      };
      document.querySelector('form').onsubmit = function(e) {
        e.preventDefault();
        targetrange(parseFloat(document.querySelector('input.value').value));
        return window.dispatchEvent(new Event('resize'));
      };
      return document.querySelector('button.clear').onclick = function(e) {
        clearrange();
        return window.dispatchEvent(new Event('resize'));
      };
    });
  });

}).call(this);
