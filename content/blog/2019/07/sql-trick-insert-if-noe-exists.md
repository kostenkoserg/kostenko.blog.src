title=SQL trick. Insert if not exists
date=2019-07-24
type=post
tags=SQL
status=published
~~~~~~

Next SQL trick allows you perform conditional `INSERT` with your query.

For example, lets do insert if record not exists yet:

SQL:
```sql
INSERT INTO my_table (id, name)  
    SELECT 1, 'name' FROM dual  WHERE NOT EXISTS (SELECT 1 FROM my_table WHERE ID = 1);
```
