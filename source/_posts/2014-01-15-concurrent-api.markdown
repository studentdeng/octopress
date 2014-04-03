---
layout: post
title: "翻译 并发编程：API 和 挑战"
date: 2014-01-15 20:21
comments: true
categories: [iOS, translation]
---

并发（[Concurrency](http://en.wikipedia.org/wiki/Concurrency_%28computer_science%29)）描述了一个同时运行多个任务的概念。他可以在单核设备上通过分时的方式实现，或者如果多个CPU则会真正的并行。

OSX和iOS提供了多种不同的API来实现并发编程。每一个API都有不同的功能和局限，适用于不同的任务。他们有不同的抽象层次。我们可以操作底层API，但是这也意味着我们需要做很多事情来保证正确。

并发编程是非常困难的，里面有很多陷阱。而且很容易被忘记，特别是我们使用API，比如 GCD 或者 NSOperationQueue。这篇文章来会总体介绍在iOS和OSX上面的不同的并发API，然后深入一点并发编程里面的固有的，每个API所独有的挑战。

#OSX和iOS上面的并发API

Apple为移动和桌面操作系统提供了相同的并发编程API。这里我们会看一下pthread和NSThread。Grand Central Dispatch, NSOperationQueue 和 NSRunLoop。技术上来说，run loops 有一点奇怪。因为他们并不是真正的并发。但是他和这篇文章的主旨很接近，所以还是值得深入了解的。

我们从底层API开始，然后到上层API。我们这样做，因为上层的API是通过底层的API实现的。当然，在实际中，我们需要反过来考虑：用最上面的一层抽象搞定事情会简单很多。

你可能想知道为什么我们这个坚持推荐使用高抽象层会让并发编程代码简单。你可以阅读这篇文章的第二部分。也可以看 Peter Steinberger 的 [线程安全](http://www.objc.io/issue-2/thread-safe-class-design.html)文章。

#线程

[线程](http://en.wikipedia.org/wiki/Thread_%28computing%29)是进程的子单元，被操作系统独立调度执行。事实上，所有的并发API都基于线程。背后实际上的确是真的，不管是GCD还是operation queues。

多线程可以在同一个时间执行，即时在单核的CPU上。（或是至少看上去是在同时）。操作系统赋予每个线程一个时间片，用户看上去多个任务就像是在同时执行一样。如果CPU是多核的，那么多个线程就可以真正的并发执行，因此总的执行时间就会减少。

你可以使用[CPU strategy view](https://developer.apple.com/library/mac/documentation/DeveloperTools/Conceptual/InstrumentsUserGuide/AnalysingCPUUsageinYourOSXApp/AnalysingCPUUsageinYourOSXApp.html)Instruments中的几个工具来深入了解一下你的代码或者是framework代码在多核下是如何调用和执行的。

这里面有一个非常重要的需要记住的是你对什么时候执行代码，执行那段代码无能为力，执行多长时间，什么时候会被暂停去执行别的任务，也是不知道的。这个线程调度的技术非常强大。然而，也带来了非常大的复杂性，后面会提到。

让我们把这个复杂的情况暂时放在一边。你可以使用pthread API，或是其他的Objective-C封装的代码，NSThread去创建自己的线程。这里有一个简单的代码，查找100W和数中的最小和最大的数。使用了4个线程并发执行。这就是一个非常好的例子，告你你最好不要直接使用pThread。

    struct threadInfo {
        uint32_t * inputValues;
        size_t count;
    };

    struct threadResult {
        uint32_t min;
        uint32_t max;
    };

    void * findMinAndMax(void *arg)
    {
        struct threadInfo const * const info = (struct threadInfo *) arg;
        uint32_t min = UINT32_MAX;
        uint32_t max = 0;
        for (size_t i = 0; i < info->count; ++i) {
            uint32_t v = info->inputValues[i];
            min = MIN(min, v);
            max = MAX(max, v);
        }
        free(arg);
        struct threadResult * const result = (struct threadResult *) malloc(sizeof(*result));
        result->min = min;
        result->max = max;
        return result;
    }

    int main(int argc, const char * argv[])
    {
        size_t const count = 1000000;
        uint32_t inputValues[count];
        
        // Fill input values with random numbers:
        for (size_t i = 0; i < count; ++i) {
            inputValues[i] = arc4random();
        }
        
        // Spawn 4 threads to find the minimum and maximum:
        size_t const threadCount = 4;
        pthread_t tid[threadCount];
        for (size_t i = 0; i < threadCount; ++i) {
            struct threadInfo * const info = (struct threadInfo *) malloc(sizeof(*info));
            size_t offset = (count / threadCount) * i;
            info->inputValues = inputValues + offset;
            info->count = MIN(count - offset, count / threadCount);
            int err = pthread_create(tid + i, NULL, &findMinAndMax, info);
            NSCAssert(err == 0, @"pthread_create() failed: %d", err);
        }
        // Wait for the threads to exit:
        struct threadResult * results[threadCount];
        for (size_t i = 0; i < threadCount; ++i) {
            int err = pthread_join(tid[i], (void **) &(results[i]));
            NSCAssert(err == 0, @"pthread_join() failed: %d", err);
        }
        // Find the min and max:
        uint32_t min = UINT32_MAX;
        uint32_t max = 0;
        for (size_t i = 0; i < threadCount; ++i) {
            min = MIN(min, results[i]->min);
            max = MAX(max, results[i]->max);
            free(results[i]);
            results[i] = NULL;
        }
        
        NSLog(@"min = %u", min);
        NSLog(@"max = %u", max);
        return 0;
    }
    
NSThread是


