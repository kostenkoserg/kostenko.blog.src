title= ORA-01795 and JPA function workaround
date=2020-11-27
type=post
tags=jakartaee, jpa, hibernate, oracle
status=published
~~~~~~
Few posts ago i wrote about Hibernate Interceptor to solve **[ORA-01795: maximum number of expressions in a list is 1000 error](https://kostenko.org/blog/2020/10/jpa-ora-01795-hibernate-interceptor.html)**. This way can be very helpful in case you got this limitation, but by some reasons not able to perform refactoring.

Another way to get it done with  **JPQL** is a **JPA function()**. We used similar approach to implement [JPA paging with COUNT(*) OVER()](https://kostenko.org/blog/2020/10/jpa-count-over.html).

So, let's see how less code we need to get it work with custom *`Dialect`*  workaround.

`Custom dialect:`
```java
public class MyOraDialect extends Oracle10gDialect {
    public MyOraDialect () {
        super();
        // sql tuples workaround
        registerFunction( "safeTupleIn", new VarArgsSQLFunction( StandardBasicTypes.INTEGER, "(", ",0),(", ",0)"));
        // custom SQLFunction workaround
        registerFunction( "safeIn", new SafeInFunction());
    }
}
```
`Usage example:`
```java
@Test
public void safeTupleIn1000Test() throws Exception {
     EntityManager em = Persistence.createEntityManagerFactory("myDSTestOra").createEntityManager();
     // this.generateTestData(em);
     ...
     Query query =  em.createQuery("SELECT b as post FROM OraBlogEntity b where (id, 0) in (function('safeTupleIn',:ids))", Tuple.class);
     query.setParameter("ids", idsList);
     List<Tuple> tpList = query.getResultList();
     System.out.println(tpList.size());
}
```
or bit cleaner:
```java
...
Query query =  em.createQuery("SELECT b as post FROM OraBlogEntity b where id in (function('safeIn', id, :ids))", Tuple.class);
query.setParameter("ids", idsList);
...
```

Result SQL in this case SQL tuples will looks like
```bash
Hibernate: select orablogent0_.id as id1_0_, orablogent0_.body as body2_0_, orablogent0_.title as title3_0_ from orablogentity orablogent0_ where (orablogent0_.id , 0) in ((?,0),(?,0),(?....)
```
In case custom SQLFunction implementation:
```bash
Hibernate: select orablogent0_.id as id1_0_, orablogent0_.body as body2_0_, orablogent0_.title as title3_0_ from orablogentity orablogent0_ where orablogent0_.id in (?,...,?) or orablogent0_.id in (?,...,?)
```

Below is simple example how custom **`org.hibernate.dialect.function.SQLFunction`** can be implemented.

```java
public class SafeInFunction implements SQLFunction {
    private final static int IN_CAUSE_LIMIT = 1000;
    ...
    @Override
    public String render(Type firstArgumentType, List arguments, SessionFactoryImplementor factory) throws QueryException {
        final StringBuilder buf = new StringBuilder();
        String fieldName = (String) arguments.get(0);
        for (int i = 1; i < arguments.size(); i++) {
            if (i % IN_CAUSE_LIMIT == 0) {
                buf.deleteCharAt(buf.length() - 1).append(") or ").append(fieldName).append(" in (");
            }
            buf.append("?,");
        }
        return buf.deleteCharAt(buf.length() - 1).toString();
    }
}
```

PS. Hibernate provides **`org.hibernate.dialect.Dialect`** method to overwrite
```java
/**
 * Return the limit that the underlying database places on the number of elements in an {@code IN} predicate.
 * If the database defines no such limits, simply return zero or less-than-zero.
 *
 * @return int The limit, or zero-or-less to indicate no limit.
 */
public int getInExpressionCountLimit() {
  return 0;
}
```
But unfortunately did not provides properly implementation yet and just throw warning
```bash
WARN: HHH000443: Dialect limits the number of elements in an IN predicate to 1000 entries.  However, the given parameter list [ids] contained 1111 entries, which will likely cause failures to execute the query in the database
```

Source code of described example available on [GitHub](https://github.com/kostenkoserg/ee-jpa-examples)
