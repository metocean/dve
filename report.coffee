###

Represents an entire report.
Includes title, author and other metadata.

###

dve = require './'

module.exports = (dom, options) ->
  { components, spec } = options
  dve dom,
    components: components
    spec: spec.spec
