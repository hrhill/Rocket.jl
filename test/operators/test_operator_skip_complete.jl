module RocketSkipCompleteOperatorTest

using Test
using Rocket

include("./test_helpers.jl")

@testset "operator: skip_complete()" begin

    run_testset([
        (
            source = from(1:5) |> skip_complete(),
            values = @ts([ 1:5 ])
        ),
        (
            source = completed() |> skip_complete(),
            values = @ts()
        ),
        (
            source = throwError(1) |> skip_complete(),
            values = @ts(e(1))
        ),
        (
            source = never() |> skip_complete(),
            values = @ts()
        )
    ])

end

end