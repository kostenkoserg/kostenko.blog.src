title=Distributed caching with Wildfly/Infinispan and poor JCache support.
date=2020-08-26
type=post
tags=jakartaee, wildfly, infinispan, jcache
status=published
~~~~~~

Latest trends teach us to do development of stateless applications, and if you can - keep your design stateless. But, by some reason, you may need to cache and share state between nodes.

It would be nice to have **[JSR 107: JCACHE - Java Temporary Caching API](https://jcp.org/en/jsr/detail?id=107)** support in Wildfly Application Server, but unfortunately, JCache still not a part of JakartaEE specification (i hope one day it will) and pity to realize that Wildfly does not support JCache by default.

From other point of view many well known vendors like [Hazelcast](https://hazelcast.org/), [Infinispan](https://infinispan.org/), [Ehcache](https://www.ehcache.org/) etc, supports JCache API as well. In turn significant Infinispan part integrated into Wildfly Application Server and can be used as distributed cache provider over  separate **[infinispan subsystem](https://docs.wildfly.org/20/wildscribe/subsystem/infinispan/index.html)** configuration.

So, let's design sample Jakarta EE application to see how **distrubuted cache** looks and works on practice.

First, we need for at least two node Wildfly cluster - please refer to my article about [Wildfly domain mode cluster and load balancing from the box](https://kostenko.org/blog/2019/04/wildfly-cluster-domain-mode.html). And then we are ready to configure distributed cache for our application:

```bash
/profile=full-ha/subsystem=infinispan/cache-container=mycachecontainer:add
/profile=full-ha/subsystem=infinispan/cache-container=mycachecontainer/distributed-cache=mycache:add
```

After simply server configuration above, we are ready to create our sample application. And as usual with Jakarta EE - **`build.gradle`** looks pretty simple and clear :

```java
apply plugin: 'war'
dependencies {
    providedCompile "jakarta.platform:jakarta.jakartaee-api:8.0.0"
    providedCompile "org.infinispan:infinispan-core:10.1.8.Final"
}
```

Now to use configured above `mycache` we need to register cache resource in the one from two ways :

```java
@Startup
@Singleton
@LocalBean
public class MyCacheResource {
    @Resource(lookup = "java:jboss/infinispan/cache/mycachecontainer/mycache")
    private org.infinispan.Cache<String, Object> myCache;
```

**OR** provide  resource reference in your **WEB-INF/web.xml** descriptor:

```xml
<web-app version="2.5"  xmlns="http://java.sun.com/xml/ns/javaee"  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://java.sun.com/xml/ns/javaee http://java.sun.com/xml/ns/javaee/web-app_2_5.xsd">
    <display-name>JCache API example</display-name>
    <resource-env-ref>
        <resource-env-ref-name>mycache</resource-env-ref-name>
        <lookup-name>java:jboss/infinispan/cache/mycachecontainer/mycache</lookup-name>
    </resource-env-ref>    
</web-app>
```

I personally prefer second one because it allows move vendor specific code and dependencies from application source level to the descriptor which is designed for. Actually, i recommend to use standard API as much as possible and **refer to custom vendor specific stuff very carefully**.

Also to help Wildfly avoid casting exception like **`java.lang.IllegalArgumentException: Can not set org.infinispan.Cache field to org.jboss.as.clustering.infinispan.DefaultCache`** we need to configure module dependencies over **MANIFEST.MF**:

```bash
Manifest-Version: 1.0
Dependencies: org.infinispan export
```

**OR** over **jboss-deployment-structure.xml** :

```xml
<jboss-deployment-structure>
   <deployment>
      <dependencies>
         <module name="org.infinispan" export="TRUE" />
      </dependencies>
   </deployment>
</jboss-deployment-structure>
```

And again, I prefer second way as **vendor specific descriptor is a right place for vendor specific stuff**.  Please refer to **[deployment module dependencies](https://access.redhat.com/documentation/en-us/jboss_enterprise_application_platform/6/html/development_guide/add_an_explicit_module_dependency_to_a_deployment1)** explanation for the details

Now when all preparation is complete, - let's implement simple service and JAX-RS resource to check how cache distribution works:

`TestCacheService.java:`
```java
@Named
public class TestCacheService {

    @Resource(name = "mycache")
    org.infinispan.Cache cache;

    public void putIspnCache(String key, String value) {
        cache.put(key, String.format("%s (%s)", value, new Date()));
    }

    public Object getIspnCache(String key) {
        return cache.get(key);
    }
}
```

`TestCacheEndpoint.java:`
```java
@Stateless
@ApplicationPath("/")
@Path("/jcache")
public class TestCacheEndpoint extends Application {

    @Inject
    TestCacheService service;

    @GET
    @Path("/ispn-put")
    public Response putIspn(@QueryParam("key") String key, @QueryParam("value") String value) {
        service.putIspnCache(key, value);
        return Response.ok("ok").build();
    }

    @GET
    @Path("/ispn-get")
    public Response getIspn(@QueryParam("key") String key) {
        return Response.ok(service.getIspnCache(key)).build();
    }
}    
```

Time to do deploy and test:
```bash
[domain@localhost:9990 /] deploy ~/work/kostenko/wildfly-infinispan-example/build/libs/jcache-examples.war --server-groups=backend-servers
```
```bash
curl -o - "http://localhost:8180/jcache-examples/jcache/ispn-put?key=KEY1&value=VALUE1"
ok
curl -o - "http://localhost:8280/jcache-examples/jcache/ispn-get?key=KEY1"
VALUE1 (Mon Aug 24 21:26:56 EEST 2020)
curl -o - "http://localhost:8280/jcache-examples/jcache/ispn-put?key=KEY2&value=VALUE2"
ok
curl -o - "http://localhost:8180/jcache-examples/jcache/ispn-get?key=KEY2"
VALUE2 (Mon Aug 24 21:27:52 EEST 2020)
```
As you can see from above, value we put on node1 available on node2 and vice versa. Even if we add new node to the cluster - cached values will be available on the fresh node as well:
```bash
[domain@localhost:9990 /] /host=master/server-config=backend3:add(group=backend-servers, socket-binding-port-offset=300)
[domain@localhost:9990 /] /host=master/server-config=backend3:start(blocking=true)
```
```bash
curl -o - "http://localhost:8380/jcache-examples/jcache/ispn-get?key=KEY2"
VALUE2 (Mon Aug 24 21:27:52 EEST 2020)
```

Great! So for now we able to share state between cluster members and, actually, this is enough for lot of typical use cases.
So, what about some  standardization of our application ? As was noticed above **JCache** can be helpful here, but unfortunately enabling last one on Wildfly is not trivial at all.

To get JCache worked you can patch your Wildfly Application Server with [Infinispan wildfly modules] (https://infinispan.org/download-archive/) or just put missed libraries to the your application and exclude transitive ones to avoid conflicts with libraries that already present in the Wildfly.

`build.gradle:`
```java
...
dependencies {
    providedCompile "jakarta.platform:jakarta.jakartaee-api:8.0.0"
    compile "javax.cache:cache-api:1.0.0"
    compile "org.infinispan:infinispan-jcache:10.1.8.Final"
    compile "org.infinispan:infinispan-cdi-embedded:10.1.8.Final"
}
configurations {
  runtime.exclude group: "org.infinispan", module: "infinispan-core"
  runtime.exclude group: "org.infinispan", module: "infinispan-commons"
  runtime.exclude group: "org.infinispan.protostream", module: "protostream"
}
```

`jboss-deployment-structure.xml:`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<jboss-deployment-structure>
    <deployment>
        <dependencies>
           <module name="org.infinispan" export="TRUE" />
           <module name="org.infinispan.commons" export="TRUE" />
           <module name="org.infinispan.protostream" export="TRUE" />
        </dependencies>
    </deployment>
</jboss-deployment-structure>
```

After that you should be able to use JCache in the usual way:

`TestCacheService.java:`

```java
...
@CacheResult(cacheName = "mycache")
public String getJCacheResult() {
    System.out.println("getJCacheResult");
    return new Date().toString();
}
...
```
`beans.xml:`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://xmlns.jcp.org/xml/ns/javaee" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee  http://xmlns.jcp.org/xml/ns/javaee/beans_1_1.xsd" bean-discovery-mode="all">
    <interceptors>
        <class>org.infinispan.jcache.annotation.CacheResultInterceptor</class>
    </interceptors>
</beans>
```

**@CacheResult** works and caching the result  **BUT it is not related to the configured on Wildfly `mycache` and ignores configured options** like lifespans, distributions etc because Infinispan's JCache CachingProvider implementation created caches from an Infinispan native configuration file (based on the provided URI, interpreted as a file path) instead of WF configuration.

I did some digging about possibility to produce custom JCache CachingProvider but unfortunately did not find any workable solution for it. Also refer to my post about [ispn distributed cache issues](https://kostenko.org/blog/2020/01/infinispan-distributed-cache-issues.html) workaround.

As usual, sample source code available on [GitHub](https://github.com/kostenkoserg/wildfly-infinispan-example)
