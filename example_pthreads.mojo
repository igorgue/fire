from time import sleep
from pthread import *
from fire import exit


var task_queue: DynamicVector[Int32] = DynamicVector[Int32]()
var queue_size: Int32 = 0

var queue_mutex: pthread_mutex_t = pthread_mutex_t(PTHREAD_MUTEX_TIMED_NP)
var task_cond: pthread_cond_t = pthread_cond_t()


fn main():
    fn worker_thread_func(arg: UInt8) -> UInt8:
        print("Worker thread started")

        sleep(10)

        print("Worker thread finished")

        queue_size -= 1

        print("queue_size:", queue_size)

        return 0

    var workers = StaticTuple[THREAD_POOL_SIZE, pthread_t]()

    for i in range(THREAD_POOL_SIZE):
        var worker = pthread_t()
        workers[i] = worker

        if pthread_create(worker, worker_thread_func) != 0:
            print("Error creating thread")
            return exit(1)

    for i in range(100):
        _ = pthread_mutex_lock(queue_mutex)

        if queue_size == THREAD_POOL_SIZE:
            print("Queue full")
            let val = pthread_mutex_unlock(queue_mutex)
            print("val:", val)
            sleep(1)
            continue

        task_queue.push_back(i)
        queue_size += 1

        _ = pthread_cond_signal(task_cond)
        _ = pthread_mutex_unlock(queue_mutex)
