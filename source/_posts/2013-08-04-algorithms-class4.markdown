---
layout: post
title: "stanford 算法课上 Kosaraju algorithm"
date: 2013-08-04 23:32
comments: true
categories: [algorithms]
---

强连通图的应用场景我就不在这里赘述了。其中[Kosaraju](http://en.wikipedia.org/wiki/Kosaraju's_algorithm)是最常见的一种。

这个也是Stanford 算法课[弟四周的作业](https://class.coursera.org/algo-004/quiz/attempt?quiz_id=57)，现在看来是最难的一道题。那么这里我就给一个我自己的实现了。

这个作业的难度就在于他的输入是一个相当大的数据，处理不好，很容易溢出。那份大数据，我没有留在这里，感兴趣的同学可以自己下载。70多M，实在不适合放在github上面。

[source_code](https://github.com/studentdeng/algorithms_class)

由于是xcode的环境，在g++下是过不去的。。。

