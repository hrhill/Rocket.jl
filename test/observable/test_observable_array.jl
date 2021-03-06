module RocketArrayObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "ArrayObservable" begin

    println("Testing: from")

    struct DummyObject end

    @testset begin
        @test from([ 1, 2, 3 ]) == ArrayObservable{Int, Rocket.AsapScheduler}([ 1, 2, 3 ], Rocket.AsapScheduler())
        @test from(( 1, 2, 3 )) == ArrayObservable{Int, Rocket.AsapScheduler}([ 1, 2, 3 ], Rocket.AsapScheduler())
        @test from(0)           == ArrayObservable{Int, Rocket.AsapScheduler}([ 0 ], Rocket.AsapScheduler())

        @test from([ 1.0, 2.0, 3.0 ]) == ArrayObservable{Float64, Rocket.AsapScheduler}([ 1.0, 2.0, 3.0 ], Rocket.AsapScheduler())
        @test from(( 1.0, 2.0, 3.0 )) == ArrayObservable{Float64, Rocket.AsapScheduler}([ 1.0, 2.0, 3.0 ], Rocket.AsapScheduler())
        @test from(0.0)               == ArrayObservable{Float64, Rocket.AsapScheduler}([ 0.0 ], Rocket.AsapScheduler())

        @test from("Hello!") == ArrayObservable{Char, Rocket.AsapScheduler}([ 'H', 'e', 'l', 'l', 'o', '!' ], Rocket.AsapScheduler())
        @test from('H')      == ArrayObservable{Char, Rocket.AsapScheduler}([ 'H' ], Rocket.AsapScheduler())

        @test from(0) != from(0.0)

        @test_throws Exception from()
        @test_throws Exception from(DummyObject())
    end

    @testset begin
        source = from(0)
        io = IOBuffer()

        show(io, source)

        printed = String(take!(io))

        @test occursin("ArrayObservable", printed)
        @test occursin(string(eltype(source)), printed)
    end

    run_testset([
        (
            source = from([ 1, 2, 3 ]),
            values = @ts([ 1, 2, 3, c ]),
            source_type = Int
        ),
        (
            source = from(1),
            values = @ts([ 1, c ]),
            source_type = Int
        ),
        (
            source = from("Hello!"),
            values = @ts([ 'H', 'e', 'l', 'l', 'o', '!', c ]),
            source_type = Char
        ),
        (
            source = from('H'),
            values = @ts([ 'H', c ]),
            source_type = Char
        ),
        (
            source = from("H"),
            values = @ts([ 'H', c ]),
            source_type = Char
        ),
        (
            source = from("H"),
            values = @ts([ 'H', c ]),
            source_type = Char
        ),
        (
            source = from((0, 1, 2)),
            values = @ts([ 0, 1, 2, c ]),
            source_type = Int
        )
    ])

end

end
