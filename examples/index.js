// Generated by CoffeeScript 1.9.2

/*

Using DVE with browserify is recommended but not required.
 */
var components, d, d3, example2, i, jsyaml, len, moment;

d3 = require('d3');

jsyaml = require('js-yaml');

components = require('dve');

example2 = require('./example2');

moment = require('timespanner');

for (i = 0, len = example2.length; i < len; i++) {
  d = example2[i];
  d.time = moment(d.time, 'DD-MM-YYYY HH:mm');
}

d3.text('/test.yml', function(error, spec) {
  var dom, scene;
  dom = document.querySelector('#root');
  spec = jsyaml.load(spec);
  scene = components[spec.type](spec, components);
  return scene.render(dom, {
    example2: example2
  }, {});
});
