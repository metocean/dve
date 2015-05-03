build = (dom, items) ->
  d3
    .select dom
    .selectAll 'div.item'
    .data items
    .enter()
    .append 'div'
    .each (d, i) ->
      base = d3
        .select @
        .attr 'class', "item #{d.type}"
      new window["ER#{d.type}"] base, d

d3.text './presentation.yml', (error, items) ->
  items = jsyaml.load items
  dom = document.querySelector 'body'
  build dom, items