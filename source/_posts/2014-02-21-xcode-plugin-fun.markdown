---
layout: post
title: "Xcode5 Plugins 开发简介"
date: 2014-02-21 13:13
comments: true
categories: [plugin, iOS]
---

这篇文章介绍如何给Xcode5开发插件。如果之前了解iPhone & iPad 开发，那么下面的内容对您非常熟悉。最后我们会开发一个简单的插件，记录Xcode开发中Building的时间。

#准备工作

首先编写一个Plugin还是需要不少额外的配置，这里推荐[Xcode Plugin Template](https://github.com/kattrali/Xcode5-Plugin-Template)。用这个templage来帮助我们开发Plugin。

另外，编写插件和之前的iPhone or Mac上的APP不太一样。从某种意义上来说就是用Xcode调试Xcode。所以这里需要额外配置一点东西。

* 修改Scheme

![image](http://studentdeng.github.io/images/xcode_plugin1.png)

* Executable 选择Xcode.app

![image](http://studentdeng.github.io/images/xcode_plugin2.png)

当我们Build & Run Project的时候就可以看到启动了一个新的Xcode进程，当然除了Xcode， Mail或是其他程序我们都可以调试。

#如何编写插件

因为Apple至今并没有公开Xcode Plugin的文档，所以我们需要通过一些其他方法寻找思路。

{% codeblock lang:objc %}

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationLog:) name:nil object:nil];
	
	- (void)notificationLog:(NSNotification *)notify
	{
    	NSLog(@"%@", notify.name);
	}
	
{% endcodeblock %}

这里稍微有一点特殊，参数notificationName 设为nil，下面是Apple的文档，不是很清楚。

	notificationName If you pass nil, the notification center doesn’t use a notification’s name to decide whether to deliver it to the observer.

但是目前来看，似乎可以看到所有的通知。当然绝大部分是重复的，对我们没有意义。很幸运最后我们找到了2个通知是我们需要的，下面的代码，已经做了过滤。

{% codeblock lang:objc %}
	- (void)notificationLog:(NSNotification *)notify
	{
    	if (![notify.name hasPrefix:@"IDEBuildOperation"]) {
        	return;
    	}
    
    	NSLog(@"%@", notify.name);
	}
	
{% endcodeblock %}
	
这2个通知分别是

* IDEBuildOperationWillStartNotification
* IDEBuildOperationDidStopNotification

这个我们不得不赞一下cocoa的命名方式，大家都可以猜出这2个通知的含义。剩下的事情就很简单了。统计build时间。

#最后

这是[项目源代码](https://github.com/studentdeng/Buddy)。有兴趣的同学可以玩玩，看一下自己的编译时间有多长。另外最终的代码中还增加了2个小的features。

* 查看当前打开Xcode的人数
* 查看自己打开Xcode专注的时间有多长，这个时间是当Xcode被focus的时候才统计，另外不足1分钟不计算在内。

Have fun！



