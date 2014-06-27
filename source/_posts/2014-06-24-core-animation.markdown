---
layout: post
title: "Core Animation基本概念和iOS8新动画改动"
date: 2014-06-24 19:21
comments: true
categories: [iOS]
---

[上一篇《AutoLayout 相关概念介绍和动画demo》](http://studentdeng.github.io/blog/2014/06/13/auto-layout/)提到了一些Core Aniamtion的基础知识，这篇依然介绍一些基本概念，最后提到一点iOS8的动画改动。

#一些基本概念

说到Core Animation 不能不说Layer, 一个个Layer通过tree的结构组织起来，在Display的过程中实际上有3种Layer tree。

* model layer tree
* presentation tree
* render tree

`model Layer tree` 中的Layer是我们通常意义说的Layer。当我们修改layer中的属性时,就会立刻修改model layer tree。是动画的目标值。

	layer.position = CGPointMake(0,0); //这里的修改会直接影响model layer tree

`presentation tree` 是Layer在屏幕中的真实位置。比如我们创建一个动画

	  [UIView animateWithDuration:5.0f
                   animations:^{
                     self.animationLabel.center = CGPointMake(200, 400);
                   }];

	//这里用一个Timer print presentLayer的位置。
	CALayer *layer = self.animationLabel.layer.presentationLayer;
  
	NSLog(@"model:%@, presentLayer%@", NSStringFromCGPoint(self.animationLabel.layer.position), NSStringFromCGPoint(layer.position));
	

下面是屏幕输出结果

	model:{73.5, 155.5}, presentLayer{73.5, 155.5}
	model:{200, 400}, presentLayer{73.559769, 155.61552}//开始动画
	model:{200, 400}, presentLayer{73.814095, 156.10709}
	model:{200, 400}, presentLayer{74.267357, 156.98315}
	...
	...
	...
	model:{200, 400}, presentLayer{199.99576, 399.99182}
	model:{200, 400}, presentLayer{200, 400}
	


`render tree` 在apple的render server进程中，是真正处理动画的地方。而且线程的优先级也比我们主线程优先级高。所以有时候即使我们的App主线程busy，依然不会影响到手机屏幕的绘制工作。

#CADisplayLink

了解cocos2dx对CADisplayLink一点也不陌生，对APP开发者可能就有一点远，但是facebook的Pop一下子拉近了我们和CADisplayLink的距离。通过设置callback函数，当屏幕刷新的时候，就可以执行我们的代码。当然，我们也可以利用NSTimer 或是GCD来实现类似的功能。但是CADisplayLink是最优的，因为不管是哪种类型的Timer，即使我们的刷新间隔和屏幕刷新保持一致。我们都无法知道系统什么时候刷新屏幕。

![image](/Users/yuguang/Desktop/QQ20140627-1@2x.png)

{% imgcap /images/core_animation_1.png 1-1 NSTimer中每一帧其实只有8ms的时间，如果大于8ms，那么就会丢帧%}

UIDynamic和facebook的 pop 看上去非常类似，但是我们需要注意一点，相对于传统的model动画来说，CADisplayLink导致部分绘制工作放在了我们APP的地址空间中，也就是说，增大了APP内存，CPU的开销。也更容易遇到性能瓶颈。

{% notebox %}
model layer的这部分绘制是完全在render server，而render server运行在比APP更高优先级的进程中，而这个也意味着会有进程间通讯的开销。传递的数据包括整个render tree还有动画，所以，Apple 并不推荐我们手动commit transaction, Core Animation 默认会在run loop 中提交transaction。
{% endnotebox %}


#Additive Animation

Apple 最近在推荐一些Model APP的设计，那么


