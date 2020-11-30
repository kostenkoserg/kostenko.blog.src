title=Infinispan Server as Wildfly remote cache container for your Jakarta EE application
date=2020-11-29
type=post
tags=jakartaee, wildfly, infinispan, jcache
status=published
~~~~~~
![pager](/img/2020-11-wildfly-infinispan-server-1.png)

Recently i wrote a few articles about [using infinispan cache](https://kostenko.org/tags/infinispan.html) based on Wildfly infinispan subsystem. But even though Wildfly provides well cache containers management support, - from the high load and high availability points of view, make sense to take a look to separate clustered cache instances.

**PROS:**

  * Heap, threads, GC pauses separated between application and cache containers.
  * Application or cache can be scaled separately depends on needs
  * More configuration possibilities (like ASYNC replication etc)
  * Minimizing affect of application to cache distribution and visa verse
  * Application containers restart keeps stored cache data

**CONS:**

 * Increase infrastructure complexity
 * Additional support and monitoring unit
 * Additional costs in case separate cache cloud nodes

Fortunately, with Wildfly Application Server it easy enough to **switch between embedded and remote cache containers** even in runtime (just another JNDI lookup). So, let's try it out! And first, we need to download  stable **[infinispan server release](https://infinispan.org/download-archive/)**. I have chosen **10.1.8** as my Wildfly 20 uses this one and  potential compatibility issues should be excluded.

After download, please extract distribution archive and run infinispan server
```bash
kostenko@kostenko:/opt/infinispan-server-10.1.8.Final/bin$ ./server.sh
```
By default infinispan server will use port **11222** on **127.0.0.1**. To bind another IP just use **-b** binding parameter like **`-b 0.0.0.0`** on startup.

To create named cache you can use provided UI (http://127.0.0.1:11222/) or cli console like
```bash
/opt/iplatform/infinispan/bin/cli.sh
[disconnected]> connect
create cache --template=org.infinispan.REPL_ASYNC myremotecache
```

Now let's perform Wildfly configuration to use remote cache container

```bash
/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=ispn1:add(host=127.0.0.1, port=11222)
batch
/subsystem=infinispan/remote-cache-container=myRemoteContainer:add(default-remote-cluster=data-grid-cluster)
/subsystem=infinispan/remote-cache-container=myRemoteContainer/remote-cluster=data-grid-cluster:add(socket-bindings=[ispn1])
run-batch
```
Actually, we just have finished with environment configuration and now we are ready for application development. As usual, **Jakarta EE**  **`build.gradle`** looks pretty laconical:
```java
apply plugin: 'war'
dependencies {
    providedCompile "jakarta.platform:jakarta.jakartaee-api:8.0.0"
    providedCompile "org.infinispan:infinispan-core:10.1.8.Final"
    providedCompile "org.infinispan:infinispan-client-hotrod:10.1.8.Final"
}
```
To use configured cache container just inject registered **@Resource**:
```java
@Named
public class TestCacheService {

    public static final String REMOTE_CACHE_NAME = "myremotecache";

    @Resource(lookup = "java:jboss/infinispan/remote-container/myRemoteContainer")
    org.infinispan.client.hotrod.RemoteCacheContainer remoteCacheContainer;

    public void putRemoteCache(String key, String value) {
        remoteCacheContainer.getCache(REMOTE_CACHE_NAME).put(key, String.format("%s (%s)", value, new Date()));
    }

    public Object getRemoteCache(String key) {
        return remoteCacheContainer.getCache(REMOTE_CACHE_NAME).get(key);
    }
}
```
Also, you can provide resource reference by **`WEB-INF/web.xml`** descriptor and use shorter resource lookup **by name** like `@Resource(name = "myremotecontainer")`

```xml
<resource-env-ref>
    <resource-env-ref-name>myremotecontainer</resource-env-ref-name>
    <lookup-name>java:jboss/infinispan/remote-container/myRemoteContainer</lookup-name>
</resource-env-ref>
```
Last thing we need, - is provide module dependencies by **`MANIFEST.MF`**:
```java
Manifest-Version: 1.0
Dependencies: org.infinispan, org.infinispan.commons, org.infinispan.client.hotrod export
```

OR through **`jboss-deployment-structure.xml`** :

```xml
<jboss-deployment-structure>
   <deployment>
      <dependencies>
         <module name="org.infinispan" export="TRUE" />
         <module name="org.infinispan.commons" export="TRUE" />
         <module name="org.infinispan.client.hotrod" export="TRUE" />
      </dependencies>
   </deployment>
</jboss-deployment-structure>
```

This is it! Build, deploy, and test it out.

```bash
curl -o - "http://localhost:8080/jcache-examples/jcache/ispn-remote-put?key=KEY1&value=VALUE1"
ok
curl -o - "http://localhost:8080/jcache-examples/jcache/ispn-remote-get?key=KEY1"
VALUE1 (Sat Nov 28 20:48:51 EET 2020)
```
To check remote cache container statistics you can use UI or  Infinispan **CLI** console:
```bash
[disconnected]> connect
cd caches
stats myremotecache
```
```bash
{
  "time_since_start" : 23866,
  "time_since_reset" : 23866,
  "current_number_of_entries" : 1,
  "current_number_of_entries_in_memory" : 1,
  "total_number_of_entries" : 1,
  "off_heap_memory_used" : 0,
  ...
```

Last point i would like to pay attention is cache container **height availability** with **`Infinispan clustering`**.  By default, Infinispan uses MPING (multicast) protocol to cluster auto discovery. You can easy check it just by running another ISPN instances on some network. For example:
```bash
$ cd <ISPN_HOME>
$ cp -r server server2
$ bin/server.sh -o 100 -s server2

$ bin/cli.sh
connect
describe
```
```bash
{
  "version" : "10.1.8.Final",
  ...
  "cluster_members_physical_addresses" : [ "127.0.0.1:7800", "127.0.0.1:7801" ],
  "cluster_size" : 2,
  ...
}
```
Do not forget to add new ISPN node to your Wildfly configuration
```bash
/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=ispn2:add(host=127.0.0.1, port=11322)
/subsystem=infinispan/remote-cache-container=myRemoteContainer/remote-cluster=data-grid-cluster:write-attribute(name=socket-bindings, value=[ispn1,ispn2])
```


Please, notice if you perform cloud deployment or have some network restrictions, - auto discovery with **MPING** can be not accessible. In this case you can use a **static list of IP addresses**  by providing  **TCPPING** configuration via **`server/conf/infinispan.xml`**. Just add `jgroups` section and edit `transport` stack for default `cache-container` :

```xml
<infinispan>

 <jgroups>
    <stack name="mytcpping">
      <TCP bind_port="7800" port_range="30" recv_buf_size="20000000" send_buf_size="640000"/>
      <TCPPING   initial_hosts="${jgroups.tcpping.initial_hosts:127.0.0.1[7800],127.0.0.1[7800]}"/>
      <MERGE3 />
      <FD_SOCK />
      <FD_ALL timeout="3000" interval="1000" timeout_check_interval="1000" />
      <VERIFY_SUSPECT timeout="1000" />
      <pbcast.NAKACK2 use_mcast_xmit="false" xmit_interval="100" xmit_table_num_rows="50" xmit_table_msgs_per_row="1024" xmit_table_max_compaction_time="30000" />
      <UNICAST3 xmit_interval="100" xmit_table_num_rows="50" xmit_table_msgs_per_row="1024" xmit_table_max_compaction_time="30000" />
      <pbcast.STABLE stability_delay="200" desired_avg_gossip="2000" max_bytes="1M" />
      <pbcast.GMS print_local_addr="false" join_timeout="${jgroups.join_timeout:2000}" />
      <UFC max_credits="4m" min_threshold="0.40" />
      <MFC max_credits="4m" min_threshold="0.40" />
      <FRAG3 />
    </stack>
  </jgroups>

   <cache-container name="default" statistics="true">
     <transport stack="mytcpping" node-name="${infinispan.node.name:}"/>
   </cache-container>
...
```
For more details about configuration, please refer to [WildFly 20 Infinispan Model Reference](https://docs.wildfly.org/20/wildscribe/subsystem/infinispan/remote-cache-container/index.html) and [Infinispan community documentation](https://infinispan.org/documentation/)

Source code of described example available on [GitHub](https://github.com/kostenkoserg/wildfly-infinispan-example)
