title=Hibernate Search introduction. Deploying on WildFly.
date=2019-02-21
type=post
tags=hibernate, wildfly, jpa
status=published
~~~~~~

Hibernate Search is a powerful solution to implement full text search capabilities (like google or amazon) in your EE application. Under the hood it will use Apache Lucene directly or over Elasticsearch to build the index. Hibernate Search can be easy integrated with JPA, Hibernate ORM, Infinispan and other sources. If you are use Wildfly - you are lucky, - Hibernate Search already integrated with last one.

So, will see how it works on practice in few simple steps...

**1. Let's start with gradle project using EE and hibernate-search dependencies**
`build.gradle:`
```java
apply plugin: 'java'
apply plugin: 'war'

sourceCompatibility = '1.8'
defaultTasks 'clean', 'build'
ext.libraryVersions = [
    javaee                  : '8.0',
    wildfly                 : '15.0.1.Final',
    hibernatesearch         : '5.11.1.Final',
    hibernateentitymanager  : '5.4.1.Final',
    h2                      : '1.4.198',
    dom4j                   : '2.1.1',
    junit                   : '4.12'
]
configurations {
    wildfly
}
repositories {
    mavenCentral()
}
dependencies {
    wildfly "org.wildfly:wildfly-dist:${libraryVersions.wildfly}@zip"
    providedCompile "javax:javaee-api:${libraryVersions.javaee}"
    providedCompile "org.hibernate:hibernate-search-orm:${libraryVersions.hibernatesearch}"
    testCompile "junit:junit:${libraryVersions.junit}"
    testCompile "com.h2database:h2:${libraryVersions.h2}"
    testCompile "org.hibernate:hibernate-entitymanager:${libraryVersions.hibernateentitymanager}"
    testCompile "org.hibernate:hibernate-search-orm:${libraryVersions.hibernatesearch}"
    testCompile "org.dom4j:dom4j:${libraryVersions.dom4j}"
}
```
**2. Create standart JPA entity with hibernate-search annotations**
`src/main/java/org/.../BlogEntity.java:`
```java
package org.kostenko.example.wildfly.hibernatesearch;

import javax.persistence.*;
import org.hibernate.search.annotations.*;

@Entity
@Indexed
public class BlogEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column
    @Field(store = Store.YES)
    private String title;

    @Column
    @Field(store = Store.YES)
    private String body;

    // getters, setters
}
```

Main Hibernate Search annotations:

|Annotation    | Description|
| -----------  | ----------- |
|@Indexed      | Marks which entities shall be indexed; Allows override the index name. Only @Indexed entities can be searched.|
|@Field        | Marks an entity property to be indexed. Supports various options to customize the indexing format: `store` -  enum type indicating whether the value should be stored in the document. Defaults to `Store.NO` (Field value will not be stored in the index. Storing of values can be helpful to use projections and restore objects directly from index instead of mapped ORM entity), `index` -  enum defining whether the value should be indexed or not. Defaults to `Index.YES` |
|@DocumentId   | Override the property being used as primary identifier in the index. Defaults to the property with JPA’s @Id. |
|@SortableField| Marks a property so that it will be indexed in such way to allow efficient sorting on it.|


**3. Add hibernate-search properties to persistence.xml**
`src/test/resources/META-INF/persistence.xml :`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<persistence version="2.0" xmlns="http://java.sun.com/xml/ns/persistence" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://java.sun.com/xml/ns/persistence http://java.sun.com/xml/ns/persistence/persistence_2_0.xsd">
    <persistence-unit name="myDSTest" transaction-type="RESOURCE_LOCAL">
        <provider>org.hibernate.jpa.HibernatePersistenceProvider</provider>
        <class>org.kostenko.example.wildfly.hibernatesearch.BlogEntity</class>
        <exclude-unlisted-classes>false</exclude-unlisted-classes>
        <properties>
            <property name="hibernate.dialect" value="org.hibernate.dialect.HSQLDialect"/>
            <property name="hibernate.hbm2ddl.auto" value="create-drop"/>
            <property name="hibernate.connection.driver_class" value="org.hsqldb.jdbcDriver"/>
            <property name="hibernate.connection.username" value="sa"/>
            <property name="hibernate.connection.password" value=""/>
            <property name="hibernate.connection.url" value="jdbc:hsqldb:mem:testdb"/>
            <property name="hibernate.showSql" value="true"/>
            <!-- Hibernate Search -->
            <property name="hibernate.search.default.directory_provider" value="filesystem" />
            <property name="hibernate.search.default.indexBase" value="/tmp/index1" />
            <property name="hibernate.search.default.indexmanager" value="near-real-time" />
        </properties>
    </persistence-unit>
</persistence>
```
As you can see from above, it is easy enough (just with few annotations) add Hibernate Search into your application. Now Hibernate will automatically build index each time the entity persisted, updated or removed through Hibernate ORM. The index can be stored in `ram` or on  `filesystem`. Others directory providers also available - refer official documentation for details.

So, time to do simple test and see how it works with **Lucene queries**

`src/test/java/org/.../JpaHibernateSearchTest :`
```java
public class JpaHibernateSearchTest {

    private static EntityManager entityManager;
    private static FullTextEntityManager fullTextEntityManager;
    private static QueryBuilder queryBuilder;

    @BeforeClass
    public static void init() {
        entityManager = Persistence.createEntityManagerFactory("myDSTest").createEntityManager();
        fullTextEntityManager = Search.getFullTextEntityManager(entityManager);
        queryBuilder = fullTextEntityManager.getSearchFactory().buildQueryBuilder().forEntity(BlogEntity.class).get();
        for (int i = 0; i < 1000; i++) {
            BlogEntity blogEntity = new BlogEntity();
            blogEntity.setTitle("Title" + i);
            blogEntity.setBody("BodyBody Body" + i + " look at my horse my horse is a amazing " + i);
            entityManager.getTransaction().begin();
            entityManager.persist(blogEntity);
            entityManager.getTransaction().commit();
        }
        Assert.assertEquals(1000, entityManager.createQuery("SELECT COUNT(b) FROM BlogEntity b", Number.class).getSingleResult().intValue());
    }
    /**
     * Keyword Queries - searching for a specific word.
     */
    @Test
    public void shouldSearchByKeywordQuery() throws Exception {
        Query query = queryBuilder.keyword().onFields("title", "body").matching("Body999").createQuery();
        javax.persistence.Query persistenceQuery = fullTextEntityManager.createFullTextQuery(query, BlogEntity.class); // wrap Lucene query in a javax.persistence.Query
        List<BlogEntity> result = persistenceQuery.getResultList();// execute search
        Assert.assertFalse(result.isEmpty());
        Assert.assertEquals("Title999", result.get(0).getTitle());
    }
    /**
     * Fuzzy Queries - we can define a limit of “fuzziness”
     */
    @Test
    public void shouldSearchByFuzzyQuery() throws Exception {
        Query query = queryBuilder.keyword().fuzzy().withEditDistanceUpTo(2).withPrefixLength(0).onField("title").matching("TAtle999").createQuery();
        javax.persistence.Query persistenceQuery = fullTextEntityManager.createFullTextQuery(query, BlogEntity.class);
        List<BlogEntity> result = persistenceQuery.getResultList();
        Assert.assertFalse(result.isEmpty());
        Assert.assertEquals("Title999", result.get(0).getTitle());
    }
    /**
     * Wildcard Queries - queries for which a part of a word is unknown ('?' - single character, '*' - character sequence)
     */
    @Test
    public void shouldSearchByWildcardQuery() throws Exception {
        Query query = queryBuilder.keyword().wildcard().onField("title").matching("?itle*").createQuery();
        javax.persistence.Query persistenceQuery = fullTextEntityManager.createFullTextQuery(query, BlogEntity.class);
        List<BlogEntity> result = persistenceQuery.getResultList();
        Assert.assertFalse(result.isEmpty());
        Assert.assertEquals(1000, result.size());
    }
    /**
     * Phrase Queries - search for exact or for approximate sentences
     */
    @Test
    public void shouldSearchByPhraseQuery() throws Exception {
        Query query = queryBuilder.phrase().withSlop(10).onField("body").sentence("look amazing horse 999").createQuery();
        javax.persistence.Query persistenceQuery = fullTextEntityManager.createFullTextQuery(query, BlogEntity.class);
        List<BlogEntity> result = persistenceQuery.getResultList();
        Assert.assertFalse(result.isEmpty());
        Assert.assertEquals("Title999", result.get(0).getTitle());
    }

}
```
In the test above I used most basic use-cases. But even it enough to feel how power `Apache Lucene search engine` is. And how easy it can be integrated with your application.  Please, refer to [official documentation](https://docs.jboss.org/hibernate/stable/search/reference/en-US/html_single/) for advanced topics.

**4. Use Hibernate Search as Wildfly module**
As i already noticed - Hibernate Search included in Wildfly since version 10. It means that activation of this functionality is automatic in case you are using at least one entity with `org.hibernate.search.annotations.Indexed`. So, all we need to show how it works together is just implement simple web service with similar to test logic and run it on the server.

```java
@Path("/")
@Stateless
public class HibernateSearchDemoEndpoint {

    @PersistenceContext
    EntityManager entityManager;

    /**
     * Persist 1000 entities and rebuild index
     * @return
     */
    @GET
    @Path("/init")
    @Transactional
    public Response init() {
        int count = entityManager.createQuery("SELECT COUNT(b) FROM BlogEntity b", Number.class).getSingleResult().intValue();
        long time = System.currentTimeMillis();
        for (int i = count; i < count + 1000; i++) {
            BlogEntity blogEntity = new BlogEntity();
            blogEntity.setTitle("Title" + i);
            blogEntity.setBody("Body Body Body" + i + " look at my horse my horse is a amazing " + i);
            entityManager.persist(blogEntity);
        }
        time = System.currentTimeMillis() - time;
        return Response.ok().entity(String.format("1000 records persisted. Current records %s Execution time = %s ms.", count + 1000, time)).build();
    }

    /**
     * Search by index
     * @param q - query string
     * @return
     */
    @GET
    @Path("/search")
    public Response search(@QueryParam("q") String q) {
        FullTextEntityManager fullTextEntityManager = Search.getFullTextEntityManager(entityManager);
        QueryBuilder queryBuilder = fullTextEntityManager.getSearchFactory().buildQueryBuilder().forEntity(BlogEntity.class).get();
        long time = System.currentTimeMillis();
        Query query = queryBuilder.keyword().onFields("title", "body").matching(q).createQuery();
        javax.persistence.Query persistenceQuery = fullTextEntityManager.createFullTextQuery(query, BlogEntity.class);
        List<BlogEntity> result = persistenceQuery.getResultList();
        time = System.currentTimeMillis() - time;
        String resultStr = result.stream().map(Object::toString).collect(Collectors.joining(","));
        return Response.ok().entity( String.format("Found %s results. [%s] Execution time = %s ms.",result.size(),resultStr,time)).build();
    }
}
```
Now, let's add task  into our `build.gradle` to run Wildfly directly from the project
```java
task removeWildfly(type:Delete) {
    delete "build/wildfly-${libraryVersions.wildfly}"
}
task resolveWildfly(type:Copy, dependsOn:removeWildfly) {
    destinationDir = buildDir
    from {zipTree(configurations.wildfly.singleFile)}
}
task run() {
    dependsOn 'resolveWildfly'
    doLast {
        copy {
            from projectDir.toString() + "/build/libs/wildfly-hibernate-search-example.war"
            into projectDir.toString() + "/build/wildfly-${libraryVersions.wildfly}/standalone/deployments"
        }
        exec {
            workingDir = file(projectDir)
            commandLine "./build/wildfly-${libraryVersions.wildfly}/bin/standalone.sh", "--debug", "5005"
            ext.output = {
                return standardOutput.toString()
            }
        }
    }
}
```
`run` task above will unzip wildfly into project build directory, deploy application and start the server. So, to start - please do
```bash
gradle && gradle run
```
check output to be sure that Hiberate created Index directory by provided in `persistence.xml` path
```bash
...
15:15:37,386 INFO  [org.hibernate.search.store.impl.DirectoryProviderHelper] (MSC service thread 1-3) HSEARCH000041: Index directory not found, creating: '/tmp/index2/org.kostenko.example.wildfly.hibernatesearch.BlogEntity'                                  
...
```
and see result in the browser
![create_index](/img/2019-02-hibernate-search-1.png)
![serach_by_index](/img/2019-02-hibernate-search-2.png)

Example project source code available on [GitHub](https://github.com/kostenkoserg/wildfly-hibernate-search-example)
