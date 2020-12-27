title=Improve Oracle JDBC performance by fetch size tuning
date=2020-12-28
type=post
tags=oracle, jdbc, performance, wildfly
status=published
~~~~~~
By default, when Oracle JDBC driver executes query, it retrieves a result set of **10 rows** at a time from the database cursor. Low fetch size value might cause more roundtrips to DB and this leads to a longer time to fetch results from queries. You can change the number of rows retrieved with each trip to the database cursor by changing the row fetch size value.

**Statement, PreparedStatement, CallableStatement**, and **ResultSet** provides next methods for dealing with fetch size:
```java
void setFetchSize(int rows) throws SQLException

int getFetchSize() throws SQLException
```

Default fetch size value  can be changed by **defaultRowPrefetch** connection property:

On Wildfly Application Server DataSource level by:
```bash
[standalone@localhost:9990 /] /subsystem=datasources/data-source=ExampleOraDS/connection-properties=defaultRowPrefetch:add(value=1000)
```

On Hibernate level by  **`hibernate.jdbc.fetch_size`** property:
```xml
<properties>
  ...
  <property name="hibernate.jdbc.fetch_size" value="1000" />
  ...
</properties>
```

I did simple test:
```java
@Test
public void defaultRowPrefetchTest() throws Exception {
   EntityManager em = Persistence.createEntityManagerFactory("myDSTestOra").createEntityManager();

   Long time = System.currentTimeMillis();

   Query q = em.createNativeQuery("SELECT * FROM MY_TABLE", Tuple.class);
   List<Tuple> resultList = q.getResultList();

   System.out.println(System.currentTimeMillis() - time);
}
```

And on my laptop, fetching of **16K** records takes **~185 ms** with default value and **~86 ms** with `defaultRowPrefetch = 20000`. As you can see from the result - there is more than **x2** performance improvement.

Source code of test case on [GitHub](https://github.com/kostenkoserg/ee-jpa-examples)
