---
layout: post
title: "cocoapods 入门"
date: 2013-09-13 23:48
comments: true
categories: [ios, tips]
---
#介绍

最近一直在搞[cocoapods](https://github.com/CocoaPods/CocoaPods)。 ios 这么多年终于有一个好使的包管理了。真的好激动好激动。。。
之前开发一些App的时候，在一开始的时候，总是需要手动添加framework， library，设置一些 search path，有时候还会忘记那么几个，然后出来一大堆的link error。当一些library更新的时候，还需要自己手动去更换。3句话说就是

1. 手动增加framework，library
2. 手动增加编译参数
3. 手动维护代码更新

完全是一大堆的体力活，当然，这些简单的配置和复制并不会花费太多的时间，但是，还是觉得在浪费生命，而这时候CocoaPods就出来了。我们只需要设置一个Podfile文件，执行

	$ pod install 
	
CocoaPods会帮我们下载好代码，设置好编译参数，配置好framework， library。

#安装和更新

	$ sudo gem install cocoapods
	
#使用
	
在project根目录下，create Podfile文件，下面一个例子
	
	platform :ios, '5.0'
	pod 'CURestKit', '~>1.0.1' 
	pod 'SDWebImage','~>3.4'
	pod 'MBProgressHUD', '~> 0.7'
	pod 'UALogger', '~> 0.2.3'

CocoaPods 会帮我们从git clone下来配置好的这些代码。后面的部分表示代码的版本号，一般来说和tag挂钩。

配置好Podfile之后，执行

	$ pod install
	
则会帮我们配置好这些项目。并生成一个XXXX.xcworkspace。 以后project使用这个文件就可以了。CocoaPods其实就是帮我们配置一个静态库作为项目的依赖。

CocoaPods里面有大量的代码，现在最新的版本安装后是在这里

	~/.cocoapods/repo/master/ 

#制作自己的项目配置

实际开发过程中，我们还有不少代码需要被改动，而CocoaPods上面的代码，大部分都比较旧，都是很稳定的代码，当然也有一些不能用的（大部分是国内的公司做的，大家都懂的）。另外还有一些我们自己写的一些其他代码，暂时还么有被CocoaPods收录的。这时候我们就需要配置自己的项目啦。

这里是我的一个项目配置例子。cocoapods的配置文件就是一个 *.podspec的文件，这是一个例子文件名ShareCenter.podspec。这是一个典型的ruby，

	Pod::Spec.new do |s|
	s.name         = "ShareCenter"
	s.version      = "2.0"
	s.summary      = "share client include sina weibo ,tencent weibo, renren"

	s.description  = <<-DESC
                   share client include sina weibo ,tencent weibo, renren
                   DESC

	s.homepage     = "https://github.com/studentdeng/ShareCenterExample"
	s.license      = 'MIT'
	s.author       = { "curer" => "studentdeng@hotmail.com" }
	s.platform     = :ios, '5.0'

	s.source       = { :git => "https://github.com/studentdeng/ShareCenterExample.git", :tag => s.version.to_s }
	s.source_files  = 'ShareCenter', 'ShareCenter/**/*.{h,m}'

	s.frameworks   = 'QuartzCore', 'Security', 'CoreGraphics', 'AudioToolbox'
	s.library = 'sqlite3.0'
	s.vendored_libraries = 'ShareCenter/Vender/sina/libWeiboSDK/libWeiboSDK.a'

	s.prefix_header_contents = <<-EOS
	#ifdef __OBJC__
	#import "ROConnect.h"
	#endif /* __OBJC__*/
	EOS
	end
	
	
这个基本上都是自解释的，这里有几个需要说明一下	
##s.source s.source_files
这里的 *source* 我们看出是一个git 的地址，这里我们调试的时候，可以先暂时设置成本地git，调试完毕之后就可以发布 增加tag。想要最新的代码只需要这样设置就好

	{ :git => "https://github.com/studentdeng/ShareCenterExample.git"}

我们的git项目中，并不是所有的代码都需要被引用到我们的代码中，通常project还会包括一些example，test cases等，这里的 *source_files* 就是用来指定一些文件夹，或是文件。我这里的设置也很容易理解，就是ShareCenter下面的递归后的所有后缀是h、m的子文件。


##s.frameworks s.library

这里配置的就是我们的framework 和 library，这里注意一下library的名字规则就好。

##vendored_libraries

这里用来指定外部的静态库。这里我们指定了sina sso认证的SDK

##s.prefix_header_contents

这里用来指定预编译的配置，这里一定要鄙视一下renren的超级渣渣SDK。这里提供一种解决方法。

##部署我们的配置到cocoapods中

cocoapods的代码配置文件是在这里[Specs](https://github.com/CocoaPods/Specs)

这里最好是去fork一个自己的project，然后保存一个自己或是团队的配置，这样不会在更新cocoapods的时候，丢掉自己的配置。当然，如果觉得自己搞的还不错，也可以去pull requests。

在之前提到的目录*~/.cocoapods/repo/master/* 下面，我们可以看到已经有超级多的项目了，我们可以也可以通过

	$ pod search XXX
	
来查找项目，或是直接在这个文件夹下面找，可以学习不少project的配置技巧，我这里也是从他们学到的。

最后添加一个project的配置是这样子的。

例如上面的例子，
在*~/.cocoapods/repo/master/* 下面创建一个文件夹ShareCenter，然后在创建一个2.0的文件夹表示这是version2.0的配置。
然后在把之前的ShareCenter.podspec复制到2.0目录下面。

也就是最后的目录是这样子的

	~/.cocoapods/repo/master/ShareCenter/2.0/ShareCenter.podspec
	
如果希望更多的了解cocoapods，还是需要去[Github](https://github.com/CocoaPods/CocoaPods)上面 :D
