---
layout: post
title: "Stanford 算法课 part 2 Scheduling"
date: 2013-09-16 20:46
comments: true
categories: [algorithms]
---
当一个人每天都有做不完的事情时，不知道大家又没有这种感觉。各种各样的事情，各种deadline，甚至是一些无关紧要的琐碎事情也会不断的在大脑中被回想，而且还是反复的，没有任何理由的会冒出来。对像我这样非常懒惰的人来说，这就是一个非常致命的打击，因为我需要中断当前的事情，这会让我多消耗不少脑力。。。

这应该算是时间管理中的一部分，如何给自己安排任务。人的大脑和电脑的工作模式还是有一些类似的，比如如果一直不断的记录一大堆事情而不是执行，那么就会影响到他们的工作效率。同样，如果重要的事情不作，最后也会不断的在大脑里面被回想，而造成效率降低。

在我看来，解决这些回想问题最关键的事情就是把这些东西搞定，这样才能把大脑清空，然后去做那些更加有意义的事情。

最近再跟algorithm part2里面正好有一个scheduling application的东西，挺有意思的。这里记录一下。

#问题描述

##Setup
scheduling 的基本模型是有一个shared resource，比如CPU。但是有许多jobs，比如很多线程，需要使用CPU才能运行。

##Question
我们应该如何调度这个jobs的顺序，哪一个job优先于其他job执行，从而让整个计划执行时间最少。

##Assume
为了更清楚的定义数学模型，每一个job有2个维度。

* weight 重要性
* length 时间

##Defintion

Completion time。 第J个任务的完成时间（Completion time）Cj 是 （任务J之前的等待时间 + 任务J的length）* 任务J的weight

#思路

这里根据直觉可以很明显的知道 我们需要把重要的事情放在前面，把时间短的事情放置在前面，这样可以很快的打一个勾勾，清空大脑中的这个任务。也就是说Cj 和 Wj 正相关，和 Lj负相关。但是总是有一些事情让人欲罢不能，就是那些很重要，而且做起来还比较费劲，时间花费长的事情，和那些不重要但是时间花费短的事情。真实世界的事情太复杂，还是回到我们这个简单的模型中。

一种常见的思维是设法将问题转换成之前我们已经解决了的思路之中，所以很容易想到我们需要找到单位长度中最重要的事情先做。因为我们的这个模型的任务调度不是抢占式的么。

将上面的单位时间的含义翻译过来就是 wj / lj。 也就是我们的调度程序将按照w / l的值，从大到小排列
![scheduling 1](https://raw.github.com/studentdeng/studentdeng.github.com/master/images/algo_schema_01.png)

这里我们假定任务i > j。这个图则表示这2个任务相连在一起，stuff表示之前的任务，more stuff表示之后的任务。

![scheduling 2](https://raw.github.com/studentdeng/studentdeng.github.com/master/images/algo_schema_02.png)

而这里，我们做一次任务i、j的交换，就像这样

![image](https://raw.github.com/studentdeng/studentdeng.github.com/master/images/algo_schema_03.png)

那个这2个scheduling中，i,j之前的任务的完成时间不会变，之后的任务完成时间也不会变。那么受到影响的只是任务i，j。

![image](https://raw.github.com/studentdeng/studentdeng.github.com/master/images/algo_schema_04.png)

那么这里显然scheduling 2 也就是后面的那张图的顺序比第一个要小。

然后我们可以想象最后的任务流程，就如果冒泡排序一样，一次次的比较把相对重要的数据一次次的放置到前面。

而当所有相邻的任务都按照这样的规则排列完毕后，得到的就是一个 wj / lj 的从大到小的序列。

