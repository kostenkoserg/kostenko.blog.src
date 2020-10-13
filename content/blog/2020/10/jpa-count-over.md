title=Jakarta EE JPA paging and COUNT(*) OVER()
date=2020-10-02
type=post
tags=jakartaee, jpa, hibernate
status=published
~~~~~~

![pager](/img/2020-10-pager.png)

Almost all data related applications and UI\UX practices need for paging. Jakarta EE JPA specification helps to do it on backend side  by providing simple **Query API:**

  * **`setFirstResult(int startPosition)`** - Set the position of the first result to retrieve.
  * **`setMaxResults(int maxResult)`** -  Set the maximum number of results to retrieve.

Typically, to implement paging with JPA you need for two queries: one to **select page** and second to **select total count** to calculate count of pages. It works well with simple queries and well described in many articles. But real world enterprise application often enough operates with complex queries with complex filters on big amount of data and unfortunately **second query is not for free** here from performance point of view.

Fortunately, since **JPA 2.1** developers can use **`function()`** to call not standard DB functions. Let's play around it to use power of database window functions and JPA usability.

Actually, in case Hibernate JPA provider all we need is register our custom function for our custom dialect like:
```java
public class MyOraDialect extends Oracle10gDialect {
    public MyOraDialect () {
        super();
        registerFunction("countover", new SQLFunctionTemplate(StandardBasicTypes.INTEGER, "count(*) over()"));
    }
}
```
and use dialect above in the our application `persistence.xml`:
```xml
  <property name="hibernate.dialect" value="org.kostenko.example.jpa.dialect.MyOraDialect"/>
```

Looks so easy, - time to test!

```java
public class OraTest {
    @Test
    public void countOver() throws Exception {
        EntityManager em = Persistence.createEntityManagerFactory("myDSTestOra").createEntityManager();
        this.generateTestData(em);
        Query query =  em.createQuery("SELECT b as post, function('countover') as cnt FROM OraBlogEntity b", Tuple.class);
        query.setFirstResult(10);
        query.setMaxResults(5);
        List<Tuple> tpList = query.getResultList();
        for (Tuple tp : tpList) {
            System.out.println(tp.get("post"));
            System.out.println("Total:" + tp.get("cnt"));
        }
    }
    ...
}
```
Output:
```bash
Hibernate: select * from ( select row_.*, rownum rownum_ from ( select orablogent0_.id as col_0_0_, count(*) over() as col_1_0_, orablogent0_.id as id1_0_, orablogent0_.body as body2_0_, orablogent0_.title as title3_0_ from orablogentity orablogent0_ ) row_ where rownum <= ?) where rownum_ > ?
OraBlogEntity{id=151, title=title7, body=body7}
Total:3003
OraBlogEntity{id=152, title=title8, body=body8}
Total:3003
...
```

Please, note: **count(*) over()** construction is not supported by **all** RDBMS, but in turn supports by Oracle, Postgres, MSSQL Server and others.

Source code of described example as usual available on [GitHub](https://github.com/kostenkoserg/ee-jpa-examples)
