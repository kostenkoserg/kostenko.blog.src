title=Jakarta Batch garbage collection on Wildfly (Jberet)
date=2019-10-30
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
            <property name="sql" value="#{jobParameters['sql']}"/>
            <property name="sqlFile" value="#{jobParameters['sqlFile']}"/>
            <property name="jobExecutionSelector" value="#{jobParameters['jobExecutionSelector']}"/>
            <property name="keepRunningJobExecutions" value="#{jobParameters['keepRunningJobExecutions']}"/>
            <property name="purgeJobsByNames" value="#{jobParameters['purgeJobsByNames']}"/>
            <property name="jobExecutionIds" value="#{jobParameters['jobExecutionIds']}"/>
            <property name="numberOfRecentJobExecutionsToKeep" value="#{jobParameters['numberOfRecentJobExecutionsToKeep']}"/>
            <property name="jobExecutionIdFrom" value="#{jobParameters['jobExecutionIdFrom']}"/>
            <property name="jobExecutionIdTo" value="#{jobParameters['jobExecutionIdTo']}"/>
            <property name="withinPastMinutes" value="#{jobParameters['withinPastMinutes']}"/>
            <property name="jobExecutionEndTimeFrom" value="#{jobParameters['jobExecutionEndTimeFrom']}"/>
            <property name="jobExecutionEndTimeTo" value="#{jobParameters['jobExecutionEndTimeTo']}"/>
            <property name="batchStatuses" value="#{jobParameters['batchStatuses']}"/>
            <property name="exitStatuses" value="#{jobParameters['exitStatuses']}"/>
            <property name="jobExecutionsByJobNames" value="#{jobParameters['jobExecutionsByJobNames']}"/>            </properties>
        </batchlet>
    </step>
</job>
```
