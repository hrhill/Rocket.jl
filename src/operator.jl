import Base: |>

export OperatorTrait, TypedOperatorTrait, LeftTypedOperatorTrait, RightTypedOperatorTrait, InferableOperatorTrait, InvalidOperatorTrait
export AbstractOperator, TypedOperator, LeftTypedOperator, RightTypedOperator, InferableOperator
export as_operator, call_operator!, on_call!, operator_right
export |>

"""
Abstract type for all possible operator traits

See also: [`TypedOperatorTrait`](@ref), [`LeftTypedOperatorTrait`](@ref), [`RightTypedOperatorTrait`](@ref), [`InferableOperatorTrait`](@ref), [`InvalidOperatorTrait`](@ref),
"""
abstract type OperatorTrait end

"""
Typed operator trait specifies operator to be statically typed with input and output data types.
Typed operator with input type `L` and output type `R` can only operate on input Observable with data type `L`
and will always produce an Observable with data type `R`.

# Examples

```jldoctest
using Rx

struct MyTypedOperator <: TypedOperator{Int, Int} end

function Rx.on_call!(::Type{Int}, ::Type{Int}, op::MyTypedOperator, s::S) where { S <: Subscribable{Int} }
    return ProxyObservable{Int}(s, MyTypedOperatorProxy())
end

struct MyTypedOperatorProxy <: ActorProxy end

Rx.actor_proxy!(::MyTypedOperatorProxy, actor::A) where { A <: AbstractActor{Int} } = MyTypedOperatorProxiedActor{A}(actor)

struct MyTypedOperatorProxiedActor{ A <: AbstractActor{Int} } <: Actor{Int}
    actor :: A
end

function Rx.on_next!(actor::MyTypedOperatorProxiedActor{A}, data::Int) where { A <: AbstractActor{Int} }
    # Do something with a data and/or redirect it to actor.actor
    next!(actor.actor, data + 1)
end

Rx.on_error!(actor::MyTypedOperatorProxiedActor, err) = error!(actor.actor, err)
Rx.on_complete!(actor::MyTypedOperatorProxiedActor)   = complete!(actor.actor)

source = from([ 0, 1, 2 ])
subscribe!(source |> MyTypedOperator(), LoggerActor{Int}())
;

# output

[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Completed
```

See also: [`TypedOperator`](@ref), [`OperatorTrait`](@ref), [`ProxyObservable`](@ref), [`ActorProxy`](@ref)
"""
struct TypedOperatorTrait{L, R}   <: OperatorTrait end

"""
Left typed operator trait specifies operator to be statically typed with input data type.
To infer output data type this trait should specify a special function `operator_right(operator, ::Type{L}) where L` which will be
used to infer output data type. Left typed operator with input type `L` can only operate on input Observable with data type `L` and
will always produce an Observable with data type `operator_right(operator, ::Type{L})`.

# Examples

```jldoctest
using Rx

struct CountIntegersOperator <: LeftTypedOperator{Int} end

function Rx.on_call!(::Type{Int}, ::Type{Tuple{Int, Int}}, op::CountIntegersOperator, s::S) where { S <: Subscribable{Int} }
    return ProxyObservable{Tuple{Int, Int}}(s, CountIntegersOperatorProxy())
end

function Rx.operator_right(::CountIntegersOperator, ::Type{Int})
    return Tuple{Int, Int}
end

struct CountIntegersOperatorProxy <: ActorProxy end

function Rx.actor_proxy!(::CountIntegersOperatorProxy, actor::A) where { A <: AbstractActor{ Tuple{Int, Int} } }
    return CountIntegersProxiedActor{A}(0, actor)
end

mutable struct CountIntegersProxiedActor{ A <: AbstractActor{ Tuple{Int, Int} } } <: Actor{Int}
    current :: Int
    actor   :: A
end

function Rx.on_next!(actor::CountIntegersProxiedActor{A}, data::Int) where { A <: AbstractActor{ Tuple{Int, Int} } }
    current = actor.current
    actor.current += 1
    next!(actor.actor, (current, data)) # e.g.
end

Rx.on_error!(actor::CountIntegersProxiedActor, err) = error!(actor.actor, err)
Rx.on_complete!(actor::CountIntegersProxiedActor)   = complete!(actor.actor)

source = from([ 0, 0, 0 ])
subscribe!(source |> CountIntegersOperator(), LoggerActor{Tuple{Int, Int}}())
;

# output

[LogActor] Data: (0, 0)
[LogActor] Data: (1, 0)
[LogActor] Data: (2, 0)
[LogActor] Completed
```

See also: [`LeftTypedOperator`](@ref), [`OperatorTrait`](@ref), [`ProxyObservable`](@ref), [`ActorProxy`](@ref)
"""
struct LeftTypedOperatorTrait{L}  <: OperatorTrait end

"""
Right typed operator trait specifies operator to be statically typed with output data type.

# Examples

```jldoctest
using Rx

struct ConvertToFloatOperator <: RightTypedOperator{Float64} end

function Rx.on_call!(::Type{L}, ::Type{Float64}, op::ConvertToFloatOperator, s::S) where { S <: Subscribable{L} } where L
    return ProxyObservable{Float64}(s, ConvertToFloatProxy{L}())
end

struct ConvertToFloatProxy{L} <: ActorProxy end

function Rx.actor_proxy!(proxy::ConvertToFloatProxy{L}, actor::A) where { A <: AbstractActor{Float64} } where L
    return ConvertToFloatProxyActor{L, A}(actor)
end

mutable struct ConvertToFloatProxyActor{ L, A <: AbstractActor{Float64} } <: Actor{L}
    actor :: A
end

function Rx.on_next!(actor::ConvertToFloatProxyActor{L, A}, data::L) where { A <: AbstractActor{Float64} } where L
    next!(actor.actor, convert(Float64, data)) # e.g.
end

Rx.on_error!(actor::ConvertToFloatProxyActor, err) = error!(actor.actor, err)
Rx.on_complete!(actor::ConvertToFloatProxyActor)   = complete!(actor.actor)

source = from([ 1, 2, 3 ])
subscribe!(source |> ConvertToFloatOperator(), LoggerActor{Float64}())
;

# output

[LogActor] Data: 1.0
[LogActor] Data: 2.0
[LogActor] Data: 3.0
[LogActor] Completed
```

See also: [`RightTypedOperator`](@ref), [`OperatorTrait`](@ref), [`ProxyObservable`](@ref), [`ActorProxy`](@ref)
"""
struct RightTypedOperatorTrait{R} <: OperatorTrait end

"""
Inferable operator trait specifies operator to be statically typed neither with input data type nor with output data type.
To infer output data type this trait should specify a special function `operator_right(operator, ::Type{L}) where L` where `L` is input data type
which will be used to infer output data type.

```jldoctest
using Rx

struct IdentityOperator <: InferableOperator end

function Rx.on_call!(::Type{L}, ::Type{L}, op::IdentityOperator, s::S) where { S <: Subscribable{L} } where L
    return ProxyObservable{L}(s, IdentityProxy{L}())
end

Rx.operator_right(::IdentityOperator, ::Type{L}) where L = L

struct IdentityProxy{L} <: ActorProxy end

function Rx.actor_proxy!(proxy::IdentityProxy{L}, actor::A) where { A <: AbstractActor{L} } where L
    return IdentityProxyActor{L, A}(actor)
end

mutable struct IdentityProxyActor{ L, A <: AbstractActor{L} } <: Actor{L}
    actor :: A
end

function Rx.on_next!(actor::IdentityProxyActor{L, A}, data::L) where { A <: AbstractActor{L} } where L
    next!(actor.actor, data) # e.g.
end

Rx.on_error!(actor::IdentityProxyActor, err) = error!(actor.actor, err)
Rx.on_complete!(actor::IdentityProxyActor)   = complete!(actor.actor)

source = from([ 1, 2, 3 ])
subscribe!(source |> IdentityOperator(), LoggerActor{Int}())

source = from([ 1.0, 2.0, 3.0 ])
subscribe!(source |> IdentityOperator(), LoggerActor{Float64}())
;

# output

[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Completed
[LogActor] Data: 1.0
[LogActor] Data: 2.0
[LogActor] Data: 3.0
[LogActor] Completed

```

See also: [`InferableOperator`](@ref), [`OperatorTrait`](@ref), [`ProxyObservable`](@ref), [`ActorProxy`](@ref)
"""
struct InferableOperatorTrait     <: OperatorTrait end

"""
InvalidOperatorTrait trait specifies special 'invalid' behaviour and types with such a trait specification cannot be used as an operator for an observable stream.
By default any type has InvalidOperatorTrait trait specification
"""
struct InvalidOperatorTrait       <: OperatorTrait end

"""
Supertype for all operators
"""
abstract type AbstractOperator      end

"""
Supertype for any operator with TypedOperatorTrait behaviour

See also: [`TypedOperatorTrait`](@ref)
"""
abstract type TypedOperator{L, R}   <: AbstractOperator end

"""
Supertype for any operator with LeftTypedOperatorTrait behaviour

See also: [`LeftTypedOperatorTrait`](@ref)
"""
abstract type LeftTypedOperator{L}  <: AbstractOperator end

"""
Supertype for any operator with RightTypedOperatorTrait behaviour

See also: [`RightTypedOperatorTrait`](@ref)
"""
abstract type RightTypedOperator{R} <: AbstractOperator end

"""
Supertype for any operator with InferableOperatorTrait behaviour

See also: [`InferableOperatorTrait`](@ref)
"""
abstract type InferableOperator     <: AbstractOperator end

as_operator(::Type)                                          = InvalidOperatorTrait()
as_operator(::Type{<:TypedOperator{L, R}})   where L where R = TypedOperatorTrait{L, R}()
as_operator(::Type{<:LeftTypedOperator{L}})  where L         = LeftTypedOperatorTrait{L}()
as_operator(::Type{<:RightTypedOperator{R}}) where R         = RightTypedOperatorTrait{R}()
as_operator(::Type{<:InferableOperator})                     = InferableOperatorTrait()

call_operator!(operator::T, source) where T = call_operator!(as_operator(T), operator, source)

function call_operator!(::InvalidOperatorTrait, operator, source)
    error("Type $(typeof(operator)) is not a valid operator type. \nConsider extending your type with one of the base Operator abstract types: TypedOperator, LeftTypedOperator, RightTypedOperator, InferableOperator or implement Rx.as_operator(::Type{<:$(typeof(operator))}).")
end

function call_operator!(::TypedOperatorTrait{L, R}, operator, source::S) where { S <: Subscribable{NotL} } where L where R where NotL
    error("Operator of type $(typeof(operator)) expects source data to be of type $(L), but $(NotL) found.")
end

function call_operator!(::TypedOperatorTrait{L, R}, operator, source::S) where { S <: Subscribable{L} } where L where R
    on_call!(L, R, operator, source)
end

function call_operator!(::LeftTypedOperatorTrait{L}, operator, source::S) where { S <: Subscribable{NotL} } where L where NotL
    error("Operator of type $(typeof(operator)) expects source data to be of type $(L), but $(NotL) found.")
end

function call_operator!(::LeftTypedOperatorTrait{L}, operator, source::S) where { S <: Subscribable{L} } where L
    on_call!(L, operator_right(operator, L), operator, source)
end

function call_operator!(::RightTypedOperatorTrait{R}, operator, source::S) where { S <: Subscribable{L} } where L where R
    on_call!(L, R, operator, source)
end

function call_operator!(::InferableOperatorTrait, operator, source::S) where { S <: Subscribable{L} } where L
    on_call!(L, operator_right(operator, L), operator, source)
end

Base.:|>(source::S, operator) where { S <: Subscribable{T} } where T = call_operator!(operator, source)

on_call!(::Type, ::Type, operator, source) = error("You probably forgot to implement on_call!(::Type, ::Type, operator::$(typeof(operator)), source).")

operator_right(operator, L) = error("You probably forgot to implement operator_right(operator::$(typeof(operator)), L).")
