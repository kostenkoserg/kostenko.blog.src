title=Wildfly/Infinispan domain. Keep distributed cache on separate nodes
date=2020-11-03
type=post
tags=jakartaee, wildfly, infinispan, jcache
status=published
~~~~~~

Previously i wrote about development of Jakarta EE application using [distributed cache with Wildfly and Infinispan](https://kostenko.org/blog/2020/08/wildfly-infinspan.html). This solution has a good fit for a small clustered environments where data distribution between nodes will not costs too much. In case you are looking for clustered environment where application scaling should have minimum impact on cache and vice versa, but by some reason you wouldn't like to use a separate infinispan-server cluster as **remote-cache-container** then next topology can be a solution:
![cache-server-group](/img/2020-11-cache-server-group.png)

To make it work we need to configure **distributed-cache** for two server groups and provide **zero capacity-factor** for one of them. Below is simple configuration example:

```bash
# clone current profile
/profile=full-ha:clone(to-profile=full-ha-cache)
# Create cache server group based on new profile
/server-group=cache-servers:add(profile=full-ha-cache, socket-binding-group=full-ha-sockets)
# Add cache container and distributed cache for both profiles
/profile=full-ha/subsystem=infinispan/cache-container=mycachecontainer:add(statistics-enabled=true)
/profile=full-ha-cache/subsystem=infinispan/cache-container=mycachecontainer:add(statistics-enabled=true)
/profile=ful-ha-cache/subsystem=infinispan/cache-container=mycachecontainer/distributed-cache=mycache:add()
/profile=full-ha/subsystem=infinispan/cache-container=mycachecontainer/distributed-cache=mycache:add()
# Create cache servers
/host=master/server-config=cache1:add(group=cache-servers,socket-binding-port-offset=500)
/host=master/server-config=cache1:start(blocking=true)
/host=master/server-config=cache2:add(group=cache-servers,socket-binding-port-offset=600)
/host=master/server-config=cache2:start(blocking=true)
# Configure ZERO capacity for profile which we will use for application
/profile=full-ha/subsystem=infinispan/cache-container=mycachecontainer/distributed-cache=mycache:write-attribute(name=capacity-factor, value=0)
# Provide transport
/profile=full-ha/subsystem=infinispan/cache-container=mycachecontainer/transport=jgroups:add()
/profile=ful-ha-cache/subsystem=infinispan/cache-container=mycachecontainer/transport=jgroups:add()
```
Now let's deploy our application on two server groups
```bash
deploy jcache-examples.war --server-groups=backend-servers,cache-servers
```
You can check cached **number-of-entries** on each server by
```bash
/host=master/server=backend1/subsystem=infinispan/cache-container=mycachecontainer/distributed-cache=mycache:read-resource(include-runtime=true)
/host=master/server=cache1/subsystem=infinispan/cache-container=mycachecontainer/distributed-cache=mycache:read-resource(include-runtime=true)
```
And be sure that application backend-servers will always show `"number-of-entries" => 0`
