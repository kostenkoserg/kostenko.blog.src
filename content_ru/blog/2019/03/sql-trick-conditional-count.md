title=SQL хак. Условный COUNT для выражения  SELECT
date=2019-03-16
type=post
tags=SQL,JPA
status=published
~~~~~~

Для выполнения условной логики в SQL `SELECT`, можно использовать выражение `CASE`. Следующий SQL хак  позволит вам выполнить условный `count()` для вашего запроса.

Например, чтобы выбрать количество записей с `id > 5`:

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

Исходный код, доступен на  [GitHub](https://github.com/kostenkoserg/jpa-examples/blob/master/src/test/java/org/kostenko/example/jpa/JpaConditionalCountTest.java)
