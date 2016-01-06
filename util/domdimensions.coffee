module.exports = (dom) ->
  if window
    styles = window.getComputedStyle dom
  else
    styles =
      paddingLeft: 0
      paddingRight: 0
      paddingTop: 0
      paddingBottom: 0
  paddingLeft = parseFloat styles.paddingLeft
  paddingRight = parseFloat styles.paddingRight
  paddingTop = parseFloat styles.paddingTop
  paddingBottom = parseFloat styles.paddingBottom
  [
    dom.offsetWidth - paddingLeft - paddingRight
    dom.offsetHeight - paddingTop - paddingBottom
  ]
