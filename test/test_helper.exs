Application.ensure_all_started(:ethereumex)
Application.ensure_all_started(:telemetry)
ExUnit.start(exclude: [:skip, :conformance])
