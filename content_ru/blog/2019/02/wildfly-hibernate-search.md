title=Hibernate Search вступление. Развертывание на WildFly.
date=2019-02-21
type=post
tags=Hibernate, Wildfly, JPA
status=published
~~~~~~

Hibernate  Search - это мощное решение для реализации возможностей полнотекстового поиска (как google или  amazon) в вашем ЕЕ приложении. Под капотом, для построения индекса, будет использоваться Apache Lucene напрямую, или через Elasticsearch. Hibernate Search может быть легко интегрирован с JPA, Hibernate ORM, Infinispan или другими источниками. Если вы используете Wildfly - вам повезло, - Hibernate Search с ним уже интегрирован.

Итак, посмотрим, как это работает на практике ...

**1.Давайте начнем с gradle проекта, используя hibernate-search и EE зависимости**
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
**2. Создадим стандартную сущность JPA c Hibernate Search аннотациями **
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

Основные аннотации Hibernate Search:

|Аннотация    | Описание|
| -----------  | ----------- |
|@Indexed      | Помечает, какие объекты должны быть индексированы; Позволяет переопределению имя индекса. Только объекты @Indexed могут быть найдены..|
|@Field        | Помечает поле объекта, которое будет индексировано. Существует несколько вариантов работы с индексируемыми полями: `store` -  перечислимый тип, указывающий, должно ли значение поля быть сохранено в индексе. По умолчанию - `Store.NO` (Значение поля не будет сохранено в индексе.) Хранение значений может быть полезным для использования в механизме Projections,- что позволит восстанавливать значения полей непосредственно из индекса, минуя запросы к СУБД, `index` -  перечисление, определяющее, следует ли индексировать поле или нет. По умолчанию - `Index.YES` |
|@DocumentId   | Позволяет переопределить идентификатор документа в индексе. По-умолчанию используется поля помеченное JPA-аннотацией @Id. |
|@SortableField| Помечает что индексируемое поле может быть сортируемым.|


**3. Добавьте свойства hibernate-search в persistence.xml**
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
Как мы могли убедиться, добавить Hibernate Search в свое приложение достаточно легко, - всего пара аннотаций. Теперь Hibernate Search автоматически будет создавать индекс каждый раз, когда объект, будет изменен (создан, удален) через Hibernate ORM. Индекс может быть сохранен в `ram` или `filesystem`. Другие поставщики, также доступны.

Итак, пора сделать простой тест и посмотреть, как это работает с **Lucene queries**

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
В тесте, мы использовали основные юзкейсы. Но даже этого достаточно, чтобы почувствовать насколько `Apache Lucene search engine` неплох. И увидеть, как легко его можно интегрировать с вашим приложением. Обратитесь к [официальной документации](https://docs.jboss.org/hibernate/stable/search/reference/en-US/html_single/) для детелей.

**4. Использование Hibernate Search с Wildfly**

Как я уже писал - Hibernate Search интегрирован в  Wildfly начиная с версии 10. Это означает, что эта функциональность активируется автоматически в случае, если вы используете по крайней мере одну ентити с `org.hibernate.search.annotations.Indexed`.
Итак, все что нам нужно, чтобы показать как это работает вместе, - это просто реализовать простой веб-сервис с похожей на юнит тест логикой и запустить его на сервере.

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
Теперь, давайте добавим таск в наш `build.gradle` для запуска  Wildfly прямо из проекта
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
`run` разархивирует wildfly в каталог проекта, задеплоит приложение и запустит сервер. Итак:
```bash
gradle && gradle run
```
проверим вывод, чтобы убедиться, что Hiberate создал Index соглсно  пути в  `persistence.xml`
```bash
...
15:15:37,386 INFO  [org.hibernate.search.store.impl.DirectoryProviderHelper] (MSC service thread 1-3) HSEARCH000041: Index directory not found, creating: '/tmp/index2/org.kostenko.example.wildfly.hibernatesearch.BlogEntity'
...
```
И, наконец, смотрим на результат в браузере
![create_index](/img/2019-02-hibernate-search-1.png)
![serach_by_index](/img/2019-02-hibernate-search-2.png)

Исходный код проекта, доступен на [GitHub](https://github.com/kostenkoserg/wildfly-hibernate-search-example)
