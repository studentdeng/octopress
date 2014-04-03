---
layout: post
title: "Core Bluetooth Concept"
date: 2014-03-22 20:41
comments: true
categories: [iOS]
---

Core Bluetooth 里面的名词还是挺多的，这里简单记录一下，一上来的时候，还是很容易混淆的，这里记录一下。

#Basic Concept

Bluetooth low energy ([BLE](http://en.wikipedia.org/wiki/Bluetooth_low_energy#Radio_interface)，还有地方叫做BTLE，最恨各种简写了) 简单说是一种低功耗的短距离无线传输技术，主要用于低功耗设备传输，比如心率、记步器、智能家居方向,还有连接其他iOS设备。

Core Bluetooth API 支持BLE4.0，做了协议封装，让开发者不需要完整了解BLE协议就可以快速开发APP。

##Central and Peripheral

BLE中有2个非常重要的概念就是Central和Peripheral，有一点类似Client Server。

* Peripheral是数据的发送方（比如运动手环需要把位置，步数等数据传递给其他设备）。
* Central是数据的接收方（比如手机接收手环传递来的步数）

![1-1 Central 和 Peripheral 心率设备和Apple product](http://studentdeng.github.io/images/coreblue1.png)

##Centrals Discover and Connect to Peripherals That Are Advertising

* Peripheral把advertising packets广播出去，advertising packet 包括会包含一些重要的信息，比如设备名字，所提供的服务。

* Central 则是扫描自己感兴趣的advertising packet，比如一个APP需要查找当前家里的室温，会通过参数设定，只是检索温度设备发来的packet。


![1-2 一个简单的advertising模型](http://studentdeng.github.io/images/coreblue2.png)

## Data structure

* Peripheral 是最上层的一种服务抽象，比如iOS 系统内置的[ANCS](http://studentdeng.github.io/blog/2014/03/22/ancs/)服务,另外我们自己也可以创建自己的服务。
* characteristic 则是用来描述服务中的具体内容（比如手环有传递行走路程的接口，还有行走位置的接口），一个服务可以包含多个characteristics。

![1-3 心率检测仪包含1个服务，1个服务中包含2个characteristics,一个用来传递心率，一个用来传递位置](http://studentdeng.github.io/images/coreblue3.png)

#How to

[YmsCoreBluetooth](https://github.com/kickingvegas/YmsCoreBluetooth) 是个不错的框架，有很详细的[介绍](http://kickingvegas.github.io/YmsCoreBluetooth/appledoc/docs/tutorial/Tutorial.html)，这里就不赘述了。
