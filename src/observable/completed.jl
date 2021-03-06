export CompletedObservable, completed

import Base: ==
import Base: show

"""
    CompletedObservable{D}()

Observable that emits no items to the Actor and immediately sends a complete notification on subscription.

See also: [`Subscribable`](@ref), [`completed`](@ref)
"""
struct CompletedObservable{D} <: Subscribable{D} end

function on_subscribe!(observable::CompletedObservable, actor)
    complete!(actor)
    return VoidTeardown()
end

"""
    completed(T = Any)

Creation operator for the `CompletedObservable` that emits no items to the Actor and immediately sends a complete notification on subscription.

# Arguments
- `T`: type of output data source, optional, `Any` is the default

# Examples

```jldoctest
using Rocket

source = completed(Int)
subscribe!(source, logger())
;

# output

[LogActor] Completed

```

See also: [`CompletedObservable`](@ref), [`subscribe!`](@ref), [`logger`](@ref)
"""
completed(T = Any) = CompletedObservable{T}()

Base.:(==)(::CompletedObservable{T},  ::CompletedObservable{T})  where T           = true
Base.:(==)(::CompletedObservable{T1}, ::CompletedObservable{T2}) where T1 where T2 = false

Base.show(io::IO, ::CompletedObservable{T}) where T = print(io, "CompletedObservable($T)")
