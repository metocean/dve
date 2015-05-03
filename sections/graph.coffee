class ERgraph
  constructor: (base, options) ->
    @base = base
    @options = options

    d3.csv @options.source.url, (error, data) =>
      if @options.source.translate?
        for d in data
          for target, source of @options.source.translate
            continue if !d[source]?
            value = d[source]
            delete d[source]
            d[target] = value
      if @options.source.include?
        data = data.filter (d) =>
          shouldinclude = yes
          for key, value of @options.source.include
            continue if !d[key]?
            shouldinclude = shouldinclude and d[key] is value
          shouldinclude
      if @options.source.exclude?
        data = data.filter (d) =>
          shouldexclude = no
          for key, value of @options.source.exclude
            continue if !d[key]?
            shouldexclude = shouldexclude and d[key] is value
          not shouldexclude

      parse_time = (time) -> moment.utc d.time, moment.ISO_8601
      if @options.source.timeformat?
        parse_time = (time) => moment.utc d.time, @options.source.timeformat
      for d in data
        d.time = parse_time d.time

      domain = d3.extent data, (d) -> d.time

      timeRegex = /(\-|\+)[0-9]+([dwMyhms])/

      start = @options.display.start
      end = @options.display.end

      parse_start = (time) -> moment.utc time, moment.ISO_8601
      parse_end = (time) -> moment.utc time, moment.ISO_8601

      parse_duration = (str) =>
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

      hub_listeners = {}
      hub =
        on: (id, listener) ->
          hub_listeners[id] = [] if !hub_listeners[id]?
          hub_listeners[id].push listener
        emit: (id, args...) ->
          return if !hub_listeners[id]?
          h args... for h in hub_listeners[id]

      dimensions = window.getDimensions()
      dimensions[0] -= 42
      @base
        .selectAll 'svg.item'
        .data @options.rows
        .enter()
        .append 'svg'
        .each (d, i) ->
          svg = d3
            .select @
            .attr 'class', "item #{d.type}"
          d.hub = hub
          new window["ER#{d.type}"] svg, data, dimensions, d, domain
          hub.emit 'poi', poi

      d3
        .select window
        .on 'resize', debounce 125, ->
          dimensions = window.getDimensions()
          dimensions[0] -= 42
          hub.emit 'window dimensions changed', dimensions

          for i in d3.selectAll('.graph')
            for item in i
              item.resize dimensions if item.resize?