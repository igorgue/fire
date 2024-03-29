from memory import memset_zero

alias THREAD_POOL_SIZE = 10
alias __SIZEOF_PTHREAD_MUTEX_T = 40  # value for x86_64
alias __SIZEOF_PTHREAD_ATTR_T = 56  # value for x86_64

alias PTHREAD_MUTEX_TIMED_NP = 0
alias PTHREAD_MUTEX_RECURSIVE_NP = 1
alias PTHREAD_MUTEX_ERRORCHECK_NP = 2
alias PTHREAD_MUTEX_ADAPTIVE_NP = 3

alias pthread_t = UInt64


@value
@register_passable("trivial")
struct __pthread_mutex_s:
    var __lock: Int32
    var __count: UInt32
    var __owner: Int32
    var __nusers: UInt32
    var __kind: Int32
    var __spins: Int16
    var __elision: Int16
    var __list: __pthread_list_t


@value
@register_passable("trivial")
struct pthread_mutex_t:
    var __data: __pthread_mutex_s
    var __size: StaticTuple[__SIZEOF_PTHREAD_MUTEX_T, Int8]
    var __align: Int64

    fn __init__(__kind: Int32) -> Self:
        return Self {
            __data: __pthread_mutex_s(
                0,
                0,
                0,
                0,
                __kind,
                0,
                0,
                __pthread_list_t(),
            ),
            __size: StaticTuple[__SIZEOF_PTHREAD_MUTEX_T, Int8](0),
            __align: 0,
        }


@value
@register_passable("trivial")
struct __pthread_list_t:
    # FIXME: __prev and __next should be a pointers to __pthread_list_t
    # but now a void pointer would do which is a Pointer[UInt8]
    var __prev: Pointer[UInt8]
    var __next: Pointer[UInt8]

    fn __init__() -> Self:
        return Self {
            __prev: Pointer[UInt8].get_null(),
            __next: Pointer[UInt8].get_null(),
        }


@value
@register_passable("trivial")
struct pthread_cond_t:
    var __data: __pthread_cond_s
    var __size: StaticTuple[__SIZEOF_PTHREAD_MUTEX_T, Int8]
    var __align: Int64

    fn __init__() -> Self:
        return Self {
            __data: __pthread_cond_s(
                __atomic_wide_counter(
                    __value64=0,
                    __value32=__value32(
                        __low=0,
                        __high=0,
                    ),
                ),
                __atomic_wide_counter(
                    __value64=0,
                    __value32=__value32(
                        __low=0,
                        __high=0,
                    ),
                ),
                StaticTuple[2, UInt32](0, 0),
                StaticTuple[2, UInt32](0, 0),
                0,
                0,
                StaticTuple[2, UInt32](0, 0),
            ),
            __size: StaticTuple[__SIZEOF_PTHREAD_MUTEX_T, Int8](0),
            __align: 0,
        }


@value
@register_passable("trivial")
struct __pthread_cond_s:
    var __wseq: __atomic_wide_counter
    var __g1_start: __atomic_wide_counter
    var __g_refs: StaticTuple[2, UInt32]
    var __g_size: StaticTuple[2, UInt32]
    var __g1_orig_size: UInt32
    var __wrefs: UInt32
    var __g_signals: StaticTuple[2, UInt32]


@value
@register_passable("trivial")
struct __atomic_wide_counter:
    var __value64: UInt64
    var __value32: __value32


@value
@register_passable("trivial")
struct __value32:
    var __low: UInt32
    var __high: UInt32


@value
@register_passable("trivial")
struct pthread_attr_t:
    var __size: StaticTuple[__SIZEOF_PTHREAD_ATTR_T, UInt8]
    var __align: Int64

    fn __init__() -> Self:
        return Self {
            __size: StaticTuple[__SIZEOF_PTHREAD_ATTR_T, UInt8](0),
            __align: 0,
        }


fn pthread_mutex_lock(inout __mutex: pthread_mutex_t) -> Int32:
    return external_call["pthread_mutex_lock", Int32, Pointer[pthread_mutex_t]](
        Pointer[pthread_mutex_t].address_of(__mutex)
    )


fn pthread_mutex_unlock(inout __mutex: pthread_mutex_t) -> Int32:
    return external_call["pthread_mutex_unlock", Int32, Pointer[pthread_mutex_t]](
        Pointer[pthread_mutex_t].address_of(__mutex)
    )


fn pthread_cond_wait(
    inout __cond: pthread_cond_t, inout __mutex: pthread_mutex_t
) -> Int32:
    return external_call[
        "pthread_cond_wait", Int32, Pointer[pthread_mutex_t], Pointer[pthread_cond_t]
    ](
        Pointer[pthread_mutex_t].address_of(__mutex),
        Pointer[pthread_cond_t].address_of(__cond),
    )


fn pthread_cond_signal(inout __cond: pthread_cond_t) -> Int32:
    return external_call["pthread_cond_signal", Int32, Pointer[pthread_cond_t]](
        Pointer[pthread_cond_t].address_of(__cond),
    )


fn pthread_attr_init(inout __attr: pthread_attr_t) -> Int32:
    return external_call["pthread_attr_init", Int32, Pointer[pthread_attr_t]](
        Pointer[pthread_attr_t].address_of(__attr),
    )


fn pthread_attr_getdetachstate(
    inout __attr: pthread_attr_t, inout __detachstate: Int32
) -> Int32:
    return external_call[
        "pthread_attr_init", Int32, Pointer[pthread_attr_t], Pointer[Int32]
    ](
        Pointer[pthread_attr_t].address_of(__attr),
        Pointer[Int32].address_of(__detachstate),
    )


fn pthread_attr_setdetachstate(
    inout __attr: pthread_attr_t, __detachstate: Int32
) -> Int32:
    return external_call["pthread_attr_init", Int32, Pointer[pthread_attr_t], Int32](
        Pointer[pthread_attr_t].address_of(__attr), __detachstate
    )


# FIXME: no workee
# fn pthread_create[
#     T: AnyType
# ]( inout __newthread: pthread_t,
#     __start_routine: fn (T) capturing -> UInt8,
#     __arg: T,
# ) -> Int32:
#     """Create a new thread without attr and arg."""
#     return external_call[
#         "pthread_create",
#         Int32,
#         Pointer[pthread_t],
#         UInt8,
#         fn (T) capturing -> UInt8,
#         T,
#     ](
#         Pointer[pthread_t].address_of(__newthread),
#         0,
#         __start_routine,
#         __arg,
#     )
#
fn pthread_create(
    inout __newthread: pthread_t,
    __start_routine: fn (Int) capturing -> UInt8,
) -> Int32:
    """Create a new thread without attr and arg."""
    return external_call[
        "pthread_create",
        Int32,
        Pointer[pthread_t],
        Pointer[UInt8],
        fn (Int) capturing -> UInt8,
        Pointer[UInt8],
    ](
        Pointer[pthread_t].address_of(__newthread),
        Pointer[UInt8].get_null(),
        __start_routine,
        Pointer[UInt8].get_null(),
    )


fn pthread_create(
    inout __newthread: pthread_t,
    __start_routine: fn (Int) capturing -> UInt8,
    inout __arg: Int,
) -> Int32:
    """Create a new thread without attr and arg."""
    return external_call[
        "pthread_create",
        Int32,
        Pointer[pthread_t],
        Pointer[UInt8],
        fn (Int) capturing -> UInt8,
        Pointer[UInt8],
    ](
        Pointer[pthread_t].address_of(__newthread),
        Pointer[UInt8].get_null(),
        __start_routine,
        Pointer[Int].address_of(__arg).bitcast[UInt8](),
    )


fn pthread_create(
    inout __newthread: pthread_t,
    inout __attr: pthread_attr_t,
    __start_routine: fn (Pointer[Int]) capturing -> UInt8,
) -> Int32:
    """Create a new thread without attr and arg."""
    return external_call[
        "pthread_create",
        Int32,
        Pointer[pthread_t],
        Pointer[pthread_attr_t],
        fn (Pointer[Int]) capturing -> UInt8,
    ](
        Pointer[pthread_t].address_of(__newthread),
        Pointer[pthread_attr_t].address_of(__attr),
        __start_routine,
    )


fn pthread_create(
    inout __newthread: pthread_t,
    __start_routine: fn () capturing -> UInt8,
) -> Int32:
    """Create a new thread without attr and arg."""
    return external_call[
        "pthread_create",
        Int32,
        Pointer[pthread_t],
        fn () capturing -> UInt8,
    ](
        Pointer[pthread_t].address_of(__newthread),
        __start_routine,
    )


fn pthread_join(__th: pthread_t, inout __thread_return: UInt8) -> Int32:
    return external_call["pthread_join", Int32, pthread_t, Pointer[UInt8]](
        __th,
        Pointer[UInt8].address_of(__thread_return),
    )


fn pthread_join(__th: pthread_t) -> Int32:
    return external_call["pthread_join", Int32, pthread_t, Pointer[UInt8]](
        __th,
        Pointer[UInt8].get_null(),
    )


fn pthread_exit(__retval: String) -> UInt8:
    var slen = len(__retval)
    var ptr = Pointer[UInt8]().alloc(slen)

    memcpy(ptr, __retval._as_ptr().bitcast[DType.uint8](), slen)

    return external_call["pthread_exit", UInt8, Pointer[UInt8]](ptr)


fn pthread_detach(__th: pthread_t) -> Int32:
    return external_call["pthread_detach", Int32, pthread_t](__th)
