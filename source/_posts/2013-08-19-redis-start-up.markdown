---
layout: post
title: "redis服务器启动流程"
date: 2013-08-19 10:26
comments: true
categories: [redis]
---

![整个系统初始化流程图](http://pauladamsmith.com/articles/redis_under_the_hood/startup.png)

让我们从 redis.c -> main() 开始

#读取配置文件
在初始化完毕一些系统时间之后，redis开始初始化服务器配置。

##initServerConfig
在这个函数中，初始化全局变量

	struct redisServer server; /* server global state */

struct redisServer 结构体描述了服务器的状态。这种庞大的数据结构实在是看的烦躁。
这里可以很方便的看到redis的系统默认配置。另外还初始化了系统命令表。

	server.commands = dictCreate(&commandTableDictType,NULL);
    populateCommandTable();

这里我们可以找到redis的命令所对应的函数名称。

	struct redisCommand redisCommandTable[] = {
    	{"get",getCommand,2,"r",0,NULL,1,1,1,0,0},
	    {"set",setCommand,3,"wm",0,noPreloadGetKeys,1,1,1,0,0},
	    {"setnx",setnxCommand,3,"wm",0,noPreloadGetKeys,1,1,1,0,0},
	    {"setex",setexCommand,4,"wm",0,noPreloadGetKeys,1,1,1,0,0},
	    {"psetex",psetexCommand,4,"wm",0,noPreloadGetKeys,1,1,1,0,0},
	    {"append",appendCommand,3,"wm",0,NULL,1,1,1,0,0},
	    //...
    }
    

	struct redisCommand {
    	// 命令的名字
    	char *name;
    	// 命令的实现函数
    	redisCommandProc *proc;
    	// 命令所需的参数数量
    	int arity;
    	// 字符形式表示的 FLAG 值
    	char *sflags; /* Flags as string represenation, one char per flag. */
    	// 实际的 FLAG 值，由 sflags 计算得出
    	int flags;    /* The actual flags, obtained from the 'sflags' field. */
    	/* Use a function to determine keys arguments in a command line.
    	 * Used for Redis Cluster redirect. */
    	// 可选，在以下三个参数不足以决定命令的 key 参数时使用
    	redisGetKeysProc *getkeys_proc;
    	/* What keys should be loaded in background when calling this command? */
    	// 第一个 key 的位置
    	int firstkey; /* The first argument that's a key (0 = no keys) */
    	// 第二个 key 的位置
    	int lastkey;  /* THe last argument that's a key */
    	// 两个 key 之间的空隔
    	int keystep;  /* The step between first and last key */
    	// 这个命令被执行所耗费的总毫秒数
    	long long microseconds;
    	// 这个命令被调用的总次数
    	long long calls;
	};
	
这里可以看出，redis的命令配置，保存在底层数据结构dic中。

#服务器初始化
##initServer
这里设置信号回调函数，和继续初始化

	struct redisServer server; /* server global state */
结构外，创建了SharedObjects。

###createSharedObjects
	initServer->createSharedObjects

redis这里将除了把一些常用的字符串保存起来，目的就是为了减少不断申请释放时CPU时间，内存碎片等等,常用的返回客户端的命令，消息等。如

	shared.ok = createObject(REDIS_STRING,sdsnew("+OK\r\n"));
    shared.err = createObject(REDIS_STRING,sdsnew("-ERR\r\n"));
    
    //...
    
    shared.wrongtypeerr = createObject(REDIS_STRING,sdsnew(
        "-WRONGTYPE Operation against a key holding the wrong kind of value\r\n"));
    //...

还初始化了一个很大的共享数字对象。

	#define REDIS_SHARED_INTEGERS 10000

	for (j = 0; j < REDIS_SHARED_INTEGERS; j++) {
        shared.integers[j] = createObject(REDIS_STRING,(void*)(long)j);
        shared.integers[j]->encoding = REDIS_ENCODING_INT;
    }

###aeCreateEventLoop
	initServer->aeCreateEventLoop

 
	
	/* Include the best multiplexing layer supported by this system.
	* The following should be ordered by performances, descending. */
	#ifdef HAVE_EVPORT
		#include "ae_evport.c"
	#else
    	#ifdef HAVE_EPOLL
    		#include "ae_epoll.c"
		#else
        	#ifdef HAVE_KQUEUE
        		#include "ae_kqueue.c"
        	#else
        		#include "ae_select.c"
        	#endif
    	#endif
    #endif
	
接下来创建eventloop。这里调用 aeApiCreate 创建event loop。redis这里根据不同平台会选择不同的event方式，
Linux 使用epoll，BSD上面使用kqueue，其他选择select


###初始化网络连接
	if (server.port != 0) {
        server.ipfd = anetTcpServer(server.neterr,server.port,server.bindaddr);
        if (server.ipfd == ANET_ERR) {
            redisLog(REDIS_WARNING, "Opening port %d: %s",
                server.port, server.neterr);
            exit(1);
        }
    }

    if (server.unixsocket != NULL) {
        unlink(server.unixsocket); /* don't care if this fails */
        server.sofd = anetUnixServer(server.neterr,server.unixsocket,server.unixsocketperm);
        if (server.sofd == ANET_ERR) {
            redisLog(REDIS_WARNING, "Opening socket: %s", server.neterr);
            exit(1);
        }
    }

###创建系统cron定时器
	aeCreateTimeEvent(server.el, 1, serverCron, NULL, NULL);
	
	aeCreateTimeEvent
	aeCreateTimeEvent accepts the following as parameters:
	eventLoop: This is server.el in redis.c
	milliseconds: The number of milliseconds from the current time after which the timer expires.
	proc: Function pointer. Stores the address of the function that has to be called after the timer expires.
	clientData: Mostly NULL.
	finalizerProc: Pointer to the function that has to be called before the timed event is removed from the list of timed events.
	

aeCreateTimeEvent 创建一个定时器，redis会在这个serverCron中清理系统变量，判断是否需要写入文件等操作。

###在event loop中绑定回调函数

    if (server.ipfd > 0 && aeCreateFileEvent(server.el,server.ipfd,AE_READABLE,
        acceptTcpHandler,NULL) == AE_ERR) redisPanic("Unrecoverable error creating server.ipfd file event.");            
        
#设置启动event loop
	// 设置事件执行前要运行的函数
    aeSetBeforeSleepProc(server.el,beforeSleep);

    // 启动服务器循环
    aeMain(server.el);

	// 关闭服务器，删除事件
    aeDeleteEventLoop(server.el);
    
aeMain函数和之前用的很多的windows中的message queue非常相似。redis不断循环等待执行event。这里不论是定时器还是socket event，都会在这个event loop中被执行。

	void aeMain(aeEventLoop *eventLoop) {

    eventLoop->stop = 0;

    while (!eventLoop->stop) {

        // 如果有需要在事件处理前执行的函数，那么运行它
        if (eventLoop->beforesleep != NULL)
            eventLoop->beforesleep(eventLoop);

        // 开始处理事件
        aeProcessEvents(eventLoop, AE_ALL_EVENTS);
    	}
	}

方便整理，这里重复一下一开始的流程图

![整个系统初始化流程图](http://pauladamsmith.com/articles/redis_under_the_hood/startup.png)



#处理客户端命令流程

![处理客户端命令流程图](http://pauladamsmith.com/articles/redis_under_the_hood/request-response.png)

之前我们已经注册了socket acceptTcpHandler 回调函数，现在的流程是

	acceptTcpHandler->acceptCommonHandler->createClient->aeCreateFileEvent

    if (aeCreateFileEvent(server.el, c->fd, AE_READABLE,
    	readQueryFromClient, c) == AE_ERR) {
    	freeClient(c);
    	return NULL;
	}

这里又向event loop中加入一个新的事件callback函数：aeCreateFileEvent 用于把event loop中的监听的事件和回调函数绑定在一起。

readQueryFromClient 则是客户端一切命令的入口函数。

	void readQueryFromClient(aeEventLoop *el, int fd, void *privdata, int mask) {
    	redisClient *c = (redisClient*) privdata;
    	char buf[REDIS_IOBUF_LEN];
		int nread;
    	// ...
 
    	nread = read(fd, buf, REDIS_IOBUF_LEN);
    	// ...
    	if (nread) {
        	size_t oldlen = sdslen(c->querybuf);
        	c->querybuf = sdscatlen(c->querybuf, buf, nread);
        	c->lastinteraction = time(NULL);
        	/* Scan this new piece of the query for the newline. We do this
         	* here in order to make sure we perform this scan just one time
         	* per piece of buffer, leading to an O(N) scan instead of O(N*N) */
       		if (c->bulklen == -1 && c->newline == NULL)
            	c->newline = strchr(c->querybuf+oldlen,'\n');
    	} else {
        	return;
    	}
    	Processinputbuffer(c);
	}

 readQueryFromClient读取客户端命令，交给Processinputbuffer处理。
 
	void processInputBuffer(redisClient *c) {
		//...
		
		if (processCommand(c) == REDIS_OK)
			resetClient(c);
	}
 
	int processCommand(redisClient *c) {
		//...
		call(c,REDIS_CALL_FULL);
	}
 
这里call回根据command定义的callback函数，执行相对应的redis命令代码。

当command执行完毕之后，准备将结果传递给客户端。这里可以看到注册了sendReplyToClient回调函数。

	int prepareClientToWrite(redisClient *c) {
    	if (c->flags & REDIS_LUA_CLIENT) return REDIS_OK;
    	if (c->fd <= 0) return REDIS_ERR; /* Fake client */
	    if (c->bufpos == 0 && listLength(c->reply) == 0 &&
    	    (c->replstate == REDIS_REPL_NONE || c->replstate == REDIS_REPL_ONLINE) &&
        	aeCreateFileEvent(server.el, c->fd, AE_WRITABLE, sendReplyToClient, c) == AE_ERR)
        		return REDIS_ERR;
		return REDIS_OK;
	}
	
读到这里，我们已经看到了。redis在处理event loop的时候，不仅仅是处理客户端的连接，很多redis内部的流程也是通过event loop实现的。这个是event driven常常遇到的方式。

内容资料、图片、代码参考 

* [huangz的redis2.6代码注释](https://github.com/huangz1990/annotated_redis_source)
* [Redis: under the hood](http://pauladamsmith.com/articles/redis-under-the-hood.html#back-up-to-main)
* [Redis Event Library](http://redis.io/topics/internals-rediseventlib)