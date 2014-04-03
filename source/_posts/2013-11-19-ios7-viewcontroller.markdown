---
layout: post
title: "翻译：《iOS7 新功能 视图控制器API》"
date: 2013-11-19 18:12
comments: true
categories: [translation, iOS]
---

这篇文章投稿在 [伯乐在线](http://blog.jobbole.com/51588/)

原文出处: [objc](http://www.objc.io/issue-5/view-controller-transitions.html)


#View Controller Transitions

[Issue #5 iOS 7](http://www.objc.io/issue-5/index.html), October 2013

作者 [Chris Eidhof](http://twitter.com/chriseidhof)

#自定义动画

iOS7对我来说最激动人心的特性就是新的 View Controller Transitioning API。 iOS7之前，View Controller之间切换，我需要创建自定义的transitions。 而且这些方法都支持不完整，让人头疼。在transitions中增加交互功能就更难了。

在开始这篇文章之前，我要提醒一下：这是一个新的API，我们尽最大努力让他可以实用，但是并不能保证是最佳。可能需要至少一个月后才能确定，这篇文章是不是最佳的实用方案，这里只是一个对新功能的探索。如果有更好的使用这个API的方法，请联系我们，这样就可以修正这篇文章。

在开始介绍这个API之前，我们需要知道导航控制器的默认行为在iOS7下已经改变了：导航控制器下，切换2个view controller的动画有一点细微的改变，变得更有交互性。例如，当你希望弹出一个view controller时，可以从屏幕左边开始拖动，把整个内容拖动到屏幕右边。

让我们仔细看一下这个API，我发现这个被重度使用的接口是协议并不是一个实体。虽然一上来看上去有一点怪，但是我喜欢这个API，它给了我们更多的灵活性。我们从简单开始：用自定义动画代替原有的view controller的push动画（这里是[sample project](https://github.com/objcio/issue5-view-controller-transitions) 在github）。我们首先需要实现这个新的 UINavigationControllerDelegate 方法：

	- (id<UIViewControllerAnimatedTransitioning>)
                   navigationController:(UINavigationController *)navigationController
        animationControllerForOperation:(UINavigationControllerOperation)operation
                     fromViewController:(UIViewController*)fromVC
                       toViewController:(UIViewController*)toVC
	{
    	if (operation == UINavigationControllerOperationPush) {
        	return self.animator;
    	}
    	return nil;
	}

我们可以观察一下这种类型的操作（push 和 pop）返回一个不同的 animator。如果我们分享代码的话，这个可能是一个对象。我们可能需要把这个变量通过property保存下来。我们也可以为不同的操作创建不同的对象，这里有很高的灵活性。

让这个动画运行起来，我们创建一个自定义对象实现 UIViewControllerContextTransitioning 协议。

	@interface Animator : NSObject <UIViewControllerAnimatedTransitioning>

	@end

这个协议要求我们实现2个方法，其中一个是描述动画的执行时间

	- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
	{
    	return 0.25;
	}

另一个是描述动画的执行。

    - (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
    {
        UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        [[transitionContext containerView] addSubview:toViewController.view];
        toViewController.view.alpha = 0;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            fromViewController.view.transform = CGAffineTransformMakeScale(0.1, 0.1);
            toViewController.view.alpha = 1;
        } completion:^(BOOL finished) {
            fromViewController.view.transform = CGAffineTransformIdentity;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
            
        }];

    }

这里你可以看到这个协议是怎么用的：没有提供实体的对象参数，而是通过这个类型 id<UIViewControllerContextTransitioning> 得到transitionContext
唯一的最重要的东西就是在完成动画之后要调用 completeTransition 这个告诉 transitionContext 我们已经完成动画并且相应的更新了 view controller的状态。其他代码是标准的，我们通过transitionContext得到2个UIViewController，然后使用简单的 UIView 动画，这里我们很简单的做了一个zooming的动画

注意，我们只是写了push的自定义动画，当view controller pop时,iOS系统还是会使用默认的滑动动画。而且，实现这个方法后。导航栏也不能交互了（就是从左到右拖动实现pop view controller）。下面完善他

#交互动画

让之前的动画变得能够交互起来非常简单。我们需要实现另一个UINavigationControllerDelegate 

    - (id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController*)navigationController
                              interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>)animationController
    {
        return self.interactionController;
    }

注意，如果在一个不能交互的动画中，这里会返回nil。（译注：当不能交互时 self.interactionController 为 nil）

interactionController是UIPercentDrivenInteractionTransition的实例，没有必要更多的设置。我们通过创建拖动手势（UIPanGestureRecognizer）来实现：

    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (location.x >  CGRectGetMidX(view.bounds)) {
            navigationControllerDelegate.interactionController = [[UIPercentDrivenInteractiveTransition alloc] init];
            [self performSegueWithIdentifier:PushSegueIdentifier sender:self];
        }
    } 


只有当用户在屏幕右边操作时，我们才设置动画是可以交互的（通过设置interactionController 属性）。然后我们调用performSegueWithIdentifier（或是不用storyboards，直接push view controller）
在这个手势变化中，我们调用interactionController 的一个方法 updateInteractiveTransition:

    else if (panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGFloat d = (translation.x / CGRectGetWidth(view.bounds)) * -1;
        [interactionController updateInteractiveTransition:d];
    } 

这里根据拖动的距离设置百分比，非常cool的事情是交互控制器（interactionController）和 动画控制器（animation controller）相互协作。而且因为是普通的 UIView 动画，它控制着动画的进程。我们不需要处理他们之前的事情，
所有的事情都在背后默默的自动搞定了。

最后，当手势停止或是取消掉，我们需要调用interaction controller相应的方法

    else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if ([panGestureRecognizer velocityInView:view].x < 0) {
            [interactionController finishInteractiveTransition];
        } else {
            [interactionController cancelInteractiveTransition];
        }
        navigationControllerDelegate.interactionController = nil;
    }

当切换动画完毕时，设定interactionController为nil非常重要。如果下一个动画是非交互的，我们不希望得到一个奇怪的 interactionController

现在我们已经有一个完整的自定义的可交互的过度变换（transition）了。通过普通的拖动手势和一个UIKit提供的实体对象，几行代码就搞定了。对于大多数的自定义交互过度变换，你可以在这里停下来，用上面提到的方法做任何你想做得动画
或是交互。

#GPUImage自定义动画

我们现在已经能够实现一个完整的自定义动画了，可以不用UIView 甚至Core Animation，做自己喜欢的动画。一开始，我用Core Image实现了一个项目[Letterpress-style](http://www.macstories.net/featured/a-conversation-with-loren-brichter/)。但是在我的旧iPhone4上面只能跑到大约9FPS，这个和我所期望的60FPS差距太大了。

但是当我使用[GPUImage](https://github.com/BradLarson/GPUImage)后，实现一个非常漂亮的自定义动画效果变得非常简单。我们希望这个动画能够做到像素级的消融在2个view controller切换的时候。这个是通过分别对2个view controller 截屏，然后应用GPUImage的图片滤镜实现的。

首先，我们创建一个自定义类，实现animation 和 interactive transition 协议。

	@interface GPUImageAnimator : NSObject
	  <UIViewControllerAnimatedTransitioning,
	   UIViewControllerInteractiveTransitioning>

	@property (nonatomic) BOOL interactive;
	@property (nonatomic) CGFloat progress;

	- (void)finishInteractiveTransition;
	- (void)cancelInteractiveTransition;

	@end

为了让这个动画跑的飞快，我们只把图片传给GPU一次，然后把所有的图像处理绘制交给GPU，而不是传给CPU（GPU和CPU之间的数据传输非常慢）。通过GPUImageView，我们可以用OpenGL绘制动画效果（不需要手动编写底层的OpenGL代码，我们可以继续编写上层代码）

创建这样的滤镜链非常方便。这里可以看一下下面的例子。有一点挑战的是实现动态的滤镜。GPUImage不能给我们直接提供动画效果。这里我们通过在每一帧的时候更新滤镜来实现动画的绘制。我们使用CADisplayLink类来做这个。

	self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(frame:)];
	[self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
	
在frame:方法中，我们根据时间更新动画进度，然后更新滤镜

	- (void)frame:(CADisplayLink*)link
	{
	    self.progress = MAX(0, MIN((link.timestamp - self.startTime) / duration, 1));
	    self.blend.mix = self.progress;
	    self.sourcePixellateFilter.fractionalWidthOfAPixel = self.progress *0.1;
	    self.targetPixellateFilter.fractionalWidthOfAPixel = (1- self.progress)*0.1;
	    [self triggerRenderOfNextFrame];
	}
	
以上就是我们所有要讲得了。在交互变换中，我们需要确保我们的进度是根据手势识别设置的，而不是根据时间。但是剩下的代码几乎都一样了。

这个真的太强大了，你可以使用GPUImage提供的任何滤镜或是自己写的OpenGL代码来实现上面的效果。

#小结

我们这里仅仅提到了导航控制器下面的2个 view controller 之间的动画，事实上你可以做相同的事情在tabbar controller 或是自定义的container view controller。而且 UICollectionViewController 现在已经可以在layout上面自动实现交互动画了。他们都是使用相同的机制。这个真的太强大了。

当我和[Orta](https://twitter.com/orta)提到这个API时，他指出他已经使用这个功能创建了一些轻量级的view controller。不要在每一个view controller 保存管理动画的代码，而是创建一个新的view controller，然后实现2个view controlller视图切换时的自定义的动画效果。

#更多

* [WWDC: Custom Transitions using View Controllers](http://asciiwwdc.com/2013/sessions/218)
* [Custom UIViewController transitions](http://www.teehanlax.com/blog/custom-uiviewcontroller-transitions/)
* [iOS 7: Custom Transitions](http://www.doubleencore.com/2013/09/ios-7-custom-transitions/)
* [Custom View Controller Transitions with Orientation
](http://whoisryannystrom.com/2013/10/01/View-Controller-Transition-Orientation/)