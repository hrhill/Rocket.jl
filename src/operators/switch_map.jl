export switch_map

import Base: show

"""
    switch_map(::Type{R}, mappingFn::F) where { R, F <: Function }

Creates a `switch_map` operator, which returns an Observable that emits items based on applying a function `mappingFn` that you supply to each item
emitted by the source Observable, where that function returns an (so-called "inner") Observable. Each time it observes one of these inner Observables,
the output Observable begins emitting the items emitted by that inner Observable. When a new inner Observable is emitted, `switch_map` stops emitting
items from the earlier-emitted inner Observable and begins emitting items from the new one. It continues to behave like this for
subsequent inner Observables.

# Arguments
- `::Type{R}`: the type of data of output Observables after projection with `mappingFn`
- `mappingFn::F`: porjection function with `(data::Observable{L}) -> Observable{R}` signature, where L is type of data in "inner" observables

# Producing

Stream of type `<: Subscribable{R}`

# Examples
```jldoctest
using Rocket

source = from([ of(1), of(2), of(3) ])
subscribe!(source |> switch_map(Int), logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Completed
```

```jldoctest
using Rocket

source = from([ 1, 2, 3 ])
subscribe!(source |> switch_map(Float64, (d) -> of(convert(Float64, d ^ 2))), logger())
;

# output

[LogActor] Data: 1.0
[LogActor] Data: 4.0
[LogActor] Data: 9.0
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`RightTypedOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
switch_map(::Type{R}, mappingFn::F = identity) where { R, F <: Function } = SwitchMapOperator{R, F}(mappingFn)

struct SwitchMapOperator{R, F} <: RightTypedOperator{R}
    mappingFn :: F
end

function on_call!(::Type{L}, ::Type{R}, operator::SwitchMapOperator{R, F}, source) where { L, R, F }
    return proxy(R, source, SwitchMapProxy{L, R, F}(operator.mappingFn))
end

struct SwitchMapProxy{L, R, F} <: ActorSourceProxy
    mappingFn :: F
end

actor_proxy!(proxy::SwitchMapProxy{L, R, F}, actor::A) where { L, R, F, A } = SwitchMapActor{L, R, F, A}(proxy.mappingFn, actor)

mutable struct SwitchMapActorProps
    msubscription :: Teardown
    isubscription :: Teardown
    isdisposed    :: Bool

    SwitchMapActorProps() = new(VoidTeardown(), VoidTeardown(), false)
end

struct SwitchMapActor{L, R, F, A} <: Actor{L}
    mappingFn    :: F
    actor        :: A
    props        :: SwitchMapActorProps

    SwitchMapActor{L, R, F, A}(mappingFn::F, actor::A) where { L, R, F, A } = new(mappingFn, actor, SwitchMapActorProps())
end

struct SwitchMapInnerActor{R, S} <: Actor{R}
    switch :: S
end

on_next!(actor::SwitchMapInnerActor{R}, data::R) where R = next!(actor.switch.actor, data)
on_error!(actor::SwitchMapInnerActor,   err)             = error!(actor.switch, err)
on_complete!(actor::SwitchMapInnerActor)                 = begin end

function on_next!(actor::S, data::L) where { L, R, S <: SwitchMapActor{L, R} }
    if !actor.props.isdisposed
        unsubscribe!(actor.props.isubscription)
        actor.props.isubscription = subscribe!(actor.mappingFn(data), SwitchMapInnerActor{R, S}(actor))
    end
end

function on_error!(actor::SwitchMapActor, err)
    if !actor.props.isdisposed
        __dispose(actor)
        error!(actor.actor, err)
    end
end

function on_complete!(actor::SwitchMapActor)
    if !actor.props.isdisposed
        __dispose(actor)
        complete!(actor.actor)
    end
end

function __dispose(actor::SwitchMapActor)
    actor.props.isdisposed = true
    unsubscribe!(actor.props.msubscription)
    unsubscribe!(actor.props.isubscription)
end

struct SwitchMapSource{L, S} <: Subscribable{L}
    source :: S
end

source_proxy!(proxy::SwitchMapProxy{L, R, F}, source::S) where { L, R, F, S } = SwitchMapSource{L, S}(source)

function on_subscribe!(source::SwitchMapSource, actor::SwitchMapActor)
    actor.props.msubscription = subscribe!(source.source, actor)
    return SwitchMapSubscription(actor)
end

struct SwitchMapSubscription{A} <: Teardown
    actor :: A
end

as_teardown(::Type{<:SwitchMapSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::SwitchMapSubscription)
    unsubscribe!(subscription.actor.props.msubscription)
    unsubscribe!(subscription.actor.props.isubscription)
end


Base.show(io::IO, ::SwitchMapOperator{R})   where {    R } = print(io, "SwitchMapOperator($R)")
Base.show(io::IO, ::SwitchMapProxy{L, R})   where { L, R } = print(io, "SwitchMapProxy($L -> $R)")
Base.show(io::IO, ::SwitchMapActor{L, R})   where { L, R } = print(io, "SwitchMapActor($L -> $R)")
Base.show(io::IO, ::SwitchMapInnerActor{R}) where {    R } = print(io, "SwitchMapInnerActor($R)")
Base.show(io::IO, ::SwitchMapSource{S})     where S        = print(io, "SwitchMapSource($S)")
Base.show(io::IO, ::SwitchMapSubscription)                 = print(io, "SwitchMapSubscription()")
