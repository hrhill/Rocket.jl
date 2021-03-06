# [List of all available operators](@id operators_list)

There are operators for different purposes, and they may be categorized as: creation, transformation, filtering, joining, multicasting, error handling, utility, etc.

## Creation operators

- [make](@ref observable_function)
- [of](@ref observable_single)
- [from](@ref observable_array)
- [error](@ref observable_error)
- [never](@ref observable_never)
- [completed](@ref observable_completed)
- [timer](@ref observable_timer)
- [interval](@ref observable_interval)
- [combined](@ref observable_combined)
- [merged](@ref observable_merged)

## Transformation operators

- [map](@ref operator_map)
- [map_to](@ref operator_map_to)
- [scan](@ref operator_scan)
- [enumerate](@ref operator_enumerate)
- [uppercase](@ref operator_uppercase)
- [lowercase](@ref operator_lowercase)
- [to_array](@ref operator_to_array)
- [switch_map](@ref operator_switch_map)
- [switch_map_to](@ref operator_switch_map_to)

## Filtering operators

- [filter](@ref operator_filter)
- [some](@ref operator_some)
- [take](@ref operator_take)
- [take_until](@ref operator_take_until)
- [first](@ref operator_first)
- [last](@ref operator_last)
- [find](@ref operator_find)
- [find_index](@ref operator_find_index)

## Mathematical and Aggregate operators

- [count](@ref operator_count)
- [max](@ref operator_max)
- [min](@ref operator_min)
- [reduce](@ref operator_reduce)
- [sum](@ref operator_sum)

## Error handling operators

- [catch_error](@ref operator_catch_error)
- [rerun](@ref operator_rerun)

## Multicasting operators

- [multicast](@ref operator_multicast)
- [publish](@ref operator_publish)
- [publish_behavior](@ref operator_publish)
- [publish_replay](@ref operator_publish)
- [share](@ref operator_share)
- [share_replay](@ref operator_share)

## Utility operators

- [tap](@ref operator_tap)
- [tap_on_subscribe](@ref operator_tap_on_subscribe)
- [tap_on_complete](@ref operator_tap_on_complete)
- [delay](@ref operator_delay)
- [safe](@ref operator_safe)
- [noop](@ref operator_noop)
- [ref_count](@ref operator_ref_count)
- [async](@ref operator_ref_async)
- [default_if_empty](@ref operator_ref_default_if_empty)
- [error_if_empty](@ref operator_ref_default_if_empty)
- [skip_next](@ref operator_skip_next)
- [skip_error](@ref operator_skip_error)
- [skip_complete](@ref operator_skip_complete)
