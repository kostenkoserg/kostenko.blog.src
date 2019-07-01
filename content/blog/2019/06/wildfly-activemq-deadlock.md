title=Wildfly active-mq subsystem deadlock
date=2019-06-29
type=post
tags=Wildfly
status=published
~~~~~~

Recently got unusual height CPU utilizaton on random wildly cluster instance. Thread dump shows the reason of a problem:

```java
Found one Java-level deadlock:
=============================

"Thread-1 (ActiveMQ-server-org.apache.activemq.artemis.core.server.impl.ActiveMQServerImpl$2@46fcd20a-1114701218)":
  waiting to lock Monitor@0x00007f45f02e20f8 (Object@0x0000000603407950, a org/apache/activemq/artemis/core/server/cluster/impl/ClusterConnectionImpl$MessageFlowRecordImpl),
  which is held by "Thread-29 (ActiveMQ-client-global-threads-2129186403)"
"Thread-29 (ActiveMQ-client-global-threads-2129186403)":
  waiting to lock Monitor@0x00007f46203b5518 (Object@0x00000004cc79a7b8, a org/apache/activemq/artemis/core/server/impl/QueueImpl),
  which is held by "Thread-1 (ActiveMQ-server-org.apache.activemq.artemis.core.server.impl.ActiveMQServerImpl$2@46fcd20a-1114701218)"

Found a total of 1 deadlock.
```

Below is part of official documentation:

"If thread-pool-max-size is set to a positive integer greater than zero, the thread pool is bounded. If requests come in and there are no free threads available in the pool, requests will block until a thread becomes available. It is recommended that a bounded thread pool be used with caution since it can lead to **deadlock situations** if the upper bound is configured too low."

So, solution is:

```java
/subsystem=messaging-activemq/server=default:write-attribute(name=thread-pool-max-size,value=-1)
```
