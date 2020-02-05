title=Wildfly. Configure load balancing metrics
date=2019-08-06
type=post
tags=wildfly
status=published
~~~~~~

Previously i wrote about [Wildfly domain mode cluster and load balancing from the box](https://kostenko.org/blog/2019/04/wildfly-cluster-domain-mode.html). But what if we would like to do balancing depends on specific server behavior ?

Wildfly subsystem `mod_cluster` provide us several predefined metric types to determine best request balancing:

  * **cpu**: based on CPU load
  * **mem**: based on system memory usage
  * **heap**: based on heap usage
  * **sessions**: based on number of web sessions
  * **requests**: based on amount of requests/sec
  * **send-traffic**: based on outgoing requests traffic
  * **receive-traffic**: based on incoming requests POST traffic
  * **busyness**: computes based on amount of Thread from Thread Pool usage that are busy servicing requests


As well you also can configure **weight** (impact of a metric respect to other metrics) and **capacity** properties;
Below is example, how to change default based on CPU balancing to balancing based on busyness + CPU:

```java
/subsystem=modcluster/mod-cluster-config=configuration/dynamic-load-provider=configuration/load-metric=cpu:remove()
/subsystem=modcluster/mod-cluster-config=configuration:add-metric(type=busyness,weight=2)
/subsystem=modcluster/mod-cluster-config=configuration:add-metric(type=cpu,weight=1)
```

If predefined types is not enough, - you can provide `custom-load-metric` by implementing `org.jboss.modcluster.load.metric.impl.AbstractLoadMetric`. To possibility of using your custom metric,- you need to copy packaged JAR to `modcluster` module and update `module.xml`. Now you can use your custom metric with your configuration like

```java
 <custom-load-metric class="org.kostenko.examples.wldfly.modcluster.MyBalancingMetric">  
```
