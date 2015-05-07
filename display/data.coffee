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

###

Parse strings of the form:

<variable> (+|-) digits unit
or
ISO 8601 (http://en.wikipedia.org/wiki/ISO_8601)

e.g.

day+5h = start of the current day + five hours in current timezone
utcmonth+1M = start of the next month in utc

Always returns utc times

###

d3 = require 'd3'
moment = require 'moment-timezone'
timelord = require '@metocean/timelord'
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

    # yaml supports dates, so only parse if a string
    if spec.display.start?
      domain[0] = spec.display.start
      if typeof domain[0] is 'string'
        domain[0] = timelord domain[0]
    if spec.display.end?
      domain[1] = spec.display.end
      if typeof domain[1] is 'string'
        domain[1] = timelord domain[1]
    poi = null
    if moment.utc().isBetween domain[0], domain[1]
      poi = moment.utc()
    if spec.display.timezone?
      tz = spec.display.timezone
      domain[0] = domain[0].tz tz
      domain[1] = domain[1].tz tz
      for d in data
        d.time = d.time.tz tz
      poi = poi.tz tz if poi?

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
