from time import sleep
from pthread import *
from fire import exit

alias THREAD_SIZE = 100


fn main():
    var workers = StaticTuple[THREAD_SIZE, pthread_t]()

    var i = 0
    while i < THREAD_SIZE:
        workers[i] = pthread_t()

        fn thread_func(arg: Int) -> UInt8:
            print("worker id:", i, "started")

            sleep(1)

            print("finished")

            return pthread_exit("bye")

        if pthread_create(workers[i], thread_func) != 0:
            print("error creating thread, retrying")

            i -= 1

            continue

        # _ = pthread_detach(workers[i])

        i += 1

    var j = 0
    while j < THREAD_SIZE:
        _ = pthread_join(workers[j])

        j += 1


# from time import sleep
# from pthread import *
# from fire import exit
#
#
# var task_queue: DynamicVector[Int32] = DynamicVector[Int32]()
# var queue_size: Int32 = 0
#
# var task_cond: pthread_cond_t = pthread_cond_t()
#
#
# fn main():
#     fn worker_thread_func(arg: UInt8) -> UInt8:
#         print("Worker thread started")
#
#         sleep(1)
#
#         print("Worker thread finished")
#
#         print("queue_size:", queue_size)
#
#         return pthread_exit("bye")
#
#     var workers = StaticTuple[THREAD_POOL_SIZE, pthread_t]()
#
#     for i in range(THREAD_POOL_SIZE):
#         var worker = pthread_t()
#         workers[i] = worker
#
#         if pthread_create(worker, worker_thread_func) != 0:
#             print("Error creating thread")
#             return exit(1)
#
#     for i in range(100):
#         _ = pthread_mutex_lock(queue_mutex)
#
#         # if queue_size == THREAD_POOL_SIZE:
#         # pass
#         # print("Waiting for a free worker thread")
#         #
#         # if pthread_mutex_unlock(queue_mutex) == 0:
#         #     _ = pthread_cond_wait(task_cond, queue_mutex)
#         #     _ = pthread_mutex_lock(queue_mutex)
#
#         # queue_size -= 1
#
#         _ = pthread_cond_signal(task_cond)
#         _ = pthread_mutex_unlock(queue_mutex)
#
