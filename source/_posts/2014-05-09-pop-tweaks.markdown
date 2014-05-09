---
layout: post
title: "facebook pop & tweaks demo"
date: 2014-05-09 19:39
comments: true
categories: [iOS]
---

最近facebook开源了2个很有价值的project [pop](https://github.com/facebook/pop)和[Tweaks](https://github.com/facebook/Tweaks)。
facebook提供了一个非常赞的topic-[Building Paper](http://www.youtube.com/playlist?list=PLb0IAmt7-GS2sh8saWW4z8x2vo7puwgnR)。

这篇文章来简单介绍一下[pop](https://github.com/facebook/pop)的使用，最后使用[Tweaks](https://github.com/facebook/Tweaks)来微小调整动画参数来达到我们最希望的效果。

这是我们最后的效果:

<div class="video-container">
	<iframe height=498 width=510 src="http://player.youku.com/embed/XNzA5ODM1NTQ4" frameborder=0 allowfullscreen></iframe>
</div>

#pop is powerful

这个动画效果很简单，有很多方式都可以做到，但是pop来实现它，只需要下面几行代码。

{% codeblock lang:objc %}
  POPBasicAnimation *animation = [POPBasicAnimation animation];
  animation.property = [self animationProperty];
  animation.fromValue = @(0);
  animation.toValue = @(8000);
  animation.duration = 2.0f;
  
  [self.numberLabel pop_addAnimation:animation forKey:@"numberLabelAnimation"];
{% endcodeblock %}

{% codeblock lang:objc %}
  - (POPMutableAnimatableProperty *)animationProperty {
  return [POPMutableAnimatableProperty
      propertyWithName:@"com.curer.test"
           initializer:^(POPMutableAnimatableProperty *prop) {
               prop.writeBlock = ^(id obj, const CGFloat values[]) {
                 UILabel *label = (UILabel *)obj;
                 NSNumber *number = @(values[0]);
                 int num = [number intValue];
                 label.text = [@(num) stringValue];
               };
           }];
}
{% endcodeblock %}

哈哈，搞定了。pop太强大了。但是细心的同学会发现动画似乎不是我们想要的，我们希望做到那种一开始很快速很激动，最后却有一点慢慢的“欲求不能”的感觉。

很直观的，我们使用了万能的EaseOut动画

{% codeblock lang:objc %}
  POPBasicAnimation *animation = [POPBasicAnimation animation];
  animation.property = [self animationProperty];
  animation.fromValue = @(0);
  animation.toValue = @(8000);
  animation.duration = 2.0f;
  //增加animation 时间函数控制
  animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
{% endcodeblock %}

增加了一行代码，但是发现这个动画变化的时间还是不能让我们满意，一开始变化的还是慢，后面变化的又有点快。

#how can we better build animation
动画的实现其实很简单，抛开性能，就是一个个不断变化的图片，对于我们这个简单的动画，就是一个从0到8000的变化，如果x轴为时间，y轴为大小。我们第一个动画其实是这个样子

{% imgcap /images/pop-demo-3.png %}

easeout好一点是这样子

{% imgcap /images/pop-demo-1.png %}

我们其实希望是这个样子

{% imgcap /images/pop-demo-2.png %}

CAMediaTimingFunction 实际上还提供另一个方法，不是很常用，但是却非常适合我们现在的场景。
{% codeblock lang:objc %}
+ (id)functionWithControlPoints:(float)c1x :(float)c1y :(float)c2x :(float)c2y;
{% endcodeblock %}

这里我们描述的“时间函数”其实就是[贝塞尔曲线](http://en.wikipedia.org/wiki/B%C3%A9zier_curve)。

这里推荐一个[网站](http://cubic-bezier.com/)可以很直观的生成贝塞尔曲线。
这里我们得到了参数（.12,1,.11,.94）。

{% codeblock lang:objc %}
  POPBasicAnimation *animation = [POPBasicAnimation animation];
  animation.property = [self animationProperty];
  animation.fromValue = @(0);
  animation.toValue = @(8000);
  animation.duration = 2.0f;
  //修改animation 时间函数
  animation.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.12 :1: 0.11:0.94];
{% endcodeblock %}

这里我们已经得到我们想要的动画效果了。而且看上去相当不错。

#how can we better build animation
如何才能有更好的效果呢？动画的速度，时间，等等参数都会影响到动画的效果是不是会完美。如何判断动画效果是否足够好。的确是个很难的问题。而解决这个问题的关键，不在于工程师自己折腾，应该找专业的人来做。而这时[Tweaks](https://github.com/facebook/Tweaks)就闪亮登场了。

初始化的时候创建2个tweak用来动态调整时间和目标数值。并修改一下默认的UIWindow为```FBTweakShakeWindow```
{% codeblock lang:objc %}
  //reset window
  self.window = [[FBTweakShakeWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

  FBTweak *animationDurationTweak =
      FBTweakInline(@"Content", @"Animation", @"Duration", 2.0, 1.0, 3.0);
  animationDurationTweak.stepValue = [NSNumber numberWithFloat:0.1f];
  animationDurationTweak.precisionValue = [NSNumber numberWithFloat:3.0f];

  FBTweak *animationToValueTweak =
      FBTweakInline(@"Content", @"Animation", @"ToValue", 8000, 1000, 10000);
  animationToValueTweak.stepValue = @(1000);
  animationDurationTweak.precisionValue = [NSNumber numberWithFloat:1.0f];
{% endcodeblock %}

再把原来创建动画的代码稍微修正一下
{% codeblock lang:objc %}
  POPBasicAnimation *animation = [POPBasicAnimation animation];
  animation.property = [self animationProperty];
  animation.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.12 :1: 0.11:0.94];
  animation.fromValue = @(0);

  double animationDuration =
      FBTweakValue(@"Content", @"Animation", @"Duration", 2.0);
  animation.toValue =
      @(FBTweakValue(@"Content", @"Animation", @"ToValue", 8000));
  animation.duration = animationDuration;

  [self.numberLabel pop_addAnimation:animation forKey:@"numberLabelAnimation"];
{% endcodeblock %}
  
这样当摇晃手机的时候就可以动态调整动画参数了，最后数据会保存在plist ：）。

越简单的越强大~
