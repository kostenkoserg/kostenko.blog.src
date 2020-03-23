title=Load huge amount of data with Jakarta EE Batch
date=2020-03-23
type=post
tags=jakartaee, jberet, wildfly, batch, jsr532
status=published
~~~~~~
Processing huge amount of data is a challenge for every enterprise system. Jakarta EE specifications provides useful approach to get it done through **Jakarta Batch** (JSR-352):

>Batch processing is a pervasive workload pattern, expressed by a distinct application organization and execution model. It is found across virtually every industry, applied to such tasks as statement generation, bank postings, risk evaluation, credit score calculation, inventory management, portfolio optimization, and on and on. Nearly any bulk processing task from any business sector is a candidate for batch processing.
Batch processing is typified by bulk-oriented, non-interactive, background execution. Frequently long-running, it may be data or computationally intensive, execute sequentially or in parallel, and may be initiated through various invocation models, including ad hoc, scheduled, and on-demand.
Batch applications have common requirements, including logging, checkpointing, and parallelization. Batch workloads have common requirements, especially operational control, which allow for initiation of, and interaction with, batch instances; such interactions include stop and restart.

One of the typical use case is a import data from different sources and formats to internal database. Below we will design sample application to import data, for example, from  `json` and `xml` files to the database and see how well structured it can be.

Using **Eclipse Red Hat CodeReady Studio plugin**, we can easily design our solution diagram:
![import batch diagram](/img/2020-02-jakarta-batch-import.png)

Jakarta Batch descriptor in this case will looks like:
`META-INF/batch-jobs/hugeImport.xml:`
```java
<?xml version="1.0" encoding="UTF-8"?>
<job id="hugeImport" xmlns="http://xmlns.jcp.org/xml/ns/javaee" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee http://xmlns.jcp.org/xml/ns/javaee/jobXML_1_0.xsd" version="1.0">
    <step id="fileSelector" next="decider">
        <batchlet ref="fileSelector">
            <properties>
                <property name="path" value="/tmp/files2import"/>
                <property name="extension" value="json,xml"/>
            </properties>
        </batchlet>
    </step>
    <decision id="decider" ref="myDecider">
        <next on="xml" to="xmlParser"/>
        <next on="json" to="jsonParser"/>
    </decision>
    <step id="xmlParrser" next="chunkProcessor">
        <batchlet ref="xmlParrser">
            <properties>
                <property name="itemClass" value="MyItem"/>
            </properties>
        </batchlet>
    </step>
    <step id="jsonParrser" next="chunkProcessor">
        <batchlet ref="jsonParrser">
            <properties>
                <property name="itemClass" value="MyItem"/>
            </properties>
        </batchlet>
    </step>
    <step id="chunkProcessor">
        <chunk>
            <reader ref="itemReader"/>
            <processor ref="mockItemProcessor"/>
            <writer ref="jpaItemWriter"/>
        </chunk>
        <partition>
            <plan partitions="5"></plan>
        </partition>
    </step>
</job>
```
So, now we need to implement each brick above and try to keep each batchlet independent as much as possible. As you can see from above our job consist from:

 * **fileSelector** - batchlet do file selection based on supported by configuration file extension
 * **decider** - decision maker, responsible for choosing right parser
 * **xml\jsonParser** - parser batchlets, responsible for file parsing to a list of items
 * **chunkProcessor** - items processing chunk(reader, processor and writer) that supports partitioning

 
