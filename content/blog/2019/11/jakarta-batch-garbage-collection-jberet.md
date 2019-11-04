title=Jakarta Batch garbage collection with Jberet
date=2019-11-04
type=post
tags=Jakarta, Batch, Wildfly, Jberet
status=published
~~~~~~

To implement Jakarta Batch Specification Wildfly uses JBeret as implementation of JSR 352 (Batch Applications for the Java Platform). During processing, last one persists some working data to the memory, JDBC or another repository depends on configuration.

In case intensive usage it can collect lot of data and as result provoke some application server performance issues. To cleanup  **unwanted job data** you can design your own solution or use provided by Jberet [org.jberet.repository.PurgeBatchlet](https://docs.jboss.org/jberet/1.3.0.Final/javadoc/jberet-core/org/jberet/repository/PurgeBatchlet.html) in standard way:
```java
<job id="batchGarbageCollector" xmlns="http://xmlns.jcp.org/xml/ns/javaee"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee http://xmlns.jcp.org/xml/ns/javaee/jobXML_1_0.xsd"
     version="1.0">
    <step id="batchGarbageCollector.step1">
        <batchlet ref="org.jberet.repository.PurgeBatchlet">
            <properties>
                <property name="sqlFile" value="#{jobParameters['sqlFile']}"/>
            </properties>
        </batchlet>
    </step>
</job>
```
From the documentation `PurgeBatchlet` supports rich set of properties and looks pretty good, **BUT** on practice lot of them does not work as expected. I tried `numberOfRecentJobExecutionsToKeep` and `batchStatuses` on both WF repositories (inMemory and JDBC) and on both of them **it does not work** for me.

I am getting output like below, but garbage still was with me :(
```java
...
INFO  [org.jberet] (Batch Thread - 8) [] JBERET000023: Removing javax.batch.runtime.JobExecution 35256804
INFO  [org.jberet] (Batch Thread - 8) [] JBERET000023: Removing javax.batch.runtime.JobExecution 35256806
...
```
Good news is, that in case using JDBC repository job parameter `sqlFile` works as expected executes provided SQL... without any log outputs.

Source code of test application available on [GitHub](https://github.com/kostenkoserg/ee-batch-processing-examples)
