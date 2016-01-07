(function() {
  module.exports = function(dom) {
    var paddingBottom, paddingLeft, paddingRight, paddingTop, styles;
    if (typeof window !== "undefined" && window !== null) {
      styles = window.getComputedStyle(dom);
    } else {
      styles = {
        paddingLeft: 0,
        paddingRight: 0,
        paddingTop: 0,
        paddingBottom: 0
      };
    }
    paddingLeft = parseFloat(styles.paddingLeft);
    paddingRight = parseFloat(styles.paddingRight);
    paddingTop = parseFloat(styles.paddingTop);
    paddingBottom = parseFloat(styles.paddingBottom);
    return [dom.offsetWidth - paddingLeft - paddingRight, dom.offsetHeight - paddingTop - paddingBottom];
  };

}).call(this);
