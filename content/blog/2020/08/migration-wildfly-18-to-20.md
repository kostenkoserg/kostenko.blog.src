title=Migration from Wildfly 18 to Wildfly 20
date=2020-08-06
type=post
tags=wildfly
status=published
~~~~~~
Some time ago i wrote article about migration from [Wildfly 10 to Wildfly 18 and application level migration issues](https://kostenko.org/blog/2019/10/migration-wildfly-10-to-18.html). Migration from Wildfly 18 to **Wildfly 20** does not provoke any application level issues and can be done in minutes:

```java
git clone https://github.com/wildfly/wildfly-server-migration.git
cd ./wildfly-server-migration/
mvn clean install
cd ./dist/standalone/target/
unzip jboss-server-migration-1.10.0-SNAPSHOT.zip
cd ./jboss-server-migration

./jboss-server-migration.sh -s /opt/wildfly-18.0.0.Final -t /opt/wildfly-20.0.1.Final/
```

**Why should i do migration to Wildfly 20 ?**

  * Supports the [Eclipse MicroProfile 3.3 platform specifications](https://download.eclipse.org/microprofile/microprofile-3.3/microprofile-spec-3.3.html)
  * Possible to use TLS 1.3 with WildFly when running against JDK 11 or higher.
  * RESTEasy (integrated in WildFly via the jaxrs subsystem) can now be configured using MicroProfile Config.
  * Many component upgrades and bug fixes
