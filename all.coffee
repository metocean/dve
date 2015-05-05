module.exports =
  # formatting
  title: require './title'
  space: require './space'

  # data set
  data: require './data'

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
