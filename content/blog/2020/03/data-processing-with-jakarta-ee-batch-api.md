title=Load huge amount of data with Jakarta EE Batch
date=2020-03-25
type=post
tags=jakartaee, jberet, wildfly, batch, jsr532, jaxb, json-b
status=published
~~~~~~
Processing huge amount of data is a challenge for every enterprise system. Jakarta EE specifications provides useful approach to get it done through **[Jakarta Batch](https://projects.eclipse.org/projects/ee4j.batch)** (JSR-352):

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
        <batchlet ref="fileSelectorBatchlet">
            <properties>
                <property name="path" value="/tmp/files2import"/>
            </properties>
        </batchlet>
    </step>
    <decision id="decider" ref="myDecider">
        <next on="xml" to="xmlParser"/>
        <next on="json" to="jsonParser"/>
    </decision>
    <step id="xmlParser" next="chunkProcessor">
        <batchlet ref="xmlParserBatchlet"/>
    </step>
    <step id="jsonParser" next="chunkProcessor">
        <batchlet ref="jsonParserBatchlet"/>
    </step>
    <step id="chunkProcessor">
        <chunk>
            <reader ref="itemReader"/>
            <processor ref="itemMockProcessor"/>
            <writer ref="itemJpaWriter"/>
        </chunk>
        <partition>
            <plan partitions="5"></plan>
        </partition>
    </step>
</job>
```
So, now we need to implement each brick above and try to keep each batchlet independent as much as possible. As you can see from above our sample job consist from:

 * **fileSelector** - batchlet do file selection based on supported by configuration file extension
 * **decider** - decision maker, responsible for choosing right parser
 * **xml\jsonParser** - parser batchlets, responsible for file parsing to a list of items
 * **chunkProcessor** - items processing chunk(**reader**, optional **processor** and **writer**) with partitioning to boost performance

Before start with implementation, let's design useful solution to **share state between steps**. Unfortunately, Jakarta Batch Specification does not provide job scoped CDI beans yet (JBeret implementation does, specification doesn't). But we able to use **`JobContext.set\getTransientUserData()`** to deal with the current batch context. In our case we want to share `File` and `Queue` with  items for processing:
```java
@Named
public class ImportJobContext {
    @Inject
    private JobContext jobContext;

    private Optional<File> file = Optional.empty();
    private Queue<ImportItem> items = new ConcurrentLinkedQueue<>();

    public Optional<File> getFile() {
        return getImportJobContext().file;
    }
    public void setFile(Optional<File> file) {
        getImportJobContext().file = file;
    }
    public Queue<ImportItem> getItems() {
        return getImportJobContext().items;
    }

    private ImportJobContext getImportJobContext() {
        if (jobContext.getTransientUserData() == null) {
            jobContext.setTransientUserData(this);
        }
        return (ImportJobContext) jobContext.getTransientUserData();
    }
}
```

Now we can inject our custom **`ImportJobContext`** to share type-safe state between batchlets. First step is search file for processing by provided in step properties path:

```java
@Named
public class FileSelectorBatchlet extends AbstractBatchlet {

    @Inject
    private ImportJobContext jobContext;

    @Inject
    @BatchProperty
    private String path;

    @Override
    public String process() throws Exception {
        Optional<File> file = Files.walk(Paths.get(path)).filter(Files::isRegularFile).map(Path::toFile).findAny();
        if (file.isPresent()) {
            jobContext.setFile(file);
        }
        return BatchStatus.COMPLETED.name();
    }
}
```
After we need to make decision about parser, for example, based on extension. Decider just returns file extension as string and then  **batch runtime**  should give control to the corresponding parser batchlet. Please, check `<decision id="decider" ref="myDecider">` section in the XML batch descriptor above.
```java
@Named
public class MyDecider implements Decider {

    @Inject
    private ImportJobContext jobContext;

    @Override
    public String decide(StepExecution[] ses) throws Exception {
        if (!jobContext.getFile().isPresent()) {
            throw new FileNotFoundException();
        }
        String name = jobContext.getFile().get().getName();
        String extension = name.substring(name.lastIndexOf(".")+1);
        return extension;
    }
}
```
ParserBatchlet in turn should parse file using **JSON-B** or **JAXB** depends on type and fill Queue with **`ImportItem`** objects. I would like to use **`ConcurrentLinkedQueue`** to share items between partitions, but if you need for some other behavior here, you can provide **`javax.batch.api.partition.PartitionMapper`** with your own implementation
```java
@Named
public class JsonParserBatchlet  extends AbstractBatchlet {

    @Inject
    ImportJobContext importJobContext;

    @Override
    public String process() throws Exception {

        List<ImportItem> items = JsonbBuilder.create().fromJson(
                new FileInputStream(importJobContext.getFile().get()),
                new ArrayList<ImportItem>(){}.getClass().getGenericSuperclass());

        importJobContext.getItems().addAll(items);
        return BatchStatus.COMPLETED.name();
    }
}
```
ItemReader then will looks as simple as possible, just pool item from the Queue:
```java
@Named
public class ItemReader  extends AbstractItemReader {

    @Inject
    ImportJobContext importJobContext;

    @Override
    public ImportItem readItem() throws Exception {

        return importJobContext.getItems().poll();
    }
}
```
And persist time...
```java
@Named
public class ItemJpaWriter  extends AbstractItemWriter  {

    @PersistenceContext
    EntityManager entityManager;

    @Override
    public void writeItems(List<Object> list) throws Exception {
        for (Object obj : list) {
            ImportItem item = (ImportItem) obj;
            entityManager.merge(item);
        }
    }
}
```
Actually, this is it! Now we able to easily extend our application with new parsers, processors and writers without any existing code changes,  - just describe new (update existing) flows over Jakarta Batch descriptor.
Of course, **Jakarta Batch specification** provides much more helpful functionality than i have covered in this post (**Checkpoints**, **Exception Handling**, **Listeners**, **Flow Control**, **Failed job restarting** etc.), but even it enough to see how simple, power and well structured it can be.


**Note!** **Wildfly Application Server** implements Jakarta Batch specification through the **batch-jberet subsystem**. By default last one configured to use only **10** threads.
```xml
<subsystem xmlns="urn:jboss:domain:batch-jberet:2.0">
    ...
    <thread-pool name="batch">
        <max-threads count="10"/>
        <keepalive-time time="30" unit="seconds"/>
    </thread-pool>
</subsystem>
```
So, if you are planing intensive usage of **Batch runtime** - feel free to increase this parameter:
```bash
/subsystem=batch-jberet/thread-pool=batch/:write-attribute(name=max-threads, value=100)
```
Described sample application source code available on [GitHub](https://github.com/kostenkoserg/ee-batch-processing-examples)
