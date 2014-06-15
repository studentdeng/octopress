---
layout: post
title: "auto_layout"
date: 2014-06-13 18:28
comments: true
categories: [iOS]
---

#前言

最近Apple的动作还是蛮多的，其中有3条很有意思。

*  iOS8中设备旋转，布局的变化
*  可能的iPhone6屏幕的变化，iPhone和iPad Mac开发越来越趋于统一
*  Xcode6中Interface Builder的变化（IB中显示自定义View）

cocoa touch 开发中适配各种屏幕尺寸已经是能够预测的了，那么跟进Auto layout 也就是必备技能了，未来面试中应该也是主流问题了。

在一开始使用AutoLayout的时候，和之前的使用Frame描述位置还是有很大的不同，而且一开始的时候很容易遇到一些奇怪的异常。但是在了解AutoLayout之后，就会发现这是一个非常非常elegant的布局解决方案。

#传统的布局是如何做的

一开始接触iOS的时候，我还是蛮喜欢他的布局系统。简单来说，一个图像，我们通过中心点坐标，旋转角度和轮廓大小来定义他在窗口中的位置

这里的坐标和笛卡尔坐标系不同的是Y的方向

![1-1 The default layer geometries for iOS](/Users/curer/Desktop/QQ20140615-1.png)

这里表示了anchorPoint含义，用于表示position相对bounds的位置，比如（0.5, 0.5）表示中心，（0,0）表示左上角
![1-2 The default unit coordinate systems for iOS](/Users/curer/Desktop/QQ20140615-2.png)


下面表示了frame bounds position anchorPoint之间的关系，你可能觉得这个anchorPoint似乎没有什么用

![1-3 How the anchor point affects the layer’s position property](/Users/curer/Desktop/QQ20140615-3.png)
![1-4 How the anchor point affects the layer’s position property](/Users/curer/Desktop/QQ20140615-7.png)

但是当我们旋转一个View的时候，好处就来了

![1-5 How the anchor point affects the layer’s position property](/Users/curer/Desktop/QQ20140615-4.png)
![1-6 How the anchor point affects the layer’s position property](/Users/curer/Desktop/QQ20140615-5.png)


#传统布局的问题

传统布局是非常高效的，组合各种变化，可以轻易得实现任意的2D动画，当然也可以轻易的解决静态的布局问题。但是在面对多个屏幕，屏幕旋转时，甚至是单个屏幕，但是需要在2个View 中间动态增加一个View的时候显得非常繁琐。网上有很多例子，比如[beginning-auto-layout-part-1-of-2](http://www.raywenderlich.com/20881/beginning-auto-layout-part-1-of-2)，或是大家在平时工作中遇到的3.5inch和4inch屏幕之间的适配。

#AutoLayout

AutoLayout使用非常简单Xcode的支持也非常直观，但是对新手却非常难用（实际上很好用）。新手一开始很容易遇到一大堆的异常，crash在main函数里面，让人非常沮丧。但是在了解AutoLayout的一些原理之后变很容易理解了。

##constraints 约束

AutoLayout 是一个描述各种约束的行为，比如，一个View 距离父View上边距多少，相邻之间的间隔，各个View之间的宽高关系等等。这一系列的条件就是为了最终确定之前提到的传统布局中需要的东西，这个View的大小，位置。所以，当我们设置的条件不足，或是条件冲突时，就会产生异常。

##Intrinsic Content Size 固有大小

在使用AutoLayout的时候，UILabel 我们只需要设定他的position，不需要设置宽高，而一个自定义的UIView，我们不仅仅需要位置，还需要设定宽高，这是为什么呢？

每一个View 都有一个特别的属性叫做Intrinsic Content Size，这个可以理解成是一个View的最合适而且最小的宽度和高度。对于UILabe来说，就是至少得把我设定的文字都显示完整吧，所以系统只需要知道UILabel的位置。而UIView的Intrinsic Content是（0，0）所以需要设置UIView的宽高（或是设定周围的边距等等其他关系可以让系统知道这个View应该多宽，多高）。而Intrinsic Content Size，也是未来自定义View显示到Xcode中必须设置的属性之一。

##The Layout Process

###update constraints

###layout views



##Compression Resistance and Content Hugging

##Alignment Rect




#参考

* Core Animation Programming Guide:Core Animation Basics
* [Advanced Auto Layout Toolbox-objc.io](http://www.objc.io/issue-3/advanced-auto-layout-toolbox.html)



