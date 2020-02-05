title=Logging for JPA SQL queries with Wildfly
date=2020-01-10
type=post
tags=jpa, sql, wildfly, logging
status=published
~~~~~~
Logging for real SQL queries is very important in case using any ORM solution, - as you never can be sure **which** and **how many** requests will send JPA provider to do `find`, `merge`, `query` or some other operation.

Wildfly uses Hibernate as JPA provider and provides few standard ways to enable SQL logging:

**1.** Add `hibernate.show_sql` property to your **persistence.xml** :
```java
<properties>
    ...
    <property name="hibernate.show_sql" value="true" />
    ...
</properties>
```
```java
INFO  [stdout] (default task-1) Hibernate: insert into blogentity (id, body, title) values (null, ?, ?)
INFO  [stdout] (default task-1) Hibernate: select blogentity0_.id as id1_0_, blogentity0_.body as body2_0_, blogentity0_.title as title3_0_ from blogentity blogentity0_ where blogentity0_.title=?
```

**2.** Enable `ALL` log level for `org.hibernate` category like:
```java
/subsystem=logging/periodic-rotating-file-handler=sql_handler:add(level=ALL, file={"path"=>"sql.log"}, append=true, autoflush=true, suffix=.yyyy-MM-dd,formatter="%d{yyyy-MM-dd HH:mm:ss,SSS}")
/subsystem=logging/logger=org.hibernate.SQL:add(use-parent-handlers=false,handlers=["sql_handler"])
/subsystem=logging/logger=org.hibernate.type.descriptor.sql.BasicBinder:add(use-parent-handlers=false,handlers=["sql_handler"])
```
```java
DEBUG [o.h.SQL] insert into blogentity (id, body, title) values (null, ?, ?)
TRACE [o.h.t.d.s.BasicBinder] binding parameter [1] as [VARCHAR] - [this is body]
TRACE [o.h.t.d.s.BasicBinder] binding parameter [2] as [VARCHAR] - [title]
DEBUG [o.h.SQL] select blogentity0_.id as id1_0_, blogentity0_.body as body2_0_, blogentity0_.title as title3_0_ from blogentity blogentity0_ where blogentity0_.title=?
TRACE [o.h.t.d.s.BasicBinder] binding parameter [1] as [VARCHAR] - [title]
```

**3.** Enable spying of SQL statements:
```java
/subsystem=datasources/data-source=ExampleDS/:write-attribute(name=spy,value=true)
/subsystem=logging/logger=jboss.jdbc.spy/:add(level=DEBUG)
```
```java
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [DataSource] getConnection()
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [Connection] prepareStatement(insert into blogentity (id, body, title) values (null, ?, ?), 1)
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [PreparedStatement] setString(1, this is body)
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [PreparedStatement] setString(2, title)
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [PreparedStatement] executeUpdate()
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [PreparedStatement] getGeneratedKeys()
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [ResultSet] next()
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [ResultSet] getMetaData()
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [ResultSet] getLong(1)
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [ResultSet] close()
...
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [DataSource] getConnection()
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [Connection] prepareStatement(select blogentity0_.id as id1_0_, blogentity0_.body as body2_0_, blogentity0_.title as title3_0_ from blogentity blogentity0_ where blogentity0_.title=?)
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [PreparedStatement] setString(1, title)
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [PreparedStatement] executeQuery()
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [ResultSet] next()
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [ResultSet] getLong(id1_0_)
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [ResultSet] wasNull()
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [ResultSet] getString(body2_0_)
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [ResultSet] wasNull()
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [ResultSet] getString(title3_0_)
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [ResultSet] wasNull()
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [ResultSet] next()
DEBUG [j.j.spy] java:jboss/datasources/ExampleDS [ResultSet] close()
```

So, from above we can see that variants **2** and **3** is most useful as allows to log queries with parameters. From other point of view - SQL logging can generate lot of unneeded debug information on production. To avoid garbage data in your log files, feel free to use **[Filter Expressions for Logging](https://access.redhat.com/documentation/en-us/red_hat_jboss_enterprise_application_platform/6.4/html/administration_and_configuration_guide/chap-the_logging_subsystem#Filter_Expressions_for_Logging)**
