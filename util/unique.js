// Generated by CoffeeScript 1.9.3

/*

Returns a copy of array with dulicates removed
 */
module.exports = function(array) {
  var i, item, key, len, obj, value;
  obj = {};
  for (i = 0, len = array.length; i < len; i++) {
    item = array[i];
    obj[item] = item;
  }
  return (function() {
    var results;
    results = [];
    for (key in obj) {
      value = obj[key];
      results.push(value);
    }
    return results;
  })();
};
