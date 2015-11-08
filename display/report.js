
/*

Represents an entire report.
Includes title, author and other metadata.

TODO: metadata
 */

(function() {
  var mount;

  mount = require('./mount');

  module.exports = function(spec, components) {
    return mount(spec, components);
  };

}).call(this);
