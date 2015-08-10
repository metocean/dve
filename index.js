
/*

Export all the things, for people not using browserify.
Also for people who want all the inbuilt components for
passing into report, mount and chart.
 */
module.exports = {
  mount: require('./display/mount'),
  title: require('./display/title'),
  space: require('./display/space'),
  tabs: require('./display/tabs'),
  data: require('./display/data'),
  select: require('./display/select'),
  report: require('./display/report'),
  timedomain: require('./display/timedomain'),
  timeheadings: require('./time/timeheadings'),
  dayheadings: require('./time/dayheadings'),
  chart: require('./time/chart'),
  chart2: require('./time/chart2'),
  tablebytime: require('./time/tablebytime'),
  line: require('./time/line'),
  scatter: require('./time/scatter'),
  direction: require('./time/direction'),
  histogram: require('./xy/histogram'),
  table: require('./xy/table'),
  windrose: require('./xy/windrose'),
  windrosebar: require('./xy/windrosebar')
};
