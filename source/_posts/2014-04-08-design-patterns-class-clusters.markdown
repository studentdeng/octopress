---
layout: post
title: "Design Patterns in iOS — Class Clusters"
date: 2014-04-08 14:49
comments: true
categories: [iOS, design_patterns]
---

我对设计模式一直都是一个若有若无的感觉，特别是在手机端开发，觉得用处不是很大，认为设计模式是为了大规模团队合作，分工才能体现出效果。设计模式可以通过分不同的“层”让大家协同开发，相互之间不产生影响。但是最近看法有点改变，觉得还是需要多少了解一些。

天天使用的framework确实是一个庞大的项目，从framework的设计中可以找到很多设计模式的影子，而且还是一个很好的生产化的例子。这里先介绍 Class Clusters

Class Clusters 几乎涉及到iOS日常的所有开发过程中，也可能正是这样，导致我们很容易把它彻底遗忘。这里就拿最常用的 NSString 来讲。

{% codeblock lang:objc %}
  NSString *string1 = @"helloworld";
  NSString *string2 = [[NSString alloc] initWithFormat:@":%@", @"helloworld"];
  NSString *string3 = [NSHomeDirectory() stringByAppendingPathComponent:string1];
  NSTextStorage *storage = [[NSTextStorage alloc] initWithString:string1];
  NSString *string4 = [storage string];
  
  NSLog(@"%@", [[string1 class] description]);
  NSLog(@"%@", [[string2 class] description]);
  NSLog(@"%@", [[string3 class] description]);
  NSLog(@"%@", [[string4 class] description]);
{% endcodeblock %}

不知道有多少人试过哈，string3的返回还是让我吃了一惊。下面的结果是在Xcode5.1 SDK7.1 下的结果。

	__NSCFConstantString
	__NSCFString
	NSPathStore2
	NSBigMutableString
	

通过上面的方法创建的 NSString 最后都产生了不同的子类。有人可能会奇怪为什么需要不同的 NSString。因为对于大部分的以阅读内容为主的App来讲，很大部分资源消耗在了字符串处理上面（存储，解析，比较等等），所以对于字符串的存储需要有不同的方式来满足不同的情况，这样才能有性能上的提高。

{% notebox %}
设想一下，在这些场景上面，如果Apple直接把这些类扔给开发者，会有什么问题呢？

那么开发者需要自己在不同的场景决定使用不同的子类，不仅学习成本提高，而且也容易生成性能不太好的代码。
现在简单的 NSString 就可以直接覆盖上面的所有场景。而且随着iOS的软硬件的后续开发，开发者还可以在不修改代码的情况下获得性能提升。
{% endnotebox %}

既然看到了它的强大之处，那么就开始了解吧。
既然这是第一篇DesignPattern那么就从最简单开始 ：)

##Abstract Classes

这里引用一下Mike的内容

{% blockquote Mike Ash https://mikeash.com/pyblog/friday-qa-2010-03-12-subclassing-class-clusters.html Friday Q&A 2010-03-12: Subclassing Class Clusters %}
An abstract class is a class which is not fully functional on its own. It must be subclassed, and the subclass must fill out the missing functionality.

An abstract class is not necessarily an empty shell. It can still contain a lot of functionality all on its own, but it's not complete without a subclass to fill in the holes.
{% endblockquote %}

Abstract Class 的概念很简单，类中所有的方法不需要全部有具体的实现，相当于定义了很多的接口。比如一开始的 NSString

##Class Clusters

{% blockquote Mike Ash https://mikeash.com/pyblog/friday-qa-2010-03-12-subclassing-class-clusters.html Friday Q&A 2010-03-12: Subclassing Class Clusters %}
A class cluster is a hierarchy of classes capped off by a public abstract class. The public class provides an interface and a lot of auxiliary functionality, and then core functionality is implemented by private subclasses. The public class then provides creation methods which return instances of the private subclasses, so that the public class can be used without knowledge of those subclasses.
{% endblockquote %}

Clusters的角色不仅要实现 Abstract Class 的方法，还需要自己实现自己的特殊化需求。Abstract Class 负责提供一个“外壳”，真正“干活”的就是Cluster class。这样外部就只需要了解Abstract Class就可以了。

##NSString Benefits

比如 __NSCFConstantString 负责 const string，类似 @"helloworld"这样的字符串。这样的字符串有一个特点，不会被修改，当真正处理的时候，可以分配大小合适的内存，甚至可以分配在只读 data segment上面，而不需要分配在堆上面，如果有相同的字符串引用就可以完全赋值相同的地址。那么在retainCount上面的处理也就和其他字符串处理有很大不同。

NSPathStore2 看上去是处理有Path相关的字符串，因为没有源代码，这里我们可以大胆猜测一下，path相关的主要是做字符串的拼接操作，而这些字符串通常很长，占用空间大，但是重复的概率缺很高，那么就可以缓存一些字符串，这样可以减少一些内存的分配释放开销。

##How to use 

{% blockquote Apple Develpoer Document https://developer.apple.com/library/mac/documentation/general/conceptual/devpedia-cocoacore/ClassCluster.html Cocoa Core Competencies %}
The class cluster architecture involves a trade-off between simplicity and extensibility: Having a few public classes stand in for a multitude of private ones makes it easier to learn and use the classes in a framework but somewhat harder to create subclasses within any of the clusters.
{% endblockquote %}

就像Apple文档中提到的，Class Cluster 是在简单和扩展性上面做了一个妥协。Class Clusters 的子类化比较麻烦，而且也看上去也非常trick,Apple 更推荐的方法是用组合的方法来扩展。

大家都知道设计模式有一个非常重的坑就是被过渡设计。Class Cluster 可以帮我们

* 减少了if else 这样缺乏扩展性的代码
* 增加新功能支持不影响其他代码

那么这个非常适合应用在适配上面，比如不同屏幕的适配，不同厂家可能的不同的需求。

{% codeblock lang:objc %}

+ (id)alloc {
    if ([self class] == [SFSSearchTVC class]) {
        if ([UIDevice currentDevice] systemMajorVersion] < 7) {
            return [SFSSearchTVC6 alloc];
        } else if ([UIDevice currentDevice] systemMajorVersion] == 7) {
            return [SFSSearchTVC7 alloc];
        }
    }
    
    return [super alloc];
}
{% endcodeblock %}

上面是代码来自[BJ Miller's blog A Cluster to Remove Clutter](http://bjmiller.me/post/69043165385/a-cluster-to-remove-clutter)
是用于适配iOS6，iOS7的简单例子。

##Conclusion

很多设计模式都很像，也很容易糊涂，比如工厂模式和Class Clusters在某些地方就很类似，我自己也并不能很好的分清楚。
设计模式的本质是为了解耦。不管使用哪个设计模式，我们最后追求的都是简单、容易维护和扩展的代码。


