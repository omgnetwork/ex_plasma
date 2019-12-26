require 'coveralls'
Coveralls.wear!

ExUnit.start(exclude: [:skip, :conformance, :integration])
