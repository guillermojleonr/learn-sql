# UPDATE Guide

## 1. Basic UPDATE

*Use when you need to modify one or more columns of rows that meet a specific condition. Ideal for simple field changes.*
```sql
UPDATE table_name
SET column1 = expression1
WHERE condition;
```
- Updates rows that satisfy `WHERE`. Without `WHERE` all rows change.

## 2. Updating Multiple Columns

*Use to change several columns in a single statement, reducing round‑trips. Helpful when the new values depend on each other.*
```sql
UPDATE employees
SET first_name = 'John',
    salary = salary * 1.05
WHERE department = 'Sales';
```

## 3. UPDATE with ORDER BY & LIMIT (MySQL / MariaDB)
```sql
UPDATE products
SET price = price * 0.9
WHERE discontinued = 0
ORDER BY last_sold ASC
LIMIT 10;
```
- Useful for batch processing.

## 4. UPDATE with TOP (SQL Server)

*Use to limit the number of affected rows, often together with an ORDER BY (via a sub‑query) to process the most recent or highest‑priority records.*
```sql
UPDATE TOP (100) dbo.Orders
SET status = 'Processed'
WHERE status = 'Pending';
```

## 5. UPDATE with JOIN / FROM (MySQL, PostgreSQL, SQL Server)

*Used when the new values depend on data from another table. Joins let you correlate rows across tables in a single statement.*
### MySQL / MariaDB
```sql
UPDATE orders o
JOIN customers c ON o.customer_id = c.id
SET o.status = 'VIP'
WHERE c.is_vip = 1;
```
### PostgreSQL (using FROM)
```sql
UPDATE orders o
SET status = 'VIP'
FROM customers c
WHERE o.customer_id = c.id AND c.is_vip = true;
```
### SQL Server
```sql
UPDATE o
SET o.status = 'VIP'
FROM dbo.Orders o
JOIN dbo.Customers c ON o.customer_id = c.id
WHERE c.is_vip = 1;
```

## 6. UPDATE with Sub‑query (Scalar)

*Ideal for setting a column based on an aggregate or derived value calculated from the same or another table.*
```sql
UPDATE employees e
SET salary = (
    SELECT AVG(salary)
    FROM employees
    WHERE department = e.department
) 
WHERE e.role = 'Junior';
```

## 7. UPDATE with EXISTS

*Employ when you only want to update rows that have related rows in another table. The EXISTS check is efficient because it stops at the first match, compared to a JOIN when you only need to check for existence.*
```sql
UPDATE products p
SET discontinued = 1
WHERE EXISTS (
    SELECT 1 FROM orders o
    WHERE o.product_id = p.id AND o.status = 'Cancelled'
);
```

## 8. UPDATE with CASE (Conditional Logic)

*Use CASE to apply different update expressions according to row‑level conditions, avoiding multiple statements.*
```sql
UPDATE employees
SET bonus = CASE 
    WHEN performance = 'A' THEN salary * 0.15
    WHEN performance = 'B' THEN salary * 0.10
    ELSE salary * 0.05
END;
```

## 9. UPDATE with CTE (Common Table Expression) – PostgreSQL, SQL Server, Oracle 12c+

*CTE makes complex updates readable and reusable, especially when the new values come from a separate query that you want to reference multiple times.*
```sql
WITH salary_adjust AS (
    SELECT id, salary * 1.07 AS new_salary
    FROM employees
    WHERE tenure > 5
)
UPDATE e
SET e.salary = sa.new_salary
FROM salary_adjust sa
WHERE e.id = sa.id;
```

## 10. UPDATE … RETURNING (Supported Engines)

*Returns the affected rows directly, useful for immediate verification or chaining results without a second SELECT.*
```sql
UPDATE employees
SET salary = salary * 1.05
WHERE department = 'HR'
RETURNING id, salary;
```
- Returns the affected rows for further processing.

### Engines supporting `RETURNING` in UPDATE
| Engine | Version | Syntax notes |
|--------|---------|--------------|
| PostgreSQL | 8.2+ | `UPDATE ... SET ... WHERE ... RETURNING column1, column2;` |
| SQLite | 3.35.0+ | Same syntax, returns rows |
| MySQL | 8.0.21+ | `UPDATE ... SET ... WHERE ... RETURNING column1, column2;` |
| Oracle | 12c Release 2+ | Uses `RETURNING column1, column2 INTO :var1, :var2;` |
| MariaDB | 10.5+ | `UPDATE ... RETURNING` experimental (available from 10.5.2) |

*Note:* SQL Server does not implement `RETURNING`; instead it provides an `OUTPUT` clause with similar functionality.

- Returns the affected rows for further processing.

## 11. UPDATE with Alias (All dialects support)

*Aliases simplify queries when the same table appears multiple times or to improve readability in complex statements.*
```sql
UPDATE emp AS e
SET e.title = 'Lead Engineer'
WHERE e.id = 42;
```

## 12. MERGE (SQL Server, Oracle, PostgreSQL 15+)

*MERGE combines INSERT, UPDATE, and DELETE in one atomic operation, perfect for synchronizing a target table with a source set.*
*MERGE* can perform INSERT, UPDATE, DELETE in a single statement; shown for completeness.
```sql
MERGE INTO target t
USING source s
ON (t.id = s.id)
WHEN MATCHED THEN
    UPDATE SET t.value = s.value
WHEN NOT MATCHED THEN
    INSERT (id, value) VALUES (s.id, s.value);
```

```sql
MERGE INTO target t
USING source s
ON (t.id = s.id)
WHEN MATCHED THEN
    UPDATE SET t.value = s.value
WHEN NOT MATCHED BY TARGET THEN
    INSERT (id, value) VALUES (s.id, s.value)
WHEN NOT MATCHED BY SOURCE THEN
    DELETE;  -- elimina filas del objetivo que ya no existen en la fuente
```

---
### Best Practices
- **Always** use a `WHERE` clause unless you truly intend to modify every row.
- Test updates first with a `SELECT` using the same `WHERE` criteria.
- Wrap bulk updates in a transaction so you can `ROLLBACK` on error.
- Prefer `RETURNING`/`OUTPUT` clauses to verify changes without a second query.
- Use proper indexing on columns used in JOINs and WHERE conditions to avoid full table scans.
- For massive batch updates, consider updating in chunks (`LIMIT`/`TOP`) to reduce lock contention.

---
### Resources
- [SQL UPDATE Syntax – W3Schools](https://www.w3schools.com/sql/sql_update.asp)
- [PostgreSQL UPDATE Documentation](https://www.postgresql.org/docs/current/sql-update.html)
- [MySQL UPDATE Syntax](https://dev.mysql.com/doc/refman/8.0/en/update.html)
- [SQL Server UPDATE (Transact‑SQL)](https://learn.microsoft.com/sql/t-sql/queries/update-transact-sql)
