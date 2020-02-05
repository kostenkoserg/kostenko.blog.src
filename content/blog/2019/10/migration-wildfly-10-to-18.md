title=Migration from Wildfly 10 to Wildfly 18
date=2019-10-22
type=post
tags=wildfly
status=published
~~~~~~

Usually vendors declares easy migration, provides how-to documentation and even migration tools. But depends on complexity of your application you can stuck with some compatibility issues. Below i will explain my Wildfliy 10 to Wildfliy 18 migration steps.

First of all you can use provided by WF [migration tool](https://github.com/wildfly/wildfly-server-migration) to migrate configuration files and compatible modules to the needed release:

```java
git clone https://github.com/wildfly/wildfly-server-migration.git
cd ./wildfly-server-migration/
mvn clean install
cd ./dist/standalone/target/
unzip jboss-server-migration-1.8.0.Final-SNAPSHOT.zip
cd ./jboss-server-migration

./jboss-server-migration.sh -s /opt/wildfly-10.1.0.Final -t /opt/wildfly-18.0.0.Final/
```
Now let's see application level migration issues:

Issue #1:
```java
Caused by: java.lang.IllegalArgumentException: org.hibernate.hql.internal.ast.QuerySyntaxException: Invalid path: 'org.kostenko.STATUS.ACTIVE'
```
Error above related to the Hibernate 5.2 [performance improvement](https://vladmihalcea.com/the-performance-penalty-of-class-forname-when-parsing-jpql-and-criteria-queries/) that avoids unnecessary calls to Class.forName(). Solution here is **using Java Naming conventions for a constant.** (for example rename STATUS to Status) or in case  using non-conventional Java constants set the
```java
<property name="hibernate.query.conventional_java_constants" value="false"/>
```
in your **persistence.xml**

Issue #2:

```java
java.lang.IllegalArgumentException: ArquillianServletRunner not found. Could not determine ContextRoot from ProtocolMetadata, please contact DeployableContainer developer.
```
In case using Arquillian you need just update version `org.wildfly.arquillian:wildfly-arquillian-container-managed` to version `2.2.0.Final`

Issue #3:
```java
org.jboss.weld.exceptions.UnsupportedOperationException:
  at org.jboss.weld.bean.proxy.CombinedInterceptorAndDecoratorStackMethodHandler.invoke(CombinedInterceptorAndDecoratorStackMethodHandler.java:49)
```
Seems to old [BUG](https://issues.jboss.org/browse/WELD-2407) happened and Weld does not support Java 8 default methods completely. So, pity but same refactoring here is needed.

Issue #4:
```java
WFLYRS0018: Explicit usage of Jackson annotation in a JAX-RS deployment; the system will disable JSON-B processing for the current deployment. Consider setting the 'resteasy.preferJacksonOverJsonB' property to 'false' to restore JSON-B.
...
javax.ws.rs.client.ResponseProcessingException: javax.ws.rs.ProcessingException: RESTEASY008200: JSON Binding deserialization error  
  at org.jboss.resteasy.client.jaxrs.internal.ClientInvocation.extractResult(ClientInvocation.java:156)  
  at org.jboss.resteasy.client.jaxrs.internal.ClientInvocation.invoke(ClientInvocation.java:473)  
  at org.jboss.resteasy.client.jaxrs.internal.ClientInvocationBuilder.get(ClientInvocationBuilder.java:195)  
```
Since latest versions, WF uses `org.eclipse.yasson` as **JSON-B** provider. It can provoke some compatibility problems in case using different  implementations. Solution here is refactoring according to the JSON-B specification or excluding `resteasy-json-binding-provider` from application class loader by providing `WEB-INF/jboss-deployment-structure.xml`:
```java
<?xml version="1.0" encoding="UTF-8"?>
<jboss-deployment-structure>
    <deployment>
        <exclusions>
            <module name="org.jboss.resteasy.resteasy-json-binding-provider"/>
        </exclusions>
    </deployment>
</jboss-deployment-structure>
```
or in case using EARs, do exclusion from submodules like
```java
<?xml version="1.0" encoding="UTF-8"?>
<jboss-deployment-structure>
    <deployment>
        <exclusions>
            <module name="org.jboss.resteasy.resteasy-json-binding-provider"/>
        </exclusions>
    </deployment>
    <sub-deployment name="module-1.jar">
        <exclusions>
            <module name="org.jboss.resteasy.resteasy-json-binding-provider"/>
        </exclusions>
    </sub-deployment>    
</jboss-deployment-structure>
```

Issue #5:
According to the fixed Hibernate [BUG](https://hibernate.atlassian.net/browse/HHH-11278), for now JPA call `setMaxResult(0)` **returns empty List** instead of **ALL** elements in previous versions. So, just check it and do some refactoring if needed.
