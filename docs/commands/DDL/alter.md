# ALTER Command

## Overview

The `ALTER` command is used to modify existing database objects such as tables and fields. This allows you to add, modify, or delete columns and constraints without recreating the entire table.

---

## Syntax

```sql
ALTER TABLE TableName
ADD | MODIFY | DROP ColumnName DataType Constraints;
```

---

## Examples

### Add a New Column

```sql
ALTER TABLE Employees
ADD PhoneNumber VARCHAR(20);
```

### Add a Column with Default Value

```sql
ALTER TABLE Employees
ADD EmploymentStatus VARCHAR(20) DEFAULT 'Active';
```

### Add a NOT NULL Column with Default

```sql
ALTER TABLE Employees
ADD CreatedDate DATE DEFAULT GETDATE() NOT NULL;
```

### Modify an Existing Column

```sql
ALTER TABLE Employees
MODIFY Email VARCHAR(150) NOT NULL;
```
e
### Drop a Column

```sql
ALTER TABLE Employees
DROP COLUMN PhoneNumber;
```

### Add a Primary Key

```sql
ALTER TABLE Employees
ADD PRIMARY KEY (EmployeeID);
```

### Add a Foreign Key

```sql
ALTER TABLE Employees
ADD FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID);
```

### Add a Unique Constraint

```sql
ALTER TABLE Employees
ADD UNIQUE (Email);
```

### Add a Check Constraint

```sql
ALTER TABLE Employees
ADD CHECK (HireDate <= GETDATE());
```

### Drop a Constraint

```sql
ALTER TABLE Employees
DROP CONSTRAINT PK_Employees;
```

---

## Important Considerations

1. **Data Loss Risk** — Dropping columns removes all data in those columns
2. **Performance Impact** — Modifying large tables may lock them temporarily
3. **Constraint Dependencies** — Some modifications may fail if constraints exist
4. **NULL Values** — Adding NOT NULL columns to non-empty tables requires a DEFAULT value or backfill logic

---

## Best Practices

1. Test ALTER statements in a development environment first
2. Create a backup before modifying production tables
3. Use descriptive constraint names for easier management
4. Document all schema changes
5. Consider impact on dependent objects (views, stored procedures)
