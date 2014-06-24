---
layout: post
title: "AutoLayout 相关概念介绍和动画demo"
date: 2014-06-13 18:28
comments: true
categories: [iOS]
---

#前言

最近Apple的动作还是蛮多的，其中有3条很有意思。

*  iOS8中设备旋转，布局的变化
*  可能的iPhone6屏幕的变化，iPhone和iPad Mac开发越来越趋于统一
*  Xcode6中Interface Builder的变化（IB中显示自定义View）

cocoa touch 开发中适配各种屏幕尺寸已经是能够预测的了，那么跟进AutoLayout 也就是必备技能了。

#传统的布局是如何做的

一开始接触iOS的时候，我还是蛮喜欢他的布局系统。简单来说，一个图像，我们通过中心点坐标，旋转角度和轮廓大小来定义他在窗口中的位置

这里的坐标和笛卡尔坐标系不同的是Y的方向

{% imgcap /images/autolayout-1.png 1-1 The default layer geometries for iOS%}

这里表示了anchorPoint含义，用于表示position相对bounds的位置，比如（0.5, 0.5）表示中心，（0,0）表示左上角

{% imgcap /images/autolayout-2.png 1-2 The default unit coordinate systems for iOS%}


下面表示了frame bounds position anchorPoint之间的关系，你可能觉得这个anchorPoint似乎没有什么用

{% imgcap /images/autolayout-3.png 1-3, 1-4  How the anchor point affects the layer’s position property%}
{% imgcap /images/autolayout-7.png%}

但是当我们旋转一个View的时候，好处就来了

{% imgcap /images/autolayout-4.png 1-5 , 1-6 How the anchor point affects the layer’s position property%}
{% imgcap /images/autolayout-5.png%}


#传统布局的问题

传统布局是非常高效的，组合各种变化，可以轻易得实现任意的2D动画，当然也可以轻易的解决静态的布局问题。但是在面对多个屏幕，屏幕旋转时，或是需要在2个View 中间动态增加一个View的时候显得非常繁琐。需要不断的写一些计算距离，位置的代码（甚至还有一些magic number）。网上有很多例子，比如[beginning-auto-layout-part-1-of-2](http://www.raywenderlich.com/20881/beginning-auto-layout-part-1-of-2)，或是大家在平时工作中遇到的3.5inch和4inch屏幕之间的适配。

#AutoLayout

AutoLayout使用非常简单，Xcode的支持也非常直观。但是因为和之前的方式有很大的不同，新手一开始很容易遇到一大堆的异常，crash在main函数里面，让人非常沮丧。但是在了解AutoLayout之后，就会发现这是一个非常非常elegant的布局解决方案，也很容易理解为什么crash，以及应该如何debug。

##constraints 约束

AutoLayout 是一个描述各种约束的行为，比如，一个View 距离父View上边距多少，相邻之间的间隔，各个View之间的宽高关系等等。这一系列的条件就是为了最终确定之前提到的传统布局中需要的东西，这个View的大小，位置。所以，当我们设置的条件不足，或是条件冲突时，就会产生异常。

##Intrinsic Content Size 固有大小

在使用AutoLayout的时候，UILabel 我们只需要设定他的position，不需要设置宽高，而一个自定义的UIView，我们不仅仅需要位置，还需要设定宽高，这是为什么呢？

每一个View 都有一个特别的属性叫做Intrinsic Content Size，这个可以理解成是一个View的最合适而且最小的宽度和高度。对于UILabe来说，就是至少得把我设定的文字都显示完整吧，所以系统只需要知道UILabel的位置。而UIView的Intrinsic Content是（0，0）所以需要设置UIView的宽高（或是设定周围的边距等等其他关系可以让系统知道这个View应该多宽，多高）。而Intrinsic Content Size，也是未来自定义View显示到Xcode中必须设置的属性之一。

##Phases of Display

使用AutoLayout之后，把view显示到屏幕上面大体分成3步。

* Update constraints
* Layout views
* Display

一般来说`layoutSubviews`负责布局，比如调整View之间的距离，大小，`drawRect`负责绘制，比如使用什么颜色。而AutoLayout则是在layout之前增加了一个设定约束的过程,也就是上面提到了`update constraints`。

{% imgcap /images/autolayout-8.png 1-7%}

在view的`layoutSubView`中，如果我们调用了`[super layoutSubView]` 系统就把设定的这些约束计算成每个view的bounds，center属性。当然我们也可以基于AutoLayout的结果,再做布局的调整。

{% imgcap /images/autolayout-9.png 1-8%}

**Display 不是这篇文章的重点，这里略过**

##Alignment Rect

仔细阅读文档的同学会发现在Apple AutoLayout document中可以看到Alignment Rect 这个家伙。
AutoLayout中的Left，Right等约束，并不是针对View的frame。而是根据Alignment Rect。在绝大多数情况下Alignment = Frame。但是如果对某些需要交互的元素，而图片素材很小的时候，就可以利用Alignment把交互区域变大。可以参考UIImage 中的 `imageWithAlignmentRectInsets`。

{% imgcap /images/autolayout-10.png 1-9%}

##Animation

AutoLayout也可以配合传统的animation方法，整体代码结构如下。

{% codeblock lang:objc %}
  [self.view layoutIfNeeded];
  [UIView animateWithDuration:0.3f
                   animations:^{
                   
                     //... update constraints  
                     
                     [self.view layoutIfNeeded];
                   }];

{% endcodeblock %}

使用AutoLayout也可以轻易的实现之前的设置frame很难实现的动画效果。比如下面的例子(很奇怪，优酷吃掉了后面几秒的动画...)

<embed src="http://player.youku.com/player.php/sid/XNzI3NTQxOTI0/v.swf" allowFullScreen="true" quality="high" width="480" height="400" align="middle" allowScriptAccess="always" type="application/x-shockwave-flash"></embed>

使用之前传统的动画，实现这个过程，需要计算所有subView之间的距离，位置。而且在修改一个view的frame时，很难做到和其他View的移动速度同步。除非是custom `layoutsubview`。做起来相当麻烦。但是用AutoLayout则非常简洁直观，只需要设置第一个View的position，然后其他view约定好高度和间隔依次排列就好了。

[demo code](https://github.com/studentdeng/AutoLayoutAnimation)

当然AutoLayout做动画的时候有的地方也很麻烦，比如希望旋转view A 的时候，或是使用transform时，很容易产生奇怪的结果。一般来说会设置一个host View通过AutoLayout设定位置，然后在旋转view A。一句话就是混合起来，各取优点。

##其他

* Compression Resistance  	
* Content Hugging
* 优先级

简单的来说Compression Resistance 设置view有多大意愿（优先级），愿意压缩里面的内容。Content Hugging设置view 有多大愿意（优先级），愿意显示里面内容之外的部分。

stackoverflow上面有一个很清晰的通过UIButton解释的[[例子]](http://stackoverflow.com/questions/15850417/cocoa-autolayout-content-hugging-vs-content-compression-resistance-priority)，可以很容易理解这2个属性。

#参考

* [Core Animation Programming Guide:Core Animation Basics](https://developer.apple.com/library/ios/documentation/cocoa/conceptual/coreanimation_guide/CoreAnimationBasics/CoreAnimationBasics.html#//apple_ref/doc/uid/TP40004514-CH2-SW3)
* [Advanced Auto Layout Toolbox-objc.io](http://www.objc.io/issue-3/advanced-auto-layout-toolbox.html)
* [WWDC2012 session 202 – Introduction to Auto Layout for iOS and OS X](https://developer.apple.com/videos/wwdc/2012/?id=202)
* [WWDC2012 session 228 – Best Practices for Mastering Auto Layout](https://developer.apple.com/videos/wwdc/2012/?id=228)
* [WWDC2012 session 232 – Auto Layout by Example](https://developer.apple.com/videos/wwdc/2012/?id=232)



