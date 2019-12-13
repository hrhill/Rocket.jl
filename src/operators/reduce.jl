export reduce
export ReduceOperator, on_call!
export ReduceProxy, actor_proxy!
export ReduceActor, on_next!, on_error!, on_complete!
export @CreateReduceOperator

import Base: reduce

reduce(::Type{T}, ::Type{R}, reduceFn::Function, initial::R = zero(R)) where T where R = ReduceOperator{T, R}(reduceFn, initial)

struct ReduceOperator{T, R} <: Operator{T, R}
    reduceFn :: Function
    initial  :: R
end

function on_call!(operator::ReduceOperator{T, R}, source::S) where { S <: Subscribable{T} } where T where R
    return ProxyObservable{R}(source, ReduceProxy{T, R}(operator.reduceFn, operator.initial))
end

struct ReduceProxy{T, R} <: ActorProxy
    reduceFn :: Function
    initial  :: R
end

actor_proxy!(proxy::ReduceProxy{T, R}, actor::A) where { A <: AbstractActor{R} } where T where R = ReduceActor{T, R, A}(proxy.reduceFn, copy(proxy.initial), actor)

mutable struct ReduceActor{T, R, A <: AbstractActor{R} } <: Actor{T}
    reduceFn :: Function
    current  :: R
    actor    :: A
end

function on_next!(actor::ReduceActor{T, R, A}, data::T) where { A <: AbstractActor{R} } where T where R
    actor.current = Base.invokelatest(actor.reduceFn, data, actor.current)
end

on_error!(actor::ReduceActor, error) = error!(actor.actor, error)

function on_complete!(actor::ReduceActor)
    next!(actor.actor, actor.current)
    complete!(actor.actor)
end

macro CreateReduceOperator(name, reduceFn)
    operatorName   = Symbol(name, "ReduceOperator")
    proxyName      = Symbol(name, "ReduceProxy")
    actorName      = Symbol(name, "ReduceActor")

    operatorDefinition = quote
        struct $operatorName{T, R} <: Rx.Operator{T, R}
            initial :: R

            $(operatorName){T, R}(initial = zero(R)) where T where R = new(initial)
        end

        function Rx.on_call!(operator::($operatorName){T, R}, source::S) where { S <: Rx.Subscribable{T} } where T where R
            return Rx.ProxyObservable{R}(source, ($proxyName){T, R}(operator.initial))
        end
    end

    proxyDefinition = quote
        struct $proxyName{T, R} <: ActorProxy
            initial :: R
        end

        Rx.actor_proxy!(proxy::($proxyName){T, R}, actor::A) where { A <: Rx.AbstractActor{R} } where T where R = ($actorName){T, R, A}(copy(proxy.initial), actor)
    end

    actorDefinition = quote
        mutable struct $actorName{T, R, A <: Rx.AbstractActor{R} } <: Rx.Actor{T}
            current :: R
            actor   :: A
        end

        Rx.on_next!(actor::($actorName){T, R, A}, data::T) where { A <: Rx.AbstractActor{R} } where T where R = begin
            __inlined_lambda = $reduceFn
            actor.current = __inlined_lambda(data, actor.current)
        end

        Rx.on_error!(actor::($actorName), error) = Rx.error!(actor.actor, error)
        Rx.on_complete!(actor::($actorName))     = begin
            Rx.next!(actor.actor, actor.current)
            Rx.complete!(actor.actor)
        end
    end

    generated = quote
        $operatorDefinition
        $proxyDefinition
        $actorDefinition
    end

    return esc(generated)
end