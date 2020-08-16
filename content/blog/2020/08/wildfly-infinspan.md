title=Jakarta EE application distributed cache with Wildfly and Infinispan
date=2020-08-11
type=post
tags=jakartaee, wildfly, infinispan, jcache
~~~~~~

Latest trends teach us to do development of stateless applications, and if you can - keep your design stateless. But, by some reason, you may need to share state between nodes. The most prefer way to do it in the JakartaEE application is **[JSR 107: JCACHE - Java Temporary Caching API](https://jcp.org/en/jsr/detail?id=107)**

Unfortunately, JCache still not a part of JakartaEE specification (i hope one day it will), but many well known vendors like [Hazelcast](https://hazelcast.org/), [Infinispan](https://infinispan.org/), [Ehcache](https://www.ehcache.org/) etc, support JCache API as well. In turn **Infinispan integrated into Wildfly** Application Server as distributed cache provider and can be configured over separate **[infinispan subsystem](https://docs.wildfly.org/20/wildscribe/subsystem/infinispan/index.html)**

So, time to develop sample Jakarta EE application to see how **JCache API** looks and works on practice.

First, we need for at least two node Wildfly cluster - please refer to my article about [Wildfly domain mode cluster and load balancing from the box](https://kostenko.org/blog/2019/04/wildfly-cluster-domain-mode.html). And then we are ready to configure distributed cache for our application:

```bash
/profile=full-ha/subsystem=infinispan/cache-container=myCacheContainer:add
/profile=full-ha/subsystem=infinispan/cache-container=myCache/distributed-cache=myCache:add
```
