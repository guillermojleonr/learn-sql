# Transactions Guide

## 1. Introduction
Transactions guarantee **atomicity**, **consistency**, **isolation**, and **durability** (ACID). They let you group multiple statements so they either all succeed or all roll back.

---

## 2. Basic Syntax (ANSI‑SQL)
```sql
BEGIN TRANSACTION;   -- optional keyword `BEGIN` in many DBMS
-- one or more DML statements
COMMIT;              -- makes changes permanent
-- OR
ROLLBACK;            -- discards all changes made in the transaction
```
- `BEGIN` and `START TRANSACTION` are synonyms in MySQL/MariaDB.
- In PostgreSQL you can also write `BEGIN;`.
- SQL Server uses `BEGIN TRANSACTION` (or just `BEGIN TRAN`).

---

## 3. SAVEPOINT (Partial Rollback)
```sql
BEGIN TRANSACTION;
INSERT INTO accounts(id, balance) VALUES (1, 1000);
SAVEPOINT sp1;                     -- mark a point
UPDATE accounts SET balance = balance - 200 WHERE id = 1;
-- decide something went wrong
ROLLBACK TO SAVEPOINT sp1;        -- undo only the last update
COMMIT;                           -- keep the original insert
```
- Supported by PostgreSQL, MySQL (5.6+), SQLite, Oracle. SQL Server uses `SAVE TRANSACTION`.

---

## 4. Nested / Transaction Savepoints
### PostgreSQL – Savepoints act as lightweight nested transactions
```sql
BEGIN;
SAVEPOINT outer;
   INSERT ...;
   SAVEPOINT inner;
   UPDATE ...;   -- can roll back to inner only
   ROLLBACK TO SAVEPOINT inner;
COMMIT;            -- commits outer level
```
### SQL Server – `SAVE TRANSACTION` + `BEGIN TRAN` can be nested
```sql
BEGIN TRAN OuterTran;
    INSERT ...;
    SAVE TRAN InnerTran;
    UPDATE ...;   -- can roll back to InnerTran
    ROLLBACK TRAN InnerTran;   -- rolls back to inner point
COMMIT TRAN OuterTran;
```
> **Note:** True nested transactions (independent commit/rollback) are not supported in most RDBMS; savepoints are the portable alternative.

---

## 5. Transaction Control Statements by Dialect
| Feature | MySQL / MariaDB | PostgreSQL | SQL Server (T‑SQL) | Oracle |
|---|---|---|---|---|
| Start | `START TRANSACTION;` / `BEGIN;` | `BEGIN;` | `BEGIN TRAN;` | `BEGIN;` |
| Commit | `COMMIT;` | `COMMIT;` | `COMMIT TRAN;` | `COMMIT;` |
| Rollback | `ROLLBACK;` | `ROLLBACK;` | `ROLLBACK TRAN;` | `ROLLBACK;` |
| Savepoint | `SAVEPOINT name;` | `SAVEPOINT name;` | `SAVE TRAN name;` | `SAVEPOINT name;` |
| Rollback to Savepoint | `ROLLBACK TO SAVEPOINT name;` | `ROLLBACK TO SAVEPOINT name;` | `ROLLBACK TRAN name;` | `ROLLBACK TO SAVEPOINT name;` |
| Isolation Levels | `SET SESSION TRANSACTION ISOLATION LEVEL …;` | `SET TRANSACTION ISOLATION LEVEL …;` | `SET TRANSACTION ISOLATION LEVEL …;` | `SET TRANSACTION ISOLATION LEVEL …;` |

---

## 6. Isolation Levels (What they mean)
- **READ UNCOMMITTED** – dirty reads allowed.
- **READ COMMITTED** – no dirty reads (default in most DBMS).
- **REPEATABLE READ** – same rows read repeatedly give same result.
- **SERIALIZABLE** – full isolation, behaves as if transactions run sequentially.
```sql
-- Example (PostgreSQL)
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM accounts WHERE id = 1;
-- … other statements …
COMMIT;
```

---

## 7. Best‑Practice Checklist
- **Always** start a transaction when performing more than one write operation.
- **Never** rely on implicit commits; be explicit.
- Use **`SAVEPOINT`** if you need partial rollbacks in a long transaction.
- **Test** the transaction logic with a `SELECT` first to verify the `WHERE` clause.
- Keep transactions **short** to reduce lock contention.
- Prefer **`READ COMMITTED`** unless you have a specific need for higher isolation.
- Wrap bulk updates in **chunks** (`LIMIT`, `TOP`) to avoid long‑running locks.
- Log the transaction outcome (e.g., affected rows) for auditability.

---

## 8. Real‑World Example – Money Transfer (Two‑Phase Update)
```sql
-- PostgreSQL example
BEGIN;
-- withdraw from source account
UPDATE accounts
SET balance = balance - 250
WHERE id = 42 AND balance >= 250;
-- ensure exactly one row was updated
IF FOUND THEN
    -- deposit into destination account
    UPDATE accounts
    SET balance = balance + 250
    WHERE id = 84;
    COMMIT;
ELSE
    ROLLBACK;  -- insufficient funds
END IF;
```
- The `FOUND` check is PostgreSQL‑specific; other DBMS use `ROW_COUNT()` or `@@ROWCOUNT`.

---

## 9. Resources
- [SQL Transaction Management – PostgreSQL Docs](https://www.postgresql.org/docs/current/tutorial-transactions.html)
- [MySQL Transactions](https://dev.mysql.com/doc/refman/8.0/en/commit.html)
- [SQL Server Transaction Management](https://learn.microsoft.com/sql/t-sql/language-elements/transactions-transact-sql)
- [Oracle Transaction Control](https://docs.oracle.com/en/database/oracle/oracle-database/19/sqlrf/START-TRANSACTION.html)
- [ACID Properties – Wikipedia](https://en.wikipedia.org/wiki/ACID_(computer_science))

---

*End of Transactions Guide*
