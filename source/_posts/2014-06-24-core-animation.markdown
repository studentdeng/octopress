---
layout: post
title: "Core Animation"
date: 2014-06-24 19:21
comments: true
categories: [iOS]
---

这一篇是[AutoLayout 相关概念介绍和动画demo](http://studentdeng.github.io/blog/2014/06/13/auto-layout/)的姊妹篇，这里主要说明Display的过程。

#一些基本概念

说到Core Animation 不能不说Layer, 一个个Layer通过tree的结构组织起来，在Display的过程中实际上有3种Layer tree。而这3种Tree的设计结构不仅仅在Core Animation中，WPF/SL 也是存在这3中Layer Tree。

* model layer tree
* presentation tree
* render tree

`model Layer tree` 中的Layer是我们通常意义说的Layer。当我们修改layer中的属性时,就会立刻修改model layer tree。

	layer.position = CGPointMake(0,0); //这里的修改会直接影响model layer tree

`presentation tree` 是动画在屏幕中的真实位置。比如我们创建一个动画

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
	
根据上面的例子，可以很容易看出区别，如果从动画的角度来看model Layer tree 设定的是`目标`值， `presentation tree`则是动画在屏幕上面真正的位置。


