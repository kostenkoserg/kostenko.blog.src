title=Migration from Wildfly 10 to Wildfly 18
date=2019-10-18
type=post
tags=Wildfly
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
```
java.lang.IllegalArgumentException: ArquillianServletRunner not found. Could not determine ContextRoot from ProtocolMetadata, please contact DeployableContainer developer.
```
In case using Arquillian you need just update version `org.wildfly.arquillian:wildfly-arquillian-container-managed` to version `2.2.0.Final`

Issue #3:
```java
org.jboss.weld.exceptions.UnsupportedOperationException:
  at org.jboss.weld.bean.proxy.CombinedInterceptorAndDecoratorStackMethodHandler.invoke(CombinedInterceptorAndDecoratorStackMethodHandler.java:49)
```
Seems to old Weld [bug
