
/*

Find the closest points in a dataset.
 */

(function() {
  module.exports = function(data, f) {
    return function(value) {
      var d, fd, last, _i, _len;
      value = +value;
      if (data.length === 0 || +f(data[0]) > value || +f(data[data.length - 1]) < value) {
        return [];
      }
      last = null;
      for (_i = 0, _len = data.length; _i < _len; _i++) {
        d = data[_i];
        fd = +f(d);
        if (fd === value) {
          return [d];
        }
        if (value < fd) {
          return [last, d];
        }
        last = d;
      }
    };
  };

}).call(this);
