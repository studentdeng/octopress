---
layout: post
title: "Core Animation基本概念和Additive Animation"
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

`model Layer tree` 中的Layer是我们通常意义说的Layer。当我们修改layer中的属性时,就会立刻修改model layer tree。

	layer.position = CGPointMake(0,0); //这里的修改会直接影响model layer tree

`presentation tree` 是Layer在屏幕中的真实位置。比如我们创建一个动画

{% codeblock lang:objc %}

	  [UIView animateWithDuration:5.0f
                   animations:^{
                     self.animationLabel.center = CGPointMake(200, 400);
                   }];

	//这里用一个Timer print presentLayer的位置。
	CALayer *layer = self.animationLabel.layer.presentationLayer;
  
	NSLog(@"model:%@, presentLayer%@", NSStringFromCGPoint(self.animationLabel.layer.position), NSStringFromCGPoint(layer.position));
	
{% endcodeblock %}

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
	

{%notebox%}
render tree 在apple的render server进程中，是真正处理动画的地方。而且线程的优先级也比我们主线程优先级高。所以有时候即使我们的App主线程busy，依然不会影响到手机屏幕的绘制工作。
{%endnotebox%}

#CADisplayLink

了解[cocos2dx](http://www.cocos2d-x.org/?v=EN)对CADisplayLink一点也不陌生，对APP开发者可能就有一点远，但是facebook的[Pop](https://github.com/facebook/pop)一下子拉近了我们和CADisplayLink的距离。通过设置callback函数，当屏幕刷新的时候，就可以执行我们的代码。当然，我们也可以利用NSTimer 或是GCD来实现类似的功能。但是CADisplayLink是最优的，因为不管是哪种类型的Timer，即使我们的刷新间隔和屏幕刷新保持一致。我们都无法知道系统什么时候刷新屏幕。

{% imgcap /images/core_animation1.png 1-1 NSTimer中每一帧其实只有8ms的时间，如果大于8ms，那么就会丢帧%}

facebook的[Pop](https://github.com/facebook/pop)非常类似UIDynamic，但是我们需要注意一点，相对于传统的model动画来说，CADisplayLink导致部分绘制工作放在了我们APP的地址空间中，也就是说，增大了APP内存，CPU的开销。也更容易遇到性能瓶颈。

{% notebox %}
model layer的这部分绘制是完全在render server，而render server运行在比APP更高优先级的进程中，而这个也意味着会有进程间通讯的开销。传递的数据包括整个render tree还有动画，所以，Apple 并不推荐我们手动commit transaction, Core Animation 默认会在run loop 中提交transaction。
{% endnotebox %}


#UIView animation

Apple 最近在推荐一些Modern APP的设计，其中有一条是希望responsive。比如下面的场景，启动一个动画之后，在动画还没有完成之前取消这个动画。

[下图的相关代码](https://github.com/studentdeng/CoreAnimationAdditiveExample)

{% imgcap /images/core_animation1.gif %}

这里我们看到了3种情况。

* 红色的2个动画之间有一个很大的跳动。
* 绿色的比红色的好一点，没有跳动，但是就像撞到了墙一样，完全丧失了一开始动画的速度。
* 蓝色的的运动更加平滑，有更真实的物理效果。


##UIKit创建的动画，系统是如何理解的

UIKit的动画最后都会通过Core Animation 来实现, 那么当我们修改layer（model layer）的数值时，系统是如何理解并创建动画呢？
比如这里有一个线性的动画，将animationView的坐标从（0，0）移动到（0,500）

{% codeblock lang:objc %}

	  animationView.center = CGPointMake(0, 0);
	  [UIView animateWithDuration:1.0f
                        delay:0
                      options:UIViewAnimationOptionCurveLinear
                   animations:^{
                     animationView.center = CGPointMake(0, 500);
                   } completion:^(BOOL finished) {
                     
                   }];
                   
{% endcodeblock %}
                   
###下面是当我们创建一个UIKit的动画时发生的事情

{% imgcap /images/core_animation9.png %}

* Model：在`animationView.center = CGPointMake(0, 500);`之后会立刻修改`animationView`的model Layer中的`position`的值为（0， 500）。
* Animation：系统的理解就是从原来的model layer的值(0,0)到新的model layer的值(0, 500)创建一个动画。
* Presentation： Presentation就像上面提到的，是表示`animationView`当前在屏幕的真实位置(渲染位置)，因为还没有"动"起来，所以还是(0,0)

{%notebox%}
Animation的部分如果没有明白，可以结合后面的回头再看
{%endnotebox%}


###当我们看到屏幕上面的View移动的时候，发生了下面的事情

这是在0.4s时刻之前的状态。Model Layer的数值没有变化，而Presentation则在变化，和真正的屏幕动画保持一致。

{% imgcap /images/core_animation10.png %}


###在一个animation并没有完成的情况下，再创建一个动画系统是如何理解的呢？

如果我们在**0.5时刻**创建一个reverse动画，`animationView.center = CGPointMake(0, 0);`

{% codeblock lang:objc %}

	  [UIView animateWithDuration:1.0f
                        delay:0
                      options:UIViewAnimationOptionCurveLinear
                   animations:^{
                     animationView.center = CGPointMake(0, 0);
                   } completion:^(BOOL finished) {
                     
                   }];
                   
{% endcodeblock%}

{% imgcap /images/core_animation5.png %}

* Model：的数值会被立刻修改成目标数值(0, 0)
* Animation： 系统的理解是从原来的(0, 500)，创建一个去(0,0)的动画
* Presentation: 基于系统的理解，Presentation layer的数值变成了(0, 500)。1秒中的时间内递减到(0, 0)

到目前为止，我们可以清楚的理解为什么红色的view会有一个大的跳跃，在我们这里的理解就是presentation layer的一个不连续的修改。

##绿色的动画效果原因

在上面的基础之前，绿色的就可以简单说一些

{% imgcap /images/core_animation6.png %}

* Model 这里还是和之前一样，表示目标值
* Animation：系统的理解是从当前的动画位置开始，也就是 (0, 150)开始创建一个1秒的动画到(0,0)
* Presentation 和我们的预期一样。

{% imgcap /images/core_animation2.png linear animation 图中的颜色和本文的颜色无关，只是表示2个动画的stage%}
{% imgcap /images/core_animation3.png EseInOut animation 图中的颜色和本文的颜色无关，只是表示2个动画的stage%}

可以看出来2个动画相接的曲线不平滑，而造成这个不平滑的原因在于把之前的动画覆盖了, 丢掉了之前动画的速度，如果要实现一个更一般化的解决方案，我们很自然的想到了动画合成。

##蓝色的动画原因

蓝色的动画比较复杂，使用了Core Animation中的additive属性，动画被设置成相对的，那么就和动画具体的位置无关。最后还合成了2个动画。

首先，解释一下什么是相对的动画。

{% imgcap /images/core_animation7.png %}

这里很容易看到，view的真实位置是Animation 的值 + Model的值。系统的理解就是相对目标值(0, 500)来说，创建一个从-500 到 0 的动画。

其次，相比之前的动画，在0.6时刻（为了方便计算，把之前的0.5时刻移动到了0.6时刻）并没有删除掉之前的动画，而是添加了一个新的动画Animation2。也就是一个相对目标值(0,0)来说，创建一个从500到0的动画。整个运动变成了2个动画的合成。

{% imgcap /images/core_animation8.png %}

{%notebox%}
Animation2的duration修改了，在demo code里面并没有修改 ：）
{%endnotebox%}

这里，我们就得到了一个一般化的解决方案。

{% imgcap /images/core_animation4.png 图中的颜色和本文的颜色无关，只是表示2个动画的stage%}


##iOS8的改动

Core Animation 有一个additive的属性实际上已经存在很久了，但是却很少被大家知道（我自己也是）。在iOS8 之前，UIKit创建的动画默认是不使用additive的，而在iOS8之后，默认是Additive的。有兴趣的同学可以试一试download [demo code](https://github.com/studentdeng/CoreAnimationAdditiveExample)用Xcode6(这会还是beta)并打开macro`#define USING_UIKIT 1`看一下新的UIKit animation效果。

在了解背后的机制之后，其中的变化也很容易理解。

1. completion block 的调用变了。之前在创建一个UIKit的动画时候，会覆盖掉上一个动画，也就是删除再添加一个新动画，而现在前一个动画会在真正执行完毕才会执行completion block。
2. 不是所有的动画都支持additive


......



#参考

* [《WWDC2014 236_building_interruptible_and_responsive_interactions》](https://developer.apple.com/videos/wwdc/2014/?id=236)
* [《Core Animation Programming Guide:Core Animation Basics》](https://developer.apple.com/library/ios/documentation/cocoa/conceptual/coreanimation_guide/CoreAnimationBasics/CoreAnimationBasics.html#//apple_ref/doc/uid/TP40004514-CH2-SW3)
* [《additive-core-animation》](http://kxdx.org/additive-core-animation/)




