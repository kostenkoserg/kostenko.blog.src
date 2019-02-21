title=Hibernate Search with Wildfly
date=2019-01-21
type=post
tags=Hibernate, Wildfly, JPA
status=published
~~~~~~

Hibernate Search is a powerful solution to implement full text search capabilities (like google or amazon) in your EE application. Under the hood it will use Apache Lucene directly or over Elasticsearch to build the index. Hibernate Search can be easy integrated with JPA, Hibernate ORM, Infinispan and other sources. If you are use Wildfly - you are lucky, - Hibernate Search already integrated with last one.

So, will see how it works on practice in few simple steps...

**1. Let's start with gradle project using EE and hibernate-search dependencies**
`build.gradle:`
```
apply plugin: 'java'
apply plugin: 'war'
sourceCompatibility = '1.8'
[compileJava, compileTestJava]*.options*.encoding = 'UTF-8'
repositories {
    mavenCentral()
}
dependencies {
    providedCompile 'javax:javaee-api:7.0'
    providedCompile group: 'org.hibernate', name: 'hibernate-entitymanager', version: '5.4.1.Final'
    providedCompile group: 'org.hibernate', name: 'hibernate-search-orm', version: '5.11.1.Final'
    testCompile group: 'log4j', name: 'log4j', version: '1.2.17'
    testCompile group: 'junit', name: 'junit', version: '4.10'
    testCompile group: 'org.hsqldb', name: 'hsqldb', version: '2.3.2'
    testCompile group: 'org.hibernate', name: 'hibernate-entitymanager', version: '5.4.1.Final'
    testCompile group: 'org.hibernate', name: 'hibernate-search-orm', version: '5.11.1.Final'
}
```
**2. Create standart JPA entity with hibernate-search annotations**
`src/main/java/org/.../BlogEntity.java:`
```
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

    public Long getId() {
        return id;
    }
    public void setId(Long id) {
        this.id = id;
    }
    public String getTitle() {
        return title;
    }
    public void setTitle(String title) {
        this.title = title;
    }
    public String getBody() {
        return body;
    }
    public void setBody(String body) {
        this.body = body;
    }
}
```
Main Hibernate Search annotations:

|Annotation    | Description|
| -----------  | ----------- |
|@Indexed      | Marks which entities shall be indexed; Allows override the index name. Only @Indexed entities can be searched.|
|@Field        | Marks an entity property to be indexed. Supports various options to customize the indexing format: `store` -  enum type indicating whether the value should be stored in the document. Defaults to `Store.NO` (Field value will not be stored in the index. Storing of values can be helpful to use projections and restore jbjects directly from index), `index` -  enum defining whether the value should be indexed or not. Defaults to `Index.YES` |
|@DocumentId   | Override the property being used as primary identifier in the index. Defaults to the property with JPA’s @Id. |
|@SortableField| Marks a property so that it will be indexed in such way to allow efficient sorting on it.|


**3. Add hibernate-search properties to persistence.xml**
`src/test/resources/META-INF/persistence.xml :`
```
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
