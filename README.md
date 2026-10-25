# University Research Management System

SQL Server database project for managing researchers, research projects, publications, supervision, and grant funding.

## Contents

- ERD and relational schema with 14 application tables.
- SQL exam solutions covering joins, subqueries, CTEs, aggregation, pagination, and window functions.
- Functions, stored procedures, views, indexes, triggers, and transactions.
- Database permissions exercises.

## Setup

1. Restore `UniversityResearchSystem.bak` on SQL Server 2022 or later.
2. Select the `UniversityResearchSystem` database.
3. Run the initial `SET` statements, then execute each question separately.
4. Verify sample IDs before running statements that modify data.

## Notes

- IDs use `VARCHAR(10)`.
- `sysdiagrams` is excluded from the 14 application tables.
- Use `ROLLBACK` when testing transactions without saving changes.
