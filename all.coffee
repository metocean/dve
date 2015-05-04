module.exports =
  # formatting
  title: require './title'
  space: require './space'

  # data set
  data: require './data'

  # navigation
  timeheadings: require './timeheadings'
  dayheadings: require './dayheadings'

  # time x single scale
  chart: require './chart'

  # chart series
  line: require './line'
  scatter: require './scatter'

  # single series
  direction: require './direction'
  #TODO traffic light

  # non-timeline components
  histogram: require './histogram'
  table: require './table'
  tablebytime: require './tablebytime'
  windrose: require './windrose'
