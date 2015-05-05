###

Export all the things, for people not using browserify.
Also for people who want all the inbuilt components for
passing into report, mount and chart.

###

module.exports =
  # handles browser resize
  mount: require './display/mount'
  # formatting
  title: require './display/title'
  space: require './display/space'
  # data set
  data: require './display/data'
  report: require './display/report'

  # navigation
  timeheadings: require './time/timeheadings'
  dayheadings: require './time/dayheadings'
  # time x single scale
  chart: require './time/chart'
  tablebytime: require './time/tablebytime'
  # chart series
  line: require './time/line'
  scatter: require './time/scatter'
  # single series
  direction: require './time/direction'
  #TODO traffic light

  # non-timeline components
  histogram: require './xy/histogram'
  table: require './xy/table'
  windrose: require './xy/windrose'