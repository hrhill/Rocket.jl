module RxActorTest

using Test

import Rx
import Rx: UndefinedActorTrait, BaseActorTrait, NextActorTrait, ErrorActorTrait, CompletionActorTrait, ActorTrait
import Rx: AbstractActor, Actor, NextActor, ErrorActor, CompletionActor
import Rx: next!, error!, complete!
import Rx: on_next!, on_error!, on_complete!
import Rx: as_actor

@testset "Actor" begin

    struct DummyType end
    struct AbstractDummyActor <: AbstractActor{Any} end

    struct SpecifiedAbstractActor <: AbstractActor{Any} end
    Rx.as_actor(::Type{<:SpecifiedAbstractActor}) = BaseActorTrait{Any}()

    struct NotImplementedActor           <: Actor{Any} end
    struct NotImplementedNextActor       <: NextActor{Any} end
    struct NotImplementedErrorActor      <: ErrorActor{Any} end
    struct NotImplementedCompletionActor <: CompletionActor{Any} end

    struct ImplementedActor <: Actor{Any} end
    Rx.on_next!(::ImplementedActor, data)   = data
    Rx.on_error!(::ImplementedActor, error) = error
    Rx.on_complete!(::ImplementedActor)     = "ImplementedActor:complete"

    struct ImplementedNextActor <: NextActor{Any} end
    Rx.on_next!(::ImplementedNextActor, data) = data

    struct ImplementedErrorActor <: ErrorActor{Any} end
    Rx.on_error!(::ImplementedErrorActor, error) = error

    struct ImplementedCompletionActor <: CompletionActor{Any} end
    Rx.on_complete!(::ImplementedCompletionActor) = "ImplementedCompletionActor:complete"

    struct IntegerActor <: NextActor{Int} end
    Rx.on_next!(::IntegerActor, data::Int) = data

    @testset "as_actor" begin
            # Check if arbitrary dummy type has undefined actor type
            @test as_actor(DummyType) === UndefinedActorTrait()

            # Check if abstract actor type has undefined actor type
            @test as_actor(AbstractActor{Any}) === UndefinedActorTrait()
            @test as_actor(AbstractDummyActor) === UndefinedActorTrait()

            # Check if as_teardown return specified actor type
            @test as_actor(SpecifiedAbstractActor) === BaseActorTrait{Any}()
            @test as_actor(Actor{Int})             === BaseActorTrait{Int}()
            @test as_actor(NextActor{Int})         === NextActorTrait{Int}()
            @test as_actor(ErrorActor{Int})        === ErrorActorTrait{Int}()
            @test as_actor(CompletionActor{Int})   === CompletionActorTrait{Int}()

            @test as_actor(NotImplementedActor)           === BaseActorTrait{Any}()
            @test as_actor(NotImplementedNextActor)       === NextActorTrait{Any}()
            @test as_actor(NotImplementedErrorActor)      === ErrorActorTrait{Any}()
            @test as_actor(NotImplementedCompletionActor) === CompletionActorTrait{Any}()

            @test as_actor(ImplementedActor)           === BaseActorTrait{Any}()
            @test as_actor(ImplementedNextActor)       === NextActorTrait{Any}()
            @test as_actor(ImplementedErrorActor)      === ErrorActorTrait{Any}()
            @test as_actor(ImplementedCompletionActor) === CompletionActorTrait{Any}()

            @test as_actor(IntegerActor) === NextActorTrait{Int}()
    end

    @testset "next!" begin
            # Check if next! function throws an error for not valid actors
            @test_throws ErrorException next!(DummyType(), 1)
            @test_throws ErrorException next!(AbstractDummyActor(), 1)

            # Check if next! function throws an error without data argument
            @test_throws ErrorException next!(ImplementedActor())

            # Check if next! function throws an error for not implemented actors
            @test_throws ErrorException next!(NotImplementedActor(), 1)
            @test_throws ErrorException next!(NotImplementedNextActor(), 1)

            # Check if next! function doing nothing for incomplete actors
            @test next!(NotImplementedErrorActor(), 1)      === nothing
            @test next!(ImplementedErrorActor(), 1)         === nothing
            @test next!(NotImplementedCompletionActor(), 1) === nothing
            @test next!(ImplementedCompletionActor(), 1)    === nothing

            # Check next! function for implemented actors
            @test next!(ImplementedActor(),     1) === 1
            @test next!(ImplementedActor(),     2) === 2
            @test next!(ImplementedNextActor(), 1) === 1
            @test next!(ImplementedNextActor(), 2) === 2

            # Check next! function throws an error for wrong type of message
            @test_throws ErrorException next!(IntegerActor(), "string")
            @test_throws ErrorException next!(IntegerActor(), 1.0)
    end

    @testset "error!" begin
            # Check if error! function throws an error for not valid actors
            @test_throws ErrorException error!(DummyType(), 1)
            @test_throws ErrorException error!(AbstractDummyActor(), 1)

            # Check if error! function throws an error without error argument
            @test_throws ErrorException error!(ImplementedActor())

            # Check if error! function throws an error for not implemented actors
            @test_throws ErrorException error!(NotImplementedActor(), 1)
            @test_throws ErrorException error!(NotImplementedErrorActor(), 1)

            # Check if error! function doing nothing for incomplete actors
            @test error!(NotImplementedNextActor(), 1)       === nothing
            @test error!(ImplementedNextActor(), 1)          === nothing
            @test error!(NotImplementedCompletionActor(), 1) === nothing
            @test error!(ImplementedCompletionActor(), 1)    === nothing

            # Check error! function for implemented actors
            @test error!(ImplementedActor(),      1) === 1
            @test error!(ImplementedActor(),      2) === 2
            @test error!(ImplementedErrorActor(), 1) === 1
            @test error!(ImplementedErrorActor(), 2) === 2
    end

    @testset "complete!" begin
            # Check if error! function throws an error for not valid actors
            @test_throws ErrorException complete!(DummyType())
            @test_throws ErrorException complete!(AbstractDummyActor())

            # Check if complete! function throws an error with extra argument
            @test_throws ErrorException complete!(ImplementedActor(), 1)

            # Check if complete! function throws an error for not implemented actors
            @test_throws ErrorException complete!(NotImplementedActor())
            @test_throws ErrorException complete!(NotImplementedCompletionActor(), 1)

            # Check if complete! function doing nothing for incomplete actors
            @test complete!(NotImplementedNextActor())  === nothing
            @test complete!(ImplementedNextActor())     === nothing
            @test complete!(NotImplementedErrorActor()) === nothing
            @test complete!(ImplementedErrorActor())    === nothing

            # Check complete! function for implemented actors
            @test complete!(ImplementedActor())           === "ImplementedActor:complete"
            @test complete!(ImplementedCompletionActor()) === "ImplementedCompletionActor:complete"
    end

end

end