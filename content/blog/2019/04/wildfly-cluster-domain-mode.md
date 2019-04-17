title=Wildfly domain mode cluster and load balancing from the box
date=2019-04-15
type=post
tags=Wildfly
status=published
~~~~~~

Wildfly Application Server provide us two possible modes to setup cluster environment for the Java EE applications.

1. **Standalone mode** - every standalone instance has its own management interface and configuration. You can manage one instance at a time. Configuration placed in `standalone.xml` file.

2. **Domain mode** - all Wildfly instances manage by special orchestration process called `domain controller`. Using domain controller you can manage group of servers. Also you can mange groups as well. Each servers group can has its own configuration, deployments etc. Configuration placed in `domain.xml` and `host.xml` files.
Example of a Wildfly server groups:
![wildfly-cluster-domain-mode](/img/2019-04-wildfly-cluster-domain-mode.png)


From the version 10 Wildfly adds support for using the `Undertow` subsystem as a load balancer. So, now all we need to build clustered infrastructure is Wildfly only. Let's do it.

Download latest version of application server from the https://wildfly.org/downloads/ and unzip distributive after. To run Wildfly in domain mode, please execute:
```java
kostenko@kostenko:/opt/wildfly-16.0.0.Final/bin$ ./domain.sh
```

Connect to the Wildfly CLI concole
```java
kostenko@kostenko:/opt/wildfly-16.0.0.Final/bin$ ./jboss-cli.sh -c
[domain@localhost:9990 /]
```
By default Wildfly run preconfigured server groups `main-server-group` and `other-server-group`, so we need cleanup existing servers:

```java
:stop-servers(blocking=true)
/host=master/server-config=server-one:remove
/host=master/server-config=server-two:remove
/host=master/server-config=server-three:remove
/server-group=main-server-group:remove
/server-group=other-server-group:remove
```
Create new server group and servers, using the `full-ha` profile so `mod_cluster` support is included:
```java
/server-group=backend-servers:add(profile=full-ha, socket-binding-group=full-ha-sockets)
/host=master/server-config=backend1:add(group=backend-servers, socket-binding-port-offset=100)
/host=master/server-config=backend2:add(group=backend-servers, socket-binding-port-offset=200)

#start the backend servers
/server-group=backend-servers:start-servers(blocking=true)

#add system properties (so we can tell them apart)
/host=master/server-config=backend1/system-property=server.name:add(boot-time=false, value=backend1)
/host=master/server-config=backend2/system-property=server.name:add(boot-time=false, value=backend2)
```
Then  set up the server group for load balancer
```java
/server-group=load-balancer:add(profile=load-balancer, socket-binding-group=load-balancer-sockets)
/host=master/server-config=load-balancer:add(group=load-balancer)
/socket-binding-group=load-balancer-sockets/socket-binding=modcluster:write-attribute(name=interface, value=public)
/server-group=load-balancer:start-servers
```

Now let's develop simple Java EE web application to show how it works
