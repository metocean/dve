// Generated by CoffeeScript 1.9.3

/*

Combine multiple arrays
 */
module.exports = function() {
  var arr, arrayLengths, i, j, minLength, ref, results;
  arrayLengths = (function() {
    var j, len, results;
    results = [];
    for (j = 0, len = arguments.length; j < len; j++) {
      arr = arguments[j];
      results.push(arr.length);
    }
    return results;
  }).apply(this, arguments);
  minLength = Math.min.apply(Math, arrayLengths);
  results = [];
  for (i = j = 0, ref = minLength; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
    results.push((function() {
      var k, len, results1;
      results1 = [];
      for (k = 0, len = arguments.length; k < len; k++) {
        arr = arguments[k];
        results1.push(arr[i]);
      }
      return results1;
    }).apply(this, arguments));
  }
  return results;
};