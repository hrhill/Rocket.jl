# [About subjects](@id section_subjects)

What is a __Subject__? An Rx.jl Subject is a special type of Observable that allows values to be multicasted to many Actors. While plain Observables are unicast (each subscribed Actor owns an independent execution of the Observable), Subjects are multicast.

!!! note
    A Subject is like an Observable, but can multicast to many Actors. Subjects are like event emitters: they maintain a registry of many listeners.

Every Subject is an Observable. Given a Subject, you can subscribe to it, providing an Actor, which will start receiving values normally. From the perspective of the Actor, it cannot tell whether the Observable execution is coming from a plain unicast Observable or a Subject.

Internally to the Subject, subscribe does not invoke a new execution that delivers values. It simply registers the given Actor in a list of Actors.

Every Subject is an Actor itself. It is an object with the methods `next!`, `error!`, and `complete!`. To feed a new value to the Subject, just call `next!(subject, theValue)`, and it will be multicasted to the Actors registered to listen to the Subject.

In the example below, we have two Observers attached to a Subject, and we feed some values to the Subject:

```julia
using Rx

subject = Subject{Int}()

subscription1 = subscribe!(subject, LambdaActor{Int}(
    on_next = (d) -> println("Actor 1: $d")
))

subscription2 = subscribe!(subject, LambdaActor{Int}(
    on_next = (d) -> println("Actor 2: $d")
))

next!(subject, 0)

# Logs
# Actor 1: 0
# Actor 2: 0

unsubscribe!(subscription1)
unsubscribe!(subscription2)

```

Since a Subject is an actor, this also means you may provide a Subject as the argument to the subscribe of any Observable, like the example below shows:

```julia
using Rx

subject = Subject{Int}()

subscription1 = subscribe!(subject, LambdaActor{Int}(
    on_next = (d) -> println("Actor 1: $d")
))

subscription2 = subscribe!(subject, LambdaActor{Int}(
    on_next = (d) -> println("Actor 2: $d")
))

source = from([ 1, 2, 3 ])
subscribe!(source, subject);

# Logs
# Actor 1: 1
# Actor 2: 1
# Actor 1: 2
# Actor 2: 2
# Actor 1: 3
# Actor 2: 3
```

With the approach above, we essentially just converted a unicast Observable execution to multicast, through the Subject. This demonstrates how Subjects are the only way of making any Observable execution be shared to multiple Observers.

There are also a few specializations of the Subject type: [`BehaviorSubject`](@ref), [`ReplaySubject`](@ref), and [`AsyncSubject`](@ref).

## BehaviorSubject

[ Under development ]

## ReplaySubject

[ Under development ]

## AsyncSubject

[ Under development ]