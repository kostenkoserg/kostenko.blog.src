title= JPA and "ORA-01795: maximum number of expressions in a list is 1000 error" workaround
date=2020-10-13
type=post
tags=jakartaee, jpa, hibernate, oracle
status=published
~~~~~~
Oracle RDBMS has a known **1000 elements** limitation on count of parameters for the **`IN`** clause.
```sql
SELECT * FROM TABLE WHERE ID IN (?,?,?.....?)
```
In case count  of parameters more than 1000, - Oracle throws error: `ORA-01795: maximum number of expressions in a list is 1000 error`

Exists few ways to deal with it from the SQL point of view:

  * Split clause  `field IN (n1,...n9999)` to portions  like **`(field  IN (n1...n999) or field IN (n1000...n1999)...)`**   
  * Use temporary table to insert IDs and use sub select like **`field IN (select id from TMP_IDS)`**
  * Use tuples like **`where (id, 0) IN ((1, 0)...(n, 0))`**

Some data mapping frameworks provides solution for above by default, but unfortunately, **Hibernate** (most popular JPA provider) does not yet.

Fortunately, we can provide custom solution here by overriding **EmptyInterceptor.onPrepareStatement(String sql)** which is called when SQL string is being prepared and perform some String manipulation with the SQL.

First, we need for regular expression to find **IN** clause matches in the query. [regex101.com](https://regex101.com/) provides great help here
![pager](/img/2020-10-jpa-in-regexp-s.png)

Now we are ready to implement interceptor:
```java
public class SafeInInterceptor extends EmptyInterceptor {

    private final static Pattern pattern = Pattern.compile("[^\\s]+\\s+in\\s*\\(\\s*\\?[^\\(]*\\)", Pattern.CASE_INSENSITIVE);
    private final static int IN_CAUSE_LIMIT = 1000;

    @Override
    public String onPrepareStatement(String sql) {
        return super.onPrepareStatement(this.rewriteSqlToAvoidORA_01795(sql));
    }

    private String rewriteSqlToAvoidORA_01795(String sql) {
        Matcher matcher = pattern.matcher(sql);
        while (matcher.find()) {
            String inExpression = matcher.group();
            long countOfParameters = inExpression.chars().filter(ch -> ch == '?').count();

            if (countOfParameters <= IN_CAUSE_LIMIT) {
                continue;
            }

            String fieldName = inExpression.substring(0, inExpression.indexOf(' '));
            StringBuilder transformedInExpression = new StringBuilder(" ( ").append(fieldName).append(" in (");

            for (int i = 0; i < countOfParameters; i++) {
                if (i != 0 && i % IN_CAUSE_LIMIT == 0) {
                    transformedInExpression
                            .deleteCharAt(transformedInExpression.length() - 1)
                            .append(") or ").append(fieldName).append(" in (");
                }
                transformedInExpression.append("?,");
            }
            transformedInExpression.deleteCharAt(transformedInExpression.length() - 1).append("))");
            sql = sql.replaceFirst(Pattern.quote(inExpression), transformedInExpression.toString());
        }
        return sql;
    }
}
```

To enable interceptor, -  add next property to the your **`persistence.xml`**

```xml
<property name="hibernate.ejb.interceptor" value="org.kostenko.example.jpa.dialect.SafeInInterceptor" />
```

Time to test:

```java
@Test
public void transformSelectToSafeIn() throws Exception {
    EntityManager em = Persistence.createEntityManagerFactory("myDSTestOra").createEntityManager();

    List<Long> idsList = new ArrayList<>();
    for (int i = 0; i < 1199; i++) {
        idsList.add((long)i);
    }

    Query q =  
            em.createQuery("SELECT b FROM OraBlogEntity b WHERE b.id IN (:idsList)", OraBlogEntity.class)
            .setParameter("idsList", idsList);

    List<OraBlogEntity> blogEntitys = q.getResultList();
    System.out.println(blogEntitys.size());
}
```

Output:
```bash
Hibernate:select orablogent0_.id as id1_0_, orablogent0_.body as body2_0_, orablogent0_.title as title3_0_ from orablogentity orablogent0_
where  ( orablogent0_.id in (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
or orablogent0_.id in (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?))
```
As you can see SQL was splited. No source code changes required and no ORA-01795 anymore.

Source code of described example as usual available on [GitHub](https://github.com/kostenkoserg/ee-jpa-examples)