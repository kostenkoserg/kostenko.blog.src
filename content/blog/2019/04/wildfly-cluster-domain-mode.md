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
