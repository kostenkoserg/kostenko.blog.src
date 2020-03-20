title=Slow SQL logging with JPA and Wildfly
date=2020-03-20
type=post
tags=sql, jpa, wildfly

~~~~~~
Recently I wrote about [Logging for JPA SQL queries with Wildfly](https://kostenko.org/blog/2020/01/sql-spying-with-wildfly.html). In this post I'll show you how to configure **logging for slow SQL queries**.

As JPA provider Wildfly uses Hibernate and to enable "slow sql feature" you just need to provide `hibernate.session.events.log.LOG_QUERIES_SLOWER_THAN_MS` property in your **persistence.xml** :

```java
<properties>
    ...
    <property name="hibernate.session.events.log.LOG_QUERIES_SLOWER_THAN_MS" value="25"/>
    ...
</properties>    
```

To log slow queries to separate file configure logging like
```bash
/subsystem=logging/periodic-rotating-file-handler=slow_sql_handler:add(level=INFO, file={"path"=>"slowsql.log"}, append=true, autoflush=true, suffix=.yyyy-MM-dd,formatter="%d{yyyy-MM-dd HH:mm:ss,SSS}")
/subsystem=logging/logger=org.hibernate.SQL_SLOW:add(use-parent-handlers=false,handlers=["slow_sql_handler"])
```

**Note!** Described above functionality available since Hibernate version **5.4.5**
