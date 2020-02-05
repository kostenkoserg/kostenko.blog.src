title=SQL trick. Conditional count for select clause
date=2019-03-16
type=post
tags=sql,jpa
status=published
~~~~~~

To perform conditional logic in your SQL `SELECT` clause you can use `CASE` expression. Next SQL trick allows you perform conditional `count()` with your query.

For example, to  select count of records with `id > 5`:

SQL:
```sql
SELECT SUM(CASE WHEN id > 5 THEN 1 ELSE 0 END) FROM Table
```

JPQL:
```java
entityManager.createQuery("SELECT SUM(CASE WHEN b.id > 5 THEN 1 ELSE 0 END) FROM BlogEntity b").getSingleResult()
```

Criteria API:
```java
CriteriaBuilder cb = em.getCriteriaBuilder();
CriteriaQuery<Number> query = cb.createQuery(Number.class);
Root<BlogEntity> blogEntity = query.from(BlogEntity.class);

query.select(
        cb.sum(
                cb.<Number>selectCase()
                        .when(cb.gt(blogEntity.get("id"), 5), 1)
                        .otherwise(0)
        )
);

Number result = em.createQuery(query).getSingleResult();
```

Test cases source code available on  [GitHub](https://github.com/kostenkoserg/jpa-examples/blob/master/src/test/java/org/kostenko/example/jpa/JpaConditionalCountTest.java)
