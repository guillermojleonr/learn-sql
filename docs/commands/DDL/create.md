# CREATE Command

## Overview

The `CREATE` command is used to create new database objects such as tables, fields, indexes, and databases.

---

## Syntax

```sql
CREATE ObjectType ObjectName (
    Column1 DataType Constraints,
    Column2 DataType Constraints,
    ...
);
```

---

## Examples

### Create a Table

```sql
CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    HireDate DATE DEFAULT GETDATE(),
    Salary DECIMAL(10, 2),
    DepartmentID INT FOREIGN KEY REFERENCES Departments(DepartmentID)
);
```

### Create a Table with Check Constraint

```sql
CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName VARCHAR(100) NOT NULL,
    Price DECIMAL(8, 2) CHECK(Price > 0),
    Stock INT CHECK(Stock >= 0)
);
```

### Create an Index

```sql
CREATE INDEX idx_Email ON Employees(Email);
```

### Create a Unique Index

```sql
CREATE UNIQUE INDEX idx_UniqueSku ON Products(SKU);
```

---

## Key Constraints Used with CREATE

- `PRIMARY KEY` — Uniquely identifies each record
- `FOREIGN KEY` — Links to another table
- `UNIQUE` — Ensures all values in the column are unique
- `NOT NULL` — Column must always have a value
- `DEFAULT` — Assigns a default value
- `CHECK` — Validates data based on a condition
- `IDENTITY(start, increment)` — Auto-incrementing field

---

## Best Practices

1. Always define a `PRIMARY KEY` for each table
2. Use appropriate data types to save storage space
3. Add `NOT NULL` constraints where data is required
4. Use meaningful names for tables and columns
5. Create indexes on columns frequently used in WHERE clauses
6. Document foreign key relationships clearly
