from memory import memset_zero

alias THREAD_POOL_SIZE = 10
alias __SIZEOF_PTHREAD_MUTEX_T = 40  # value for x86_64

alias PTHREAD_MUTEX_TIMED_NP = 0
alias PTHREAD_MUTEX_RECURSIVE_NP = 1
alias PTHREAD_MUTEX_ERRORCHECK_NP = 2
alias PTHREAD_MUTEX_ADAPTIVE_NP = 3

var task_queue: StaticTuple[THREAD_POOL_SIZE, Int32] = StaticTuple[
    THREAD_POOL_SIZE, Int32
](0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
var queue_size: Int32 = 0

var queue_mutex: pthread_mutex_t = pthread_mutex_t(PTHREAD_MUTEX_TIMED_NP)
var task_cond: pthread_cond_t = pthread_cond_t()


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
        let prev_ptr = Pointer[__pthread_list_t].alloc(1)
        let next_ptr = Pointer[__pthread_list_t].alloc(1)

        memset_zero(prev_ptr, 1)
        memset_zero(next_ptr, 1)

        return Self {
            __data: __pthread_mutex_s(
                0,
                0,
                0,
                0,
                __kind,
                0,
                0,
                __pthread_list_t(
                    prev_ptr,
                    next_ptr,
                ),
            ),
            __size: StaticTuple[__SIZEOF_PTHREAD_MUTEX_T, Int8](
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            ),
            __align: 0,
        }


@value
@register_passable("trivial")
struct __pthread_list_t:
    var __prev: Pointer[__pthread_list_t]
    var __next: Pointer[__pthread_list_t]


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
            __size: StaticTuple[__SIZEOF_PTHREAD_MUTEX_T, Int8](
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            ),
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


fn pthread_mutex_lock(__mutex: pthread_mutex_t) -> Int32:
    return __ret
