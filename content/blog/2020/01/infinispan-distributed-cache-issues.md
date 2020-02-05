title=ISPN000299: Unable to acquire lock after 15 seconds for key
date=2020-01-10
type=post
tags=wildfly, infinispan
status=published
~~~~~~
Distributed cache is a wide used technology that provides useful possibilities to share state whenever it necessary. Wildfly supports distributed cache through [infinispan](https://infinispan.org/) subsystem and actually it works well, but in case height load and concurrent data access you may run into a some issues like:

 * ISPN000299: Unable to acquire lock after 15 seconds for key
 * ISPN000924: beforeCompletion() failed for SynchronizationAdapter
 * ISPN000160: Could not complete injected transaction.
 * ISPN000136: Error executing command PrepareCommand on Cache
 * ISPN000476: Timed out waiting for responses for request
 * ISPN000482: Cannot create remote transaction GlobalTx

and others.

In my case i had two node cluster with next infinispan configuration:
```java
/profile=full-ha/subsystem=infinispan/cache-container=myCache/distributed-cache=userdata:add()
/profile=full-ha/subsystem=infinispan/cache-container=myCache/distributed-cache=userdata/component=transaction:add(mode=BATCH)
```

**distributed** cache above means that number of copies are maintained, however this is typically less than the number of nodes in the cluster. From other point of view, to provide redundancy and fault tolerance you should configure enough amount of **owners** and obviously **2** is the necessary minimum here. So, in case usage small cluster and keep in mind the [BUG](https://issues.redhat.com/browse/JDG-1318), - i recommend use **replicated-cache** (all nodes in a cluster hold all keys)

Please, compare [Which cache mode should I use?](https://infinispan.org/docs/dev/titles/clustering/clustering.html#which_cache_mode_should_i_use) with your needs.

Solution:
```java
/profile=full-ha/subsystem=infinispan/cache-container=myCache/distributed-cache=userdata:remove()
/profile=full-ha/subsystem=infinispan/cache-container=myCache/replicated-cache=userdata:add()
/profile=full-ha/subsystem=infinispan/cache-container=myCache/replicated-cache=userdata/component=transaction:add(mode=NON_DURABLE_XA, locking=OPTIMISTIC)
```
Note!, `NON_DURABLE_XA` doesn't keep any transaction recovery information and if you still getting `Unable to acquire lock` errors on application critical data - you can try to resolve it by some **retry** policy and **fail-fast** transaction:

```java
/profile=full-ha/subsystem=infinispan/cache-container=myCache/distributed-cache=userdata/component=locking:write-attribute(name=acquire-timeout, value=0)
```
