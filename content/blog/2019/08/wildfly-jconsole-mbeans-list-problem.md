title=Wildfly JMX connection problems (so slow and terminates)
date=2019-08-19
type=post
tags=wildfly, jmx
status=published
~~~~~~
JMX (Java Management Extensions ) - is a technology that provide us possibility to monitoring applications (application servers) by **MBeans (Managed Bean)** objects.
List of supported MBeans can be obtained by **JConsole** tool that already included to JDK. As JMX does not provide strong defined communication protocol, - implementations can be different depends on vendor.
For example, to connect to Wildfly Application Server you need to use included in distribution `jconsole.sh` script:
```java
<WFLY_HOME>/bin/jconsole.sh
```
or add `<WFLY_HOME>/bin/client/jboss-client.jar` to classpath:
```java
jconsole J-Djava.class.path=$JAVA_HOME\lib\tools.jar;$JAVA_HOME\lib\jconsole.jar;jboss-client.jar
```
By default, Wildfly uses `timeout = 60s` for **remote JMX connections**, after that connection will terminated:
![jconsole terminated connection](/img/2019-08-jmx-jconsole.png)
To change default timeout value, use `org.jboss.remoting-jmx.timeout` property:
```java
./jconsole.sh -J-Dorg.jboss.remoting-jmx.timeout=300
```
But increasing timeouts, is not always good solution. So, lets search for the reason of slowness. To construct list of MBeans, jconsole recursively requests ALL MBeans, that can be extremely slow in case many deployments and many loggers. (Reported issue: [WFCORE-3186](https://issues.jboss.org/browse/WFCORE-3186)). Partial solution here is reducing count of log files by changing rotating type from `periodic-size-rotating-file-handler `  to `size-rotating-file-handler`.

Other reason of extremely slowness can be `Batch subsystem (JBeret)`. Last one stores a lot of working information in their tables (in memory or on remote DB, depends on configuration). If this tables big enough - it can negative affect performance of server. So, if you, no need for this data then just cleanup this stuff periodically. (for example, every redeploy in case you do it often enough):
```java
TRUNCATE TABLE PARTITION_EXECUTION CASCADE;
TRUNCATE TABLE STEP_EXECUTION CASCADE;
TRUNCATE TABLE JOB_EXECUTION CASCADE;
TRUNCATE TABLE JOB_INSTANCE CASCADE;  
```

From other point of view, obtaining ALL MBeans is not good decision as well. So, just use tooling that allows to find MBeans by path.
