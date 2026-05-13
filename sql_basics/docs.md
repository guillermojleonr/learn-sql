# SQL Repository

This public repository contains various SQL code samples and queries used across different projects.

---

## Introduction

This document summarizes key SQL theory and concepts, compiled after completing a non-certified SQL course. It serves as a quick reference for occasional use.

> **Note:**  
> Today, most theory is accessed via AI or official documentation. To demonstrate SQL proficiency, consider obtaining a certification and referencing it in your resume, along with a skills chart indicating your certification progress.

---

## SQL Statement Structure

An SQL statement typically consists of:

- **Commands**
- **Clauses**
- **Operators**
- **Aggregate Functions**

At minimum, a valid SQL statement requires commands and clauses.

---

## Object Types

- **TABLE**
- **CONSTRAINT**
- **DATABASE**
- **TRIGGER**
- **TRANSACTION**
- **COLUMN**

---

## SQL Commands

### General

- `USE DatabaseName` — Switches the active database.

### DDL: Data Definition Language

- `CREATE ObjectType ObjectName` — Create tables, fields, indexes.
- `ALTER ObjectType ObjectName` — Modify tables or fields.
- `DROP ObjectType ObjectName` — Delete tables or indexes.
- `TRUNCATE` — Remove all records from a table.

### DML: Data Manipulation Language

- `SELECT` — Query records.
- `INSERT` — Load data into the database.
- `UPDATE` — Modify field values.
- `DELETE` — Remove records.
- `TRUNCATE` — Remove all records from a table.

### DCL: Data Control Language

- `GRANT` — Assign permissions.
- `REVOKE` — Remove permissions.

### TCL: Transaction Control Language

- `COMMIT` — Save changes.
- `ROLLBACK` — Undo changes.
- `SAVEPOINT` — Set a transaction savepoint.

---

## Clauses

- `FROM`
- `WHERE`
- `GROUP BY`
- `HAVING`
- `ORDER BY`
- `JOIN`
- `LEFT JOIN`
- `RIGHT JOIN`
- `UNION` — Returns unique records only.
- `UNION ALL` — Returns all records, including duplicates.
- `ADD`

---

## Query Writing Order

1. `SELECT`
2. `FROM`
3. `WHERE`
4. `GROUP BY`
5. `HAVING`
6. `ORDER BY`

### Logical Processing Order

1. `FROM`
2. `ON`
3. `OUTER`
4. `WHERE`
5. `GROUP BY`
6. `CUBE` / `ROLLUP`
7. `HAVING`
8. `SELECT`
9. `DISTINCT`
10. `ORDER BY`
11. `TOP`

---

## Logical Operators

- `AND` — True if both conditions are true.
- `OR` — True if either condition is true.
- `NOT` — Negates the condition.

---

## Comparison Operators

- `<` — Less than
- `>` — Greater than
- `<>` — Not equal to
- `<=` — Less than or equal to
- `>=` — Greater than or equal to
- `BETWEEN` — Range
- `LIKE` — Pattern matching (wildcards)
- `IN` — Match any value in a list

---

## Aggregate Functions

Used in `SELECT` statements to return a single value for a group of records:

- `AVG()` — Average value
- `COUNT()` — Number of records (ignores NULLs)
- `SUM()` — Total sum
- `MAX()` — Highest value
- `MIN()` — Lowest value

---

## Calculation Queries & Common Functions

- `NOW()` — Current date and time
- `DATEDIFF()` — Difference between dates
- `DATE_FORMAT()` — Format date values
- `CONCAT()` — Concatenate strings
- `ROUND()` — Round numeric values

**Calculated Fields:**  
`FieldName AS FieldExpression`

---

## Constraints

- `PRIMARY KEY`
- `FOREIGN KEY REFERENCES TableName(FieldName)`
    - `ON UPDATE {CASCADE, SET NULL, NO ACTION}`
    - `ON DELETE {CASCADE, SET NULL, NO ACTION}`
- `CHECK (ConstraintExpression)`
- `WITH CHECK (ConstraintExpression)`
- `NOT NULL`
- `UNIQUE`
- `IDENTITY (InitialNumber, Step)` — Auto-incrementing fields; increments even if transaction fails to avoid concurrency issues.
- `DEFAULT (DefaultValue)`

---

## Aliases

- `AS` — Rename fields in `SELECT` queries.

---

## Character Set

Defines allowed characters (alphabet, numbers, accents, etc.). Incorrect settings may cause data truncation.

- `utf8_spanish_ci` — Modern Spanish, includes Ñ between N and O.
- `utf8_spanish2_ci` — Traditional Spanish, includes CH and LL.

> To apply a character set to all tables and columns, use the "Change the collation of all columns in all tables" option in phpMyAdmin.

---

## Collation

Determines how characters are compared and sorted (e.g., whether Ñ and N are treated as the same).

---

## Data Types

| Type         | Range (Signed)                        | Range (Unsigned)           |
|--------------|---------------------------------------|----------------------------|
| TinyInt      | -128 to 127                           | 0 to 255                   |
| SmallInt     | -32,768 to 32,767                     | 0 to 65,535                |
| Int          | -2,147,483,648 to 2,147,483,647       | 0 to 4,294,967,295         |
| BigInt       | -9,223,372,036,854,775,808 to 9,223...| 0 to 18,446,744,073,709... |
| Varchar(n)   | Variable-length string (n required)    |                            |
| Decimal(p,s) | Fixed precision and scale              |                            |

**Decimal/Numeric Details:**

- `p` (precision): Total digits (1–38, default 38)
- `s` (scale): Digits after decimal (0–p, default 0)

| Precision | Storage (bytes) |
|-----------|-----------------|
| 1–9       | 5               |
| 10–19     | 9               |
| 20–28     | 13              |
| 29–38     | 17              |

`NUMERIC` and `DECIMAL` are synonyms.

---

## Additional Constraints

- `UNSIGNED` — Use for numeric fields unless negatives are needed.
- `NULL` — Default unless specified otherwise.
- `NOT NULL`
- `PRIMARY KEY`
- `AUTO_INCREMENT` / `IDENTITY`
- `UNIQUE INDEX`SQL" is a public repository where I upload some SQL code.