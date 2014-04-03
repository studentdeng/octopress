---
layout: post
title: "git 部署代码到服务器"
date: 2013-07-30 22:34
comments: true
categories: [tips, git]
---
之前常用的部署代码就是用svn，或是更老土的ftp。今天在写一个新玩具的时候，突然发现，每次的git pull实在是一个让人烦躁的东西，就网上查找了一下，整理在这里。[参考原文](http://toroid.org/ams/git-website-howto)

实现原理是当我们push 代码到remote repository时，通过git的[post-receive hooks](https://www.kernel.org/pub/software/scm/git/docs/githooks.html)。执行 

	git checkout prod -f
	
来帮助我们实现自动部署

让我们从最简单的开始，现在**本地创建**一个git repository

	$ mkdir test && cd test
	$ git init 
	$ echo 'Hello, world!' > index.html
	$ echo 'Hello, world!' > index.html
	$ git add index.html
	$ git commit -q -m "The humble beginnings of my web site."

index.html 就是我们希望能够部署到服务器的代码

然后在**服务器**创建一个repository, 这里可不是服务器部署代码的位置

	$ mkdir test.git && cd test.git
	$ git init --bare
	$ cat > hooks/post-receive
	#!/bin/sh
	GIT_WORK_TREE=/mnt/www/test git checkout prod -f
	$ chmod +x hooks/post-receive

这是服务器的git代码目录 

	/repo/test.git
	
这里的 '/mnt/www/test' 就是我们将要部署服务器代码的位置，一般的lamp，我们喜欢放在www里，当然这里需要根据不同的环境更换就好了。

这里我们在**本地**的git目录下增加一个remote

	$ git remote add prod ssh://server_address/repo/test.git
	$ git push prod +master:refs/heads/master

server_address 可以ip，域名。

我不太喜欢用这个命令行，我喜欢用[SourceTree](http://www.sourcetreeapp.com)来做这个增加remote和最后的commit push 部分。

这时我们切换到**服务器**目录下，就可以看到我们的index.html 在我们向prod push的之后，已经自动check out 到我们指定目录下了。


之后我们只需要修改完成之后，git push prod 就可以自动部署代码了。

第一次用，这里标记一下，看看后面当发生冲突的时候，时一个什么样的情况。： ）

