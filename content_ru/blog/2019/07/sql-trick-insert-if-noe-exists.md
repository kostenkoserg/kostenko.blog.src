title=SQL хак. Вставить, если не сущетсвует
date=2019-07-24
type=post
tags=SQL
status=published
~~~~~~

Следующий SQL хак позволит вам выполнить условный `INSERT` для вашего запроса.

Например, давайте сделаем вставку, если записи ещё не будет существовать:

SQL:
```sql
INSERT INTO my_table (id, name)  
    SELECT 1, 'name' FROM dual  WHERE NOT EXISTS (SELECT 1 FROM my_table WHERE ID = 1);
```
