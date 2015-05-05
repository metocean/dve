###

Represents an entire report.
Includes title, author and other metadata.

TODO: metadata

###

mount = require './mount'

module.exports = (dom, options) ->
  { components, spec } = options
  mount dom,
    components: components
    spec: spec.spec
