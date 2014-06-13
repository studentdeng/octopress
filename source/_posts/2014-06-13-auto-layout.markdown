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

2张图片表示坐标之间的关系。

![123](/Users/yuguang/Desktop/QQ20140613-1@2x.png)

在这样的一个坐标系下，组合各种变化，可以轻易得实现任意的2D动画。



