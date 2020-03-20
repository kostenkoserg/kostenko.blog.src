title=Slow SQL logging with JPA and Wildfly
date=2020-03-20
type=post
tags=sql, jpa, wildfly
status=published
~~~~~~
Recently I wrote about **[Logging for JPA SQL queries with Wildfly](https://kostenko.org/blog/2020/01/sql-spying-with-wildfly.html)**. In this post I'll show you how to configure **logging for slow SQL queries**.

Wildfly uses Hibernate as JPA provider. So, to enable **slow sql feature** you just need to provide `hibernate.session.events.log.LOG_QUERIES_SLOWER_THAN_MS` property in your **persistence.xml** :

```java
<properties>
    ...
    <property name="hibernate.session.events.log.LOG_QUERIES_SLOWER_THAN_MS" value="25"/>
    ...
</properties>    
```

To log slow queries to separate file, please configure logging like:
```bash
/subsystem=logging/periodic-rotating-file-handler=slow_sql_handler:add(level=INFO, file={"path"=>"slowsql.log"}, append=true, autoflush=true, suffix=.yyyy-MM-dd,formatter="%d{yyyy-MM-dd HH:mm:ss,SSS}")
/subsystem=logging/logger=org.hibernate.SQL_SLOW:add(use-parent-handlers=false,handlers=["slow_sql_handler"])
```

**Note!**
Described above functionality available since Hibernate version **5.4.5**, but latest for today **Wildfly 19** uses Hibernate version **5.3**.  Fortunately, if you can't wait to enjoy the latest version of Hibernate, you can use **[WildFly feature packs](https://docs.jboss.org/hibernate/orm/5.4/topical/html_single/wildfly/Wildfly.html)** to create a **custom server** with a different version of Hibernate ORM in few simple steps:

Create provisioning configuration file (provision.xml)
```xml
<server-provisioning xmlns="urn:wildfly:server-provisioning:1.1" copy-module-artifacts="true">
    <feature-packs>
	<feature-pack
		groupId="org.hibernate"
		artifactId="hibernate-orm-jbossmodules"
		version="${hibernate-orm.version}" />
	<feature-pack
		groupId="org.wildfly"
		artifactId="wildfly-feature-pack"
		version="${wildfly.version}" />
    </feature-packs>
</server-provisioning>
```
Create gradle build file (build.gradle)
```java
plugins {
  id "org.wildfly.build.provision" version '0.0.6'
}
repositories {
    mavenLocal()
    mavenCentral()
    maven {
        name 'jboss-public'
        url 'https://repository.jboss.org/nexus/content/groups/public/'
    }
}
provision {
    //Optional destination directory:
    destinationDir = file("wildfly-custom")

    //Update the JPA API:
    override( 'org.hibernate.javax.persistence:hibernate-jpa-2.1-api' ) {
        groupId = 'javax.persistence'
        artifactId = 'javax.persistence-api'
        version = '2.2'
    }
    configuration = file( 'provision.xml' )
    //Define variables which need replacing in the provisioning configuration!
    variables['wildfly.version'] = '17.0.0.Final'
    variables['hibernate-orm.version'] = '5.4.5.Final'
}
```
Build custom Wildfly version
```bash
gradle provision
```
Switch to a different Hibernate ORM slot in your persistence.xml
```java
<properties>
    <property name="jboss.as.jpa.providerModule" value="org.hibernate:5.4"/>
</properties>
```
Enjoy!
