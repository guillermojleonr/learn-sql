# TRUNCATE Command

## Overview

The `TRUNCATE` command is used to remove all records from a table quickly. It deletes all rows but keeps the table structure and constraints intact. TRUNCATE is faster than DELETE because it does not generate individual row delete statements.

---

## Syntax

```sql
TRUNCATE TABLE TableName;
```

---

## Examples

### Truncate a Table

```sql
TRUNCATE TABLE Employees;
```

### Truncate with Identity Reset (SQL Server)

```sql
TRUNCATE TABLE Employees;
-- Next INSERT will start from IDENTITY seed (usually 1)
```

---

## TRUNCATE vs DELETE vs DROP

| Feature | TRUNCATE | DELETE | DROP |
|---------|----------|--------|------|
| **Removes** | All rows | Specific or all rows | Entire table |
| **Space** | Keeps table structure | Keeps space used | Releases all space |
| **Speed** | Very fast | Slower | Fast |
| **WHERE Clause** | No | Yes | N/A |
| **Triggers** | Not fired | Fired | N/A |
| **IDENTITY Reset** | Yes (to seed) | No | N/A |
| **Rollback** | Yes (in transaction) | Yes (in transaction) | Yes (in transaction) |
| **Locks** | Minimal | Can lock table | Full lock |

---

## Examples Comparing Operations

### Using DELETE

```sql
DELETE FROM Employees
WHERE DepartmentID = 5;
```

### Using TRUNCATE

```sql
TRUNCATE TABLE Employees;
-- Removes ALL rows
```

### Using DROP

```sql
DROP TABLE Employees;
-- Removes entire table structure
```

---

## Important Considerations

1. **No WHERE Clause** — TRUNCATE always removes all rows; you cannot specify conditions
2. **IDENTITY Reset** — IDENTITY(seed, increment) resets to its original seed value
3. **No Triggers** — TRUNCATE does not fire DELETE triggers
4. **Foreign Key Constraints** — Cannot TRUNCATE a table referenced by a foreign key
5. **Transaction Support** — Can be rolled back within a transaction

---

## Handling Foreign Key Constraints

If TRUNCATE fails due to foreign key constraints:

### Option 1: Disable Constraint

```sql
ALTER TABLE Orders
DISABLE TRIGGER ALL;

TRUNCATE TABLE Customers;

ALTER TABLE Orders
ENABLE TRIGGER ALL;
```

### Option 2: Drop and Recreate Constraint

```sql
ALTER TABLE Orders
DROP CONSTRAINT FK_Customers;

TRUNCATE TABLE Customers;

ALTER TABLE Orders
ADD CONSTRAINT FK_Customers
FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID);
```

### Option 3: Delete Instead

```sql
DELETE FROM Customers;
DBCC CHECKIDENT('Customers', RESEED, 0);
-- Manually reset IDENTITY if needed
```

---

## Best Practices

1. Use TRUNCATE when you need to remove all rows (faster than DELETE)
2. Remember TRUNCATE resets IDENTITY to seed value
3. Check for foreign key constraints before using TRUNCATE
4. Back up data before truncating production tables
5. Use transactions to protect critical operations
6. Document TRUNCATE operations for audit purposes
7. Consider using DELETE if you need to trigger business logic (triggers)
