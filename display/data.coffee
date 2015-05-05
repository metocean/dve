###

1. Loads data from a csv file.
2. Translates variable names
3. Filters data points through include and exclude.
4. Filters time through start and end
5. Passes data to sub components
6. Provides a hub for communication
   e.g. Point Of Interest (poi)

TODO: Load and query data using odoql
TODO: Implement more types (csv, tsv, NetCDF, ascii)
TODO: Turn time range specification into library
TODO: Timezones

- type: data
  source:
    type: csv
    url: example2.csv
    translate:
      time: DateTime
      wsp: WSpd10m
      gst: Gust10m
      wd: WindDir
      location: Location
    timeformat: DD-MM-YYYY HH:mm
    include:
      location: Location 1
  display:
    # timezone:
    start: 2014-12-09
    end: 2014-12-13
  spec:
  - type: chart
    text: Wind Speed
    spec:
    - type: line
      style: primary
      text: Wind Speed 10m
      field: wsp
      units: kts

###

d3 = require 'd3'
moment = require 'moment'
createhub = require '../util/hub'

module.exports = (dom, options) ->
  { components, spec, dimensions } = options

  items = []

  d3.csv spec.source.url, (error, data)->
    if spec.source.translate?
      for d in data
        for target, source of spec.source.translate
          continue if !d[source]?
          value = d[source]
          delete d[source]
          d[target] = value
    if spec.source.include?
      data = data.filter (d)->
        shouldinclude = yes
        for key, value of spec.source.include
          continue if !d[key]?
          shouldinclude = shouldinclude and d[key] is value
        shouldinclude
    if spec.source.exclude?
      data = data.filter (d)->
        shouldexclude = no
        for key, value of spec.source.exclude
          continue if !d[key]?
          shouldexclude = shouldexclude and d[key] is value
        not shouldexclude

    parse_time = (time) -> moment.utc d.time, moment.ISO_8601
    if spec.source.timeformat?
      parse_time = (time)-> moment.utc d.time, spec.source.timeformat
    for d in data
      d.time = parse_time d.time

    domain = d3.extent data, (d) -> d.time

    timeRegex = /(\-|\+)[0-9]+([dwMyhms])/

    start = spec.display.start
    end = spec.display.end

    parse_start = (time) -> moment.utc time, moment.ISO_8601
    parse_end = (time) -> moment.utc time, moment.ISO_8601

    parse_duration = (str)->
      sign = str.substr(0, 1) #+
      offset = +str.substr(1, str.length - 2) #5
      offsetunit = str.substr(str.length - 1) #h

      offset = -offset if sign is '-'

      duration = moment.duration offset, offsetunit

    durationformats =
      timestamp: (str) ->
        duration =  parse_duration str
        moment.utc().add duration
      second: (str) ->
        duration =  parse_duration str
        moment.utc().startOf('second').add duration
      minute: (str) ->
        duration =  parse_duration str
        moment.utc().startOf('minute').add duration
      hour: (str) ->
        duration =  parse_duration str
        moment.utc().startOf('hour').add duration
      day: (str) ->
        duration =  parse_duration str
        moment.utc().startOf('day').add duration
      week: (str) ->
        duration =  parse_duration str
        moment.utc().startOf('week').add duration
      month: (str) ->
        duration =  parse_duration str
        moment.utc().startOf('month').add duration
      year: (str) ->
        duration =  parse_duration str
        moment.utc().startOf('year').add duration
      localsecond: (str) ->
        duration =  parse_duration str
        moment().startOf('second').add(duration).utc()
      localminute: (str) ->
        duration =  parse_duration str
        moment().startOf('minute').add(duration).utc()
      localhour: (str) ->
        duration =  parse_duration str
        moment().startOf('hour').add(duration).utc()
      localday: (str) ->
        duration =  parse_duration str
        moment().startOf('day').add(duration).utc()
      localweek: (str) ->
        duration =  parse_duration str
        moment().startOf('week').add(duration).utc()
      localmonth: (str) ->
        duration =  parse_duration str
        moment().startOf('month').add(duration).utc()
      localyear: (str) ->
        duration =  parse_duration str
        moment().startOf('year').add(duration).utc()

    if start?
      if typeof start is 'string'
        for name, parse of durationformats
          continue if start.indexOf(name) isnt 0
          do (name, parse) ->
            parse_start = (time) -> parse start[name.length..]
          break
        domain[0] = parse_start start
      else
        domain[0] = start

    if end?
      if typeof start is 'string'
        for name, parse of durationformats
          continue if end.indexOf(name) isnt 0
          do (name, parse) ->
            parse_end = (time) -> parse end[name.length..]
          break
        domain[1] = parse_end end
      else
        domain[1] = end

    poi = null
    if moment.utc().isBetween domain[0], domain[1]
      poi = moment.utc()

    hub = createhub()

    for s in spec.spec
      unless components[s.type]?
        return console.error "#{s.type} component not found"
      items.push components[s.type] dom,
        components: components
        spec: s
        dimensions: dimensions
        hub: hub
        data: data
        domain: domain

    hub.emit 'poi', poi

  resize: (dimensions) ->
    for i in items
      continue unless i.resize?
      i.resize dimensions
