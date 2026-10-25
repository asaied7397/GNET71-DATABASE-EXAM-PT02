USE UniversityResearchSystem;
GO

-- -- Required for indexed views and subsequent changes to their base tables.
-- SET ANSI_NULLS ON;
-- SET QUOTED_IDENTIFIER ON;
-- SET ANSI_PADDING ON;
-- SET ANSI_WARNINGS ON;
-- SET ARITHABORT ON;
-- SET CONCAT_NULL_YIELDS_NULL ON;
-- SET NUMERIC_ROUNDABORT OFF;
-- GO


/* =========================================================
   Question 1
   All researchers and their projects, including researchers
   who are not assigned to any project.
   ========================================================= */

-- SELECT
--     r.Id AS ResearcherId,
--     CONCAT_WS(
--         ' ',
--         r.FirstName,
--         NULLIF(r.MiddleName, ''),
--         r.LastName
--     ) AS ResearcherName,
--     p.Id AS ProjectId,
--     p.Title AS ProjectTitle,
--     w.Role,
--     w.HoursPerWeek
-- FROM dbo.Researcher AS r
-- LEFT JOIN dbo.WorksOn AS w
--     ON w.ResearcherId = r.Id
-- LEFT JOIN dbo.ResearchProject AS p
--     ON p.Id = w.ProjectId
-- ORDER BY r.Id, p.Id;
-- GO

-- /* =========================================================
--    Question 2
--    Projects with leader name/email, funded by at least one grant.
--    ========================================================= */

-- SELECT
--     p.Id AS ProjectId,
--     p.Title,
--     CONCAT_WS(
--         ' ',
--         r.FirstName,
--         NULLIF(r.MiddleName, ''),
--         r.LastName
--     ) AS LeaderName,
--     r.Email
-- FROM dbo.ResearchProject AS p
-- INNER JOIN dbo.Researcher AS r
--     ON r.Id = p.LeaderId
-- WHERE EXISTS (
--     SELECT 1
--     FROM dbo.Funds AS f
--     WHERE f.ProjectId = p.Id
-- )
-- ORDER BY p.Id;
-- GO

-- -- EXISTS avoids repeating a project when several grants fund it.


-- /* =========================================================
--    Question 3
--    All possible researcher/publication combinations.
--    ========================================================= */

-- SELECT
--     r.Id AS ResearcherId,
--     CONCAT_WS(
--         ' ',
--         r.FirstName,
--         NULLIF(r.MiddleName, ''),
--         r.LastName
--     ) AS ResearcherName,
--     p.Id AS PublicationId,
--     p.Title AS PublicationTitle
-- FROM dbo.Researcher AS r
-- CROSS JOIN dbo.Publication AS p
-- ORDER BY r.Id, p.Id;
-- GO

-- /*
-- A CROSS JOIN produces a Cartesian product.

-- Number of rows:
--     Researcher count * Publication count

-- For example:
--     100 researchers * 500 publications = 50,000 rows.

-- On large tables, this can consume substantial CPU, memory,
-- network bandwidth, and client resources.

-- These combinations do not indicate actual authorship.
-- */

-- /* =========================================================
--    Question 4
--    Supervisors, their supervised researchers, start date, role.
--    ========================================================= */

-- SELECT
--     s.SupervisorId,
--     CONCAT_WS(
--         ' ',
--         supervisor.FirstName,
--         NULLIF(supervisor.MiddleName, ''),
--         supervisor.LastName
--     ) AS SupervisorName,
--     s.SupervisedId,
--     CONCAT_WS(
--         ' ',
--         junior.FirstName,
--         NULLIF(junior.MiddleName, ''),
--         junior.LastName
--     ) AS SupervisedName,
--     s.SupervisionStartDate,
--     s.Role
-- FROM dbo.Supervises AS s
-- INNER JOIN dbo.Researcher AS supervisor
--     ON supervisor.Id = s.SupervisorId
-- INNER JOIN dbo.Researcher AS junior
--     ON junior.Id = s.SupervisedId
-- ORDER BY s.SupervisorId, s.SupervisedId;
-- GO

-- -- Researcher is joined twice because it participates in two roles.

-- /* =========================================================
--    Question 5
--    Researchers with publications but no active-project assignment.
--    ========================================================= */

-- SELECT *
-- FROM dbo.Researcher AS r
-- WHERE EXISTS (
--     SELECT 1
--     FROM dbo.Publishes AS a
--     WHERE a.ResearcherId = r.Id
-- )
-- AND NOT EXISTS (
--     SELECT 1
--     FROM dbo.WorksOn AS w
--     INNER JOIN dbo.ResearchProject AS p
--         ON p.Id = w.ProjectId
--     WHERE w.ResearcherId = r.Id
--       AND p.Status = 'Active'
-- )
-- ORDER BY r.Id;
-- GO

-- /* =========================================================
--    Question 6
--    Five most-cited publications, including ties at the fifth row.
--    ========================================================= */

-- SELECT *
-- FROM (
--     SELECT TOP (5) WITH TIES *
--     FROM dbo.Publication AS p
--     WHERE p.CitationCount IS NOT NULL
--     ORDER BY p.CitationCount DESC
-- ) AS ranked
-- ORDER BY ranked.CitationCount DESC, ranked.Id;
-- GO

-- /* =========================================================
--    Question 7
--    Second page of researchers, ten records per page.
--    ========================================================= */

-- SELECT *
-- FROM dbo.Researcher AS r
-- ORDER BY r.LastName, r.Id
-- OFFSET 10 ROWS
-- FETCH NEXT 10 ROWS ONLY;
-- GO

-- /* =========================================================
--    Question 8
--    TOP versus OFFSET-FETCH.
--    ========================================================= */

-- SELECT TOP (3)
--     *
-- FROM dbo.Researcher AS r
-- ORDER BY r.LastName, r.Id;

-- SELECT
--     *
-- FROM dbo.Researcher AS r
-- ORDER BY r.LastName, r.Id
-- OFFSET 0 ROWS
-- FETCH NEXT 3 ROWS ONLY;
-- GO

-- /*
-- Both queries request the first three rows in the specified order.

-- The original versions ordered only by LastName.
-- When LastName ties cross the cutoff, the selected researchers
-- are not guaranteed to be identical. Adding Id resolves this.

-- Advantages of OFFSET-FETCH:
-- 1. Supports skipping rows directly.
-- 2. Supports page-number/page-size pagination.
-- 3. Makes successive pages easier to express.

-- TOP additionally supports PERCENT and WITH TIES.

-- OFFSET-FETCH is not inherently faster. Deep offsets can require
-- SQL Server to scan and discard many preceding rows.
-- */


-- /* =========================================================
--    Question 9
--    Unique sequential index within each building, oldest first.
--    ========================================================= */

-- SELECT
--     r.Id AS ResearcherId,
--     r.FirstName,
--     r.MiddleName,
--     r.LastName,
--     r.Building,
--     r.DateOfBirth,

--     ROW_NUMBER() OVER (
--         PARTITION BY r.Building
--         ORDER BY r.DateOfBirth ASC, r.Id ASC
--     ) AS BuildingSequence

-- FROM dbo.Researcher AS r
-- ORDER BY r.Building, BuildingSequence;
-- GO

-- /* =========================================================
--    Question 10
--    Rank publications within each publication type.
--    ========================================================= */

-- SELECT
--     p.Title,
--     p.Type,
--     p.CitationCount,

--     RANK() OVER (
--         PARTITION BY p.Type
--         ORDER BY p.CitationCount DESC
--     ) AS CitationRank

-- FROM dbo.Publication AS p
-- ORDER BY p.Type, CitationRank, p.Id;
-- GO

-- /* =========================================================
--    Question 11
--    Rank projects by budget within each status.
--    ========================================================= */

-- SELECT
--     p.Id AS ProjectId,
--     p.Title,
--     p.Status,
--     p.Budget,

--     RANK() OVER (
--         PARTITION BY p.Status
--         ORDER BY p.Budget DESC
--     ) AS RankWithGaps,

--     DENSE_RANK() OVER (
--         PARTITION BY p.Status
--         ORDER BY p.Budget DESC
--     ) AS RankWithoutGaps

-- FROM dbo.ResearchProject AS p
-- ORDER BY p.Status, RankWithGaps, p.Id;
-- GO

-- /*
-- Example budgets:
--     200000, 200000, 100000

-- RANK:
--     1, 1, 3

-- DENSE_RANK:
--     1, 1, 2

-- RANK leaves gaps after ties.
-- DENSE_RANK does not leave gaps.
-- */


-- /* =========================================================
--    Question 12
--    Divide researchers into four groups by publication count.
--    ========================================================= */

-- WITH PublicationCounts AS (
--     SELECT
--         r.Id,
--         r.FirstName,
--         r.MiddleName,
--         r.LastName,
--         COUNT(a.PublicationId) AS PublicationCount
--     FROM dbo.Researcher AS r
--     LEFT JOIN dbo.Publishes AS a
--         ON a.ResearcherId = r.Id
--     GROUP BY
--         r.Id,
--         r.FirstName,
--         r.MiddleName,
--         r.LastName
-- )
-- SELECT
--     Id AS ResearcherId,
--     CONCAT_WS(
--         ' ',
--         FirstName,
--         NULLIF(MiddleName, ''),
--         LastName
--     ) AS FullName,
--     PublicationCount,
--     NTILE(4) OVER (
--         ORDER BY PublicationCount DESC, Id
--     ) AS GroupNumber

-- FROM PublicationCounts
-- ORDER BY GroupNumber, PublicationCount DESC, Id;
-- GO

-- /* =========================================================
--    Question 13
--    Logical query processing order.
--    ========================================================= */

-- /*
-- Logical order:

-- 1. FROM
-- 2. WHERE
-- 3. GROUP BY
-- 4. HAVING
-- 5. SELECT
-- 6. ORDER BY
-- 7. TOP / OFFSET-FETCH

-- From is processed first to establish the source rows.
-- WHERE filters individual rows before grouping.
-- HAVING filters the resulting groups.
-- SELECT aliases cannot normally be referenced in WHERE or HAVING
-- of the same query block because those clauses are processed earlier.
-- ORDER BY can reference SELECT aliases.
-- */

-- /* =========================================================
--    Question 14
--    Correct the aggregate filtering query.
--    ========================================================= */

-- SELECT
--     w.ResearcherId,
--     COUNT(*) AS ProjectCount
-- FROM dbo.WorksOn AS w
-- GROUP BY w.ResearcherId
-- HAVING COUNT(*) > 2
-- ORDER BY w.ResearcherId;
-- GO

-- /*
-- The original query fails because:

-- 1. ProjectCount is a SELECT alias and is unavailable in WHERE.
-- 2. The aggregate condition must be evaluated after grouping.

-- Use HAVING COUNT(*) > 2.
-- */


-- /* =========================================================
--    Question 15
--    Full name, lowercase email, and age in completed years.
--    ========================================================= */

-- DECLARE @Today date = CONVERT(date, GETDATE());

-- SELECT
--     r.Id AS ResearcherId,
--     CONCAT_WS(
--         ' ',
--         r.FirstName,
--         NULLIF(r.MiddleName, ''),
--         r.LastName
--     ) AS FullName,
--     LOWER(r.Email) AS EmailLowercase,
--     DATEDIFF(YEAR, r.DateOfBirth, @Today)
--     -
--     CASE
--         WHEN DATEADD(
--             YEAR,
--             DATEDIFF(YEAR, r.DateOfBirth, @Today),
--             r.DateOfBirth
--         ) > @Today
--         THEN 1
--         ELSE 0
--     END AS AgeYears

-- FROM dbo.Researcher AS r
-- ORDER BY r.Id;
-- GO

-- /* =========================================================
--    Question 16
--    Project duration in days and start month/year.
--    ========================================================= */

-- SELECT
--     p.Id AS ProjectId,
--     p.Title,
--     DATEDIFF(
--         DAY,
--         p.StartDate,
--         COALESCE(p.EndDate, CONVERT(date, GETDATE()))
--     ) AS DurationDays,
--     MONTH(p.StartDate) AS StartMonth,
--     YEAR(p.StartDate) AS StartYear
-- FROM dbo.ResearchProject AS p
-- ORDER BY p.Id;
-- GO

-- -- NULL EndDate is replaced with today's date.

-- /* =========================================================
--    Question 17
--    Researchers whose email domain is university.edu.
--    ========================================================= */

-- SELECT *
-- FROM dbo.Researcher AS r
-- WHERE CHARINDEX('@', r.Email) > 1
--   AND LOWER(
--         SUBSTRING(
--             r.Email,
--             CHARINDEX('@', r.Email) + 1,
--             100
--         )
--       ) = 'university.edu'
-- ORDER BY r.Id;
-- GO

-- /* =========================================================
--    Question 18
--    Replace missing MiddleName and RoomNumber with N/A.
--    ========================================================= */

-- SELECT
--     r.Id,
--     r.FirstName,
--     COALESCE(
--         NULLIF(LTRIM(RTRIM(r.MiddleName)), ''),
--         'N/A'
--     ) AS MiddleName,
--     r.LastName,
--     r.Email,
--     r.DateOfBirth,
--     r.Building,
--     COALESCE(
--         NULLIF(LTRIM(RTRIM(r.RoomNumber)), ''),
--         'N/A'
--     ) AS RoomNumber

-- FROM dbo.Researcher AS r
-- ORDER BY r.Id;
-- GO

-- /* =========================================================
--    Question 19
--    Classify projects by budget.
--    ========================================================= */

-- SELECT
--     p.Id AS ProjectId,
--     p.Title,
--     p.Budget,

--     CASE
--         WHEN p.Budget IS NULL THEN 'Unknown'
--         WHEN p.Budget < 50000 THEN 'Small'
--         WHEN p.Budget <= 150000 THEN 'Medium'
--         ELSE 'Large'
--     END AS BudgetCategory

-- FROM dbo.ResearchProject AS p
-- ORDER BY p.Id;
-- GO

-- /* =========================================================
--    Question 20
--    Total budget managed by each project leader.
--    ========================================================= */

-- SELECT
--     r.Id AS ResearcherId,
--     CONCAT_WS(
--         ' ',
--         r.FirstName,
--         NULLIF(r.MiddleName, ''),
--         r.LastName
--     ) AS FullName,
--     SUM(p.Budget) AS TotalBudget,
--     COUNT(*) AS ProjectCount,
--     COUNT(p.Budget) AS KnownBudgetCount
-- FROM dbo.Researcher AS r
-- INNER JOIN dbo.ResearchProject AS p
--     ON p.LeaderId = r.Id
-- GROUP BY
--     r.Id,
--     r.FirstName,
--     r.MiddleName,
--     r.LastName
-- ORDER BY r.Id;
-- GO

-- /* =========================================================
--    Question 21
--    Buildings with more than three researchers.
--    ========================================================= */

-- SELECT
--     r.Building,
--     COUNT(*) AS ResearcherCount
-- FROM dbo.Researcher AS r
-- WHERE r.Building IS NOT NULL
-- GROUP BY r.Building
-- HAVING COUNT(*) > 3
-- ORDER BY r.Building;
-- GO

-- /* =========================================================
--    Question 22
--    Citation statistics per publication type; average above 50.
--    ========================================================= */

-- SELECT
--     p.Type,
--     AVG(
--         CAST(p.CitationCount AS decimal(19,4))
--     ) AS AverageCitationCount,
--     SUM(
--         CAST(p.CitationCount AS bigint)
--     ) AS TotalCitations,
--     COUNT(*) AS PublicationCount
-- FROM dbo.Publication AS p
-- GROUP BY p.Type
-- HAVING AVG(
--     CAST(p.CitationCount AS decimal(19,4))
-- ) > 50
-- ORDER BY p.Type;
-- GO

-- /* =========================================================
--    Question 23
--    More than two projects and more than 60 total weekly hours.
--    ========================================================= */

-- SELECT
--     w.ResearcherId,
--     COUNT(*) AS ProjectCount,
--     SUM(CAST(w.HoursPerWeek AS bigint)) AS TotalHoursPerWeek
-- FROM dbo.WorksOn AS w
-- GROUP BY w.ResearcherId
-- HAVING COUNT(*) > 2
--    AND SUM(CAST(w.HoursPerWeek AS bigint)) > 60
-- ORDER BY w.ResearcherId;
-- GO

-- /* =========================================================
--    Question 24
--    Projects with budgets above the overall average.
--    ========================================================= */

-- SELECT *
-- FROM dbo.ResearchProject AS p
-- WHERE p.Budget > (
--     SELECT AVG(p2.Budget)
--     FROM dbo.ResearchProject AS p2
-- )
-- ORDER BY p.Budget DESC, p.Id;
-- GO

-- /* =========================================================
--    Question 25
--    Researchers above their building's average publication count.
--    ========================================================= */

-- SELECT
--     r.Id AS ResearcherId,
--     CONCAT_WS(
--         ' ',
--         r.FirstName,
--         NULLIF(r.MiddleName, ''),
--         r.LastName
--     ) AS FullName,
--     r.Building,
--     (
--         SELECT COUNT(*)
--         FROM dbo.Publishes AS a
--         WHERE a.ResearcherId = r.Id
--     ) AS PublicationCount
-- FROM dbo.Researcher AS r
-- WHERE r.Building IS NOT NULL
-- AND (
--     SELECT COUNT(*)
--     FROM dbo.Publishes AS a
--     WHERE a.ResearcherId = r.Id
-- ) > (
--     SELECT
--         AVG(CAST(peers.PublicationCount AS decimal(19,4)))
--     FROM (
--         SELECT
--             r2.Id,
--             r2.Building,
--             COUNT(a2.PublicationId) AS PublicationCount
--         FROM dbo.Researcher AS r2
--         LEFT JOIN dbo.Publishes AS a2
--             ON a2.ResearcherId = r2.Id
--         GROUP BY r2.Id, r2.Building
--     ) AS peers
--     WHERE peers.Building = r.Building
-- )
-- ORDER BY r.Building, r.Id;
-- GO

-- /* =========================================================
--    Question 26
--    Researchers who supervise at least one other researcher.
--    ========================================================= */

-- SELECT *
-- FROM dbo.Researcher AS r
-- WHERE EXISTS (
--     SELECT 1
--     FROM dbo.Supervises AS s
--     WHERE s.SupervisorId = r.Id
-- )
-- ORDER BY r.Id;
-- GO


-- /* =========================================================
--    Question 27
--    Each project and its researcher count, using a subquery.
--    ========================================================= */

-- SELECT
--     p.Id AS ProjectId,
--     p.Title,
--     (
--         SELECT COUNT(*)
--         FROM dbo.WorksOn AS w
--         WHERE w.ProjectId = p.Id
--     ) AS ResearcherCount
-- FROM dbo.ResearchProject AS p
-- ORDER BY p.Id;
-- GO

-- /* =========================================================
--    Question 28
--    Second-highest distinct budget, without ranking or OFFSET.
--    ========================================================= */

-- SELECT
--     MAX(p.Budget) AS SecondHighestBudget
-- FROM dbo.ResearchProject AS p
-- WHERE p.Budget < (
--     SELECT MAX(p2.Budget)
--     FROM dbo.ResearchProject AS p2
-- );
-- GO

-- /* =========================================================
--    Question 29
--    Researchers involved in projects but with no publications.
--    ========================================================= */

-- SELECT *
-- FROM dbo.Researcher AS r
-- WHERE EXISTS (
--     SELECT 1
--     FROM dbo.WorksOn AS w
--     WHERE w.ResearcherId = r.Id
-- )
-- AND NOT EXISTS (
--     SELECT 1
--     FROM dbo.Publishes AS a
--     WHERE a.ResearcherId = r.Id
-- )
-- ORDER BY r.Id;
-- GO

-- /* =========================================================
--    Question 30
--    Researchers who both supervise and lead projects.
--    ========================================================= */

-- SELECT r.*
-- FROM dbo.Researcher AS r
-- WHERE EXISTS (
--     SELECT 1
--     FROM dbo.Supervises AS s
--     WHERE s.SupervisorId = r.Id
-- )
-- AND EXISTS (
--     SELECT 1
--     FROM dbo.ResearchProject AS p
--     WHERE p.LeaderId = r.Id
-- )
-- ORDER BY r.Id;
-- GO

-- /* =========================================================
--    Question 31
--    Scalar function returning project duration in days.
--    ========================================================= */

-- CREATE OR ALTER FUNCTION dbo.GetProjectActiveDays
-- (
--     @ProjectId varchar(10)
-- )
-- RETURNS int
-- AS
-- BEGIN
--     DECLARE @Days int;
--     SELECT
--         @Days = DATEDIFF(
--             DAY,
--             p.StartDate,
--             COALESCE(p.EndDate, CONVERT(date, GETDATE()))
--         )
--     FROM dbo.ResearchProject AS p
--     WHERE p.Id = @ProjectId;
--     RETURN @Days;
-- END;
-- GO

-- /* =========================================================
--    Question 32
--    Table-valued function returning a researcher's projects.
--    ========================================================= */

-- CREATE OR ALTER FUNCTION dbo.GetResearcherProjects
-- (
--     @ResearcherId varchar(10)
-- )
-- RETURNS TABLE
-- AS
-- RETURN
-- (
--     SELECT
--         p.Id AS ProjectId,
--         p.Title AS ProjectTitle,
--         w.Role,
--         w.HoursPerWeek
--     FROM dbo.WorksOn AS w
--     INNER JOIN dbo.ResearchProject AS p
--         ON p.Id = w.ProjectId
--     WHERE w.ResearcherId = @ResearcherId
-- );
-- GO

-- /* =========================================================
--    Question 33
--    Multi-statement TVF returning researcher statistics.
--    ========================================================= */

-- CREATE OR ALTER FUNCTION dbo.GetResearcherStatistics
-- (
--     @ResearcherId varchar(10)
-- )
-- RETURNS @Statistics TABLE
-- (
--     ResearcherId varchar(10) NOT NULL,
--     TotalProjects int NOT NULL,
--     TotalPublications int NOT NULL,
--     TotalHoursPerWeek bigint NOT NULL,
--     AverageCitationsPerPublication decimal(19,4) NULL
-- )
-- AS
-- BEGIN
--     IF NOT EXISTS (
--         SELECT 1
--         FROM dbo.Researcher
--         WHERE Id = @ResearcherId
--     )
--         RETURN;
--     DECLARE
--         @Projects int,
--         @Publications int,
--         @Hours bigint,
--         @AverageCitations decimal(19,4);
--     SELECT
--         @Projects = COUNT(*),
--         @Hours = COALESCE(
--             SUM(CAST(w.HoursPerWeek AS bigint)),
--             0
--         )
--     FROM dbo.WorksOn AS w
--     WHERE w.ResearcherId = @ResearcherId;
--     SELECT
--         @Publications = COUNT(*),
--         @AverageCitations = AVG(
--             CAST(p.CitationCount AS decimal(19,4))
--         )
--     FROM dbo.Publishes AS a
--     INNER JOIN dbo.Publication AS p
--         ON p.Id = a.PublicationId
--     WHERE a.ResearcherId = @ResearcherId;
--     INSERT INTO @Statistics
--     (
--         ResearcherId,
--         TotalProjects,
--         TotalPublications,
--         TotalHoursPerWeek,
--         AverageCitationsPerPublication
--     )
--     VALUES
--     (
--         @ResearcherId,
--         @Projects,
--         @Publications,
--         @Hours,
--         @AverageCitations
--     );
--     RETURN;
-- END;
-- GO

-- /*
-- Projects and publications are aggregated separately.

-- Joining both detail tables first would multiply rows and can
-- inflate counts and weekly hours.

-- Existing researcher with no activity:
--     TotalProjects = 0
--     TotalPublications = 0
--     TotalHoursPerWeek = 0
--     AverageCitationsPerPublication = NULL

-- NULL average means no known citation values, not an average of zero.

-- Use a multi-statement TVF when the result genuinely requires:
-- - Procedural branching.
-- - Multiple staged changes to the return table.
-- - Logic that cannot reasonably be expressed as one SELECT.

-- Prefer an inline TVF when a single relational expression is sufficient:
-- it normally gives the optimizer better visibility.

-- Multiple aggregates alone do not require a multi-statement TVF.
-- This example demonstrates the requested function style.
-- */


-- /* =========================================================
--    Question 34
--    Nonclustered index for Status and StartDate searches.
--    ========================================================= */

-- IF NOT EXISTS (
--     SELECT 1
--     FROM sys.indexes
--     WHERE object_id = OBJECT_ID(N'dbo.ResearchProject')
--       AND name = N'IX_ResearchProject_Status_StartDate'
-- )
-- BEGIN
--     CREATE NONCLUSTERED INDEX IX_ResearchProject_Status_StartDate
--     ON dbo.ResearchProject
--     (
--         Status,
--         StartDate DESC
--     );
-- END;
-- GO

-- -- Check existing index definitions to avoid equivalent duplicate indexes.

-- /* =========================================================
--    Question 35
--    Clustered versus nonclustered indexes.
--    ========================================================= */

-- /*
-- CLUSTERED INDEX:
-- - Its leaf level contains the table's data rows.
-- - Data is organized by the clustering key in the B-tree.
-- - A table can have at most ONE clustered index.
-- - A table without a clustered index is a heap.

-- NONCLUSTERED INDEX:
-- - A separate B-tree containing index keys and optional included columns.
-- - Contains a row locator:
--     RID for a heap.
--     Clustering key for a clustered table.
-- - A table can have multiple nonclustered indexes.

-- CREATING A CLUSTERED INDEX ON A HEAP:
-- - Reorganizes the base table.
-- - Existing nonclustered indexes are rebuilt to replace RID locators
--   with clustering-key locators.
-- - Can require substantial IO, storage, and locking.

-- IMPORTANT:
-- A primary key and a clustered index are different concepts.
-- A primary key is often clustered by default, but it can be nonclustered.

-- A clustered index does not remove the need for ORDER BY.
-- */


-- /* =========================================================
--    Question 36
--    Covering index for Email searches returning researcher names.
--    ========================================================= */

-- IF NOT EXISTS (
--     SELECT 1
--     FROM sys.indexes
--     WHERE object_id = OBJECT_ID(N'dbo.Researcher')
--       AND name = N'IX_Researcher_Email_Covering'
-- )
-- BEGIN
--     CREATE NONCLUSTERED INDEX IX_Researcher_Email_Covering
--     ON dbo.Researcher (Email)
--     INCLUDE (FirstName, LastName);
-- END;
-- GO

-- /*
-- A covering index contains every column required by a particular query.

-- Email is the searchable index key.
-- FirstName and LastName are stored as included columns.

-- For this query:

-- SELECT FirstName, LastName
-- FROM dbo.Researcher
-- WHERE Email = 'someone@university.edu';

-- SQL Server can potentially answer it from the index alone,
-- avoiding lookups into the base table.

-- Coverage is query-specific; this does not cover arbitrary SELECT *.
-- */


-- /* =========================================================
--    Question 37
--    ActiveProjectSummary view.
--    ========================================================= */

-- CREATE OR ALTER VIEW dbo.ActiveProjectSummary
-- AS
-- SELECT
--     p.Id AS ProjectId,
--     p.Title AS ProjectTitle,
--     CONCAT_WS(
--         ' ',
--         r.FirstName,
--         NULLIF(r.MiddleName, ''),
--         r.LastName
--     ) AS LeaderName,
--     COALESCE(team.TeamMemberCount, 0) AS TeamMemberCount,
--     COALESCE(
--         team.TotalHoursPerWeek,
--         CONVERT(bigint, 0)
--     ) AS TotalHoursPerWeek,
--     p.Budget AS TotalBudget
-- FROM dbo.ResearchProject AS p
-- INNER JOIN dbo.Researcher AS r
--     ON r.Id = p.LeaderId
-- LEFT JOIN (
--     SELECT
--         w.ProjectId,
--         COUNT(*) AS TeamMemberCount,
--         SUM(CAST(w.HoursPerWeek AS bigint)) AS TotalHoursPerWeek
--     FROM dbo.WorksOn AS w
--     GROUP BY w.ProjectId
-- ) AS team
--     ON team.ProjectId = p.Id
-- WHERE p.Status = 'Active';
-- GO

-- /*
-- Includes active projects without team assignments.

-- Team members are counted from WorksOn.
-- A leader is counted only if their WorksOn assignment exists.

-- Budget is selected once from ResearchProject.
-- Do not SUM the project budget across joined team rows.

-- Zero hours is a display convention for an absent/entirely unknown total.
-- */


-- /* =========================================================
--    Question 38
--    Indexed view: ResearcherPublicationStats.
--    ========================================================= */

-- SET ANSI_NULLS ON;
-- SET QUOTED_IDENTIFIER ON;
-- SET ANSI_PADDING ON;
-- SET ANSI_WARNINGS ON;
-- SET ARITHABORT ON;
-- SET CONCAT_NULL_YIELDS_NULL ON;
-- SET NUMERIC_ROUNDABORT OFF;
-- GO

-- CREATE OR ALTER VIEW dbo.ResearcherPublicationStats
-- WITH SCHEMABINDING
-- AS
-- SELECT
--     r.Id AS ResearcherId,
--     r.FirstName,
--     r.MiddleName,
--     r.LastName,
--     COUNT_BIG(*) AS TotalPublications
-- FROM dbo.Researcher AS r
-- INNER JOIN dbo.Publishes AS a
--     ON a.ResearcherId = r.Id
-- GROUP BY
--     r.Id,
--     r.FirstName,
--     r.MiddleName,
--     r.LastName;
-- GO

-- CREATE UNIQUE CLUSTERED INDEX
--     IX_ResearcherPublicationStats_ResearcherId
-- ON dbo.ResearcherPublicationStats (ResearcherId);
-- GO

-- /* =========================================================
--    Question 39
--    Indexed-view requirements, restrictions, and tradeoffs.
--    ========================================================= */

-- /*
-- REQUIREMENTS:
-- 1. WITH SCHEMABINDING.
-- 2. Schema-qualified base-table references, such as dbo.Researcher.
-- 3. Base tables in the same database.
-- 4. Matching ownership requirements between the view and base tables.
-- 5. Deterministic expressions.
-- 6. Precise expressions for keys and relevant grouping/predicate expressions.
-- 7. First index must be UNIQUE CLUSTERED.
-- 8. A grouped indexed view requires COUNT_BIG(*).

-- REQUIRED SET OPTIONS:
-- ON:
--     ANSI_NULLS
--     ANSI_PADDING
--     ANSI_WARNINGS
--     ARITHABORT
--     CONCAT_NULL_YIELDS_NULL
--     QUOTED_IDENTIFIER

-- OFF:
--     NUMERIC_ROUNDABORT

-- These settings matter during creation and later base-table modifications.

-- EXAMPLES OF RESTRICTED CONSTRUCTS:
--     TOP
--     ORDER BY
--     OFFSET
--     DISTINCT
--     OUTER JOIN
--     Self-joins
--     Subqueries
--     CTEs
--     Window functions
--     UNION
--     HAVING
--     AVG
--     COUNT instead of COUNT_BIG

-- The full restrictions list is broader.
-- GETDATE() cannot be used because it is nondeterministic.

-- BENEFITS:
-- - Stores eligible results physically.
-- - Can accelerate repeated expensive joins/aggregates.
-- - Results are maintained transactionally with base-table changes.

-- COSTS:
-- - Additional storage.
-- - Additional INSERT/UPDATE/DELETE maintenance.
-- - More restrictive definitions.
-- - No guarantee that every query becomes faster.

-- WHEN TO CHOOSE:
-- Indexed view:
--     Repeated, expensive, measured, read-heavy aggregate workloads.

-- Regular view:
--     Reusable logical abstraction without materialized storage/write cost.

-- Summary table:
--     More flexible computation, but synchronization and freshness must
--     be implemented explicitly.

-- Optimizer use and NOEXPAND behavior depend on SQL Server edition
-- and the selected execution plan.
-- */


-- /* =========================================================
--    Question 40
--    AddResearcherToProject procedure.
--    Return 0 for success and -1 for errors.
--    ========================================================= */

-- CREATE OR ALTER PROCEDURE dbo.AddResearcherToProject
--     @ResearcherId varchar(10),
--     @ProjectId varchar(10),
--     @JoinDate date,
--     @Role varchar(50),
--     @HoursPerWeek int
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     IF @ResearcherId IS NULL
--        OR @ProjectId IS NULL
--        OR @JoinDate IS NULL
--        OR @HoursPerWeek IS NULL
--        OR @HoursPerWeek NOT BETWEEN 1 AND 168
--     BEGIN
--         RETURN -1;
--     END;
--     IF NOT EXISTS (
--         SELECT 1
--         FROM dbo.Researcher
--         WHERE Id = @ResearcherId
--     )
--     BEGIN
--         RETURN -1;
--     END;
--     IF NOT EXISTS (
--         SELECT 1
--         FROM dbo.ResearchProject
--         WHERE Id = @ProjectId
--     )
--     BEGIN
--         RETURN -1;
--     END;
--     IF EXISTS (
--         SELECT 1
--         FROM dbo.WorksOn
--         WHERE ResearcherId = @ResearcherId
--           AND ProjectId = @ProjectId
--     )
--     BEGIN
--         RETURN -1;
--     END;
--     BEGIN TRY
--         INSERT INTO dbo.WorksOn
--         (
--             ResearcherId,
--             ProjectId,
--             JoinDate,
--             Role,
--             HoursPerWeek
--         )
--         VALUES
--         (
--             @ResearcherId,
--             @ProjectId,
--             @JoinDate,
--             @Role,
--             @HoursPerWeek
--         );
--         RETURN 0;
--     END TRY
--     BEGIN CATCH
--         RETURN -1;
--     END CATCH;
-- END;
-- GO

-- /*
-- Example: performs an INSERT if executed.

-- DECLARE @ReturnCode int;

-- EXEC @ReturnCode = dbo.AddResearcherToProject
--     @ResearcherId = 'R001',
--     @ProjectId = 'P001',
--     @JoinDate = '20261021',
--     @Role = 'Research Assistant',
--     @HoursPerWeek = 10;

-- SELECT @ReturnCode AS ReturnCode;

-- The PK and FKs remain the final protection against duplicate
-- or missing-reference races.

-- ContributionPercentage is nullable and is not requested as a parameter.
-- */


-- /* =========================================================
--    Question 41
--    Activate a pending project only when staffed and funded.
--    ========================================================= */

-- CREATE OR ALTER PROCEDURE dbo.UpdateProjectStatus
--     @ProjectId varchar(10)
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     BEGIN TRY
--         UPDATE p
--         SET Status = 'Active'
--         FROM dbo.ResearchProject AS p
--         WHERE p.Id = @ProjectId
--           AND p.Status = 'Pending'
--           AND (
--               p.EndDate IS NULL
--               OR p.EndDate >= CONVERT(date, GETDATE())
--           )
--           AND EXISTS (
--               SELECT 1
--               FROM dbo.WorksOn AS w WITH (HOLDLOCK)
--               WHERE w.ProjectId = p.Id
--           )
--           AND EXISTS (
--               SELECT 1
--               FROM dbo.Funds AS f WITH (HOLDLOCK)
--               WHERE f.ProjectId = p.Id
--           );
--         IF @@ROWCOUNT = 0
--         BEGIN
--             THROW 51041,
--                 'Project missing, not Pending, already ended, unstaffed, or without grant funding.',
--                 1;
--         END;
--         RETURN 0;
--     END TRY
--     BEGIN CATCH
--         THROW;
--     END CATCH;
-- END;
-- GO

-- /* =========================================================
--    Question 42
--    Procedure with OUTPUT parameters for researcher totals.
--    ========================================================= */

-- CREATE OR ALTER PROCEDURE dbo.GetResearcherSummary
--     @ResearcherId varchar(10),
--     @TotalProjects int OUTPUT,
--     @TotalPublications int OUTPUT,
--     @TotalWeeklyHours bigint OUTPUT
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     SELECT
--         @TotalProjects = 0,
--         @TotalPublications = 0,
--         @TotalWeeklyHours = 0;
--     IF NOT EXISTS (
--         SELECT 1
--         FROM dbo.Researcher
--         WHERE Id = @ResearcherId
--     )
--     BEGIN
--         THROW 51042, 'Researcher does not exist.', 1;
--     END;
--     SELECT
--         @TotalProjects = COUNT(*),
--         @TotalWeeklyHours = COALESCE(
--             SUM(CAST(HoursPerWeek AS bigint)),
--             0
--         )
--     FROM dbo.WorksOn
--     WHERE ResearcherId = @ResearcherId;
--     SELECT
--         @TotalPublications = COUNT(*)
--     FROM dbo.Publishes
--     WHERE ResearcherId = @ResearcherId;
-- END;
-- GO

-- /*
-- Example:

-- DECLARE
--     @Projects int,
--     @Publications int,
--     @Hours bigint;

-- EXEC dbo.GetResearcherSummary
--     @ResearcherId = 'R001',
--     @TotalProjects = @Projects OUTPUT,
--     @TotalPublications = @Publications OUTPUT,
--     @TotalWeeklyHours = @Hours OUTPUT;

-- SELECT
--     @Projects AS TotalProjects,
--     @Publications AS TotalPublications,
--     @Hours AS TotalWeeklyHours;
-- */


-- /* =========================================================
--    Question 43
--    AFTER INSERT trigger preventing more than five assignments.
--    ========================================================= */

-- CREATE OR ALTER TRIGGER dbo.trg_WorksOn_MaxFiveProjects
-- ON dbo.WorksOn
-- AFTER INSERT
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     IF NOT EXISTS (SELECT 1 FROM inserted)
--         RETURN;
--     DECLARE @LockedResearchers bigint;
--     SELECT
--         @LockedResearchers = COUNT_BIG(*)
--     FROM dbo.Researcher AS r WITH (UPDLOCK, HOLDLOCK)
--     INNER JOIN (
--         SELECT DISTINCT ResearcherId
--         FROM inserted
--     ) AS affected
--         ON affected.ResearcherId = r.Id;
--     IF EXISTS (
--         SELECT w.ResearcherId
--         FROM dbo.WorksOn AS w WITH (UPDLOCK, HOLDLOCK)
--         INNER JOIN (
--             SELECT DISTINCT ResearcherId
--             FROM inserted
--         ) AS affected
--             ON affected.ResearcherId = w.ResearcherId
--         GROUP BY w.ResearcherId
--         HAVING COUNT_BIG(*) > 5
--     )
--     BEGIN
--         IF @@TRANCOUNT > 0
--             ROLLBACK TRANSACTION;
--         THROW 51043,
--             'A researcher cannot be assigned to more than five projects.',
--             1;
--     END;
-- END;
-- GO

-- /*
-- Handles multi-row INSERT statements.

-- Checks each affected researcher's total assignments, not just the
-- number of rows in inserted.

-- The count covers all projects, not only active projects.

-- Locking protects concurrent checks. Conflicting concurrent writers may
-- deadlock; the victim transaction must be retried as a whole.

-- Creating the trigger does not repair existing violations.

-- As requested, this handles INSERT. Reassignments through UPDATE would
-- need equivalent validation if those operations are permitted.
-- */


-- /* =========================================================
--    Question 44
--    Complete a project when EndDate is set to a past date.
--    ========================================================= */

-- CREATE OR ALTER TRIGGER dbo.trg_ResearchProject_AutoComplete
-- ON dbo.ResearchProject
-- AFTER INSERT, UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;

--     IF NOT EXISTS (SELECT 1 FROM inserted)
--         RETURN;

--     IF NOT UPDATE(EndDate)
--         RETURN;

--     UPDATE p
--     SET Status = 'Completed'

--     FROM dbo.ResearchProject AS p
--     INNER JOIN inserted AS i
--         ON i.Id = p.Id

--     WHERE i.EndDate < CONVERT(date, GETDATE())
--       AND (
--           p.Status IS NULL
--           OR p.Status <> 'Completed'
--       );
-- END;
-- GO

-- /*
-- AFTER is appropriate because the trigger supplements normal DML;
-- it does not replace the original INSERT/UPDATE.

-- The update is set-based and supports multiple projects.

-- The date comparison is strictly earlier than today:
-- an EndDate equal to today is not yet a past date.

-- Updating Status does not update EndDate, so the UPDATE(EndDate)
-- guard avoids repeating the completion logic on that nested update.

-- A trigger does not execute just because midnight passes.
-- A scheduled job is needed to complete untouched projects over time.
-- */


-- /* =========================================================
--    Question 45
--    Audit all updates to Grants.
--    ========================================================= */

-- IF OBJECT_ID(N'dbo.GrantAudit', N'U') IS NULL
-- BEGIN
--     CREATE TABLE dbo.GrantAudit
--     (
--         AuditId bigint IDENTITY(1,1) NOT NULL
--             CONSTRAINT PK_GrantAudit PRIMARY KEY,
--         GrantId varchar(10) NOT NULL,
--         OldAmount decimal(12,2) NOT NULL,
--         NewAmount decimal(12,2) NOT NULL,
--         ModifiedBy nvarchar(128) NOT NULL,
--         ModifiedDate datetime2(7) NOT NULL
--     );
-- END;
-- GO
-- CREATE OR ALTER TRIGGER dbo.trg_Grants_AuditUpdates
-- ON dbo.Grants
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     IF NOT EXISTS (SELECT 1 FROM inserted)
--         RETURN;
--     IF UPDATE(Id)
--     BEGIN
--         THROW 51045,
--             'Grant Id cannot be updated; it is the audit pairing key.',
--             1;
--     END;
--     INSERT INTO dbo.GrantAudit
--     (
--         GrantId,
--         OldAmount,
--         NewAmount,
--         ModifiedBy,
--         ModifiedDate
--     )
--     SELECT
--         i.Id,
--         d.Amount,
--         i.Amount,
--         SYSTEM_USER,
--         SYSDATETIME()
--     FROM inserted AS i
--     INNER JOIN deleted AS d
--         ON d.Id = i.Id;
-- END;
-- GO

-- /*
-- All successful row updates are logged, including changes to
-- GrantName or other columns when Amount itself is unchanged.

-- Do not filter with OldAmount <> NewAmount:
-- the question requests all updates.

-- No FK is added from GrantAudit to Grants, allowing history to
-- survive a later deletion of the source grant.

-- Audit inserts share the original transaction.
-- Rolling back the update also rolls back its audit rows.

-- The immutable-Id rule is an explicit implementation choice,
-- not a constraint originally present in the supplied database.
-- */


-- /* =========================================================
--    Question 46
--    Transaction: create project, assign leader, allocate grant.
--    ========================================================= */

/*
SET XACT_ABORT ON;
DECLARE
    @ProjectId varchar(10) = 'PEXAM001',
    @LeaderId varchar(10) = 'R001',
    @GrantId varchar(10) = 'G001',
    @StartDate date = CONVERT(date, GETDATE()),
    @AllocationAmount decimal(12,2) = 1000.00,
    @Award decimal(12,2),
    @AlreadyAllocated decimal(38,2),
    @CurrentProjectCount bigint;
BEGIN TRY
    BEGIN TRANSACTION;
    IF EXISTS (
        SELECT 1
        FROM dbo.ResearchProject WITH (UPDLOCK, HOLDLOCK)
        WHERE Id = @ProjectId
    )
    BEGIN
        THROW 51046, 'The new project Id already exists.', 1;
    END;
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Researcher WITH (UPDLOCK, HOLDLOCK)
        WHERE Id = @LeaderId
    )
    BEGIN
        THROW 51047, 'Leader does not exist.', 1;
    END;
    SELECT
        @CurrentProjectCount = COUNT_BIG(*)
    FROM dbo.WorksOn WITH (UPDLOCK, HOLDLOCK)
    WHERE ResearcherId = @LeaderId;
    IF @CurrentProjectCount >= 5
    BEGIN
        THROW 51048,
            'Leader is already assigned to five projects.',
            1;
    END;
    SELECT
        @Award = Amount
    FROM dbo.Grants WITH (UPDLOCK, HOLDLOCK)
    WHERE Id = @GrantId;
    IF @Award IS NULL
    BEGIN
        THROW 51049, 'Grant does not exist.', 1;
    END;
    SELECT
        @AlreadyAllocated = COALESCE(
            SUM(AllocationAmount),
            0
        )
    FROM dbo.Funds WITH (UPDLOCK, HOLDLOCK)
    WHERE GrantId = @GrantId;
    IF @AllocationAmount <= 0
       OR @AlreadyAllocated + @AllocationAmount > @Award
    BEGIN
        THROW 51050,
            'Allocation is invalid or exceeds the remaining grant amount.',
            1;
    END;
    INSERT INTO dbo.ResearchProject
    (
        Id,
        Title,
        StartDate,
        EndDate,
        Budget,
        Status,
        LeaderId
    )
    VALUES
    (
        @ProjectId,
        'Exam Research Project',
        @StartDate,
        NULL,
        @AllocationAmount,
        'Pending',
        @LeaderId
    );
    INSERT INTO dbo.WorksOn
    (
        ResearcherId,
        ProjectId,
        JoinDate,
        Role,
        HoursPerWeek,
        ContributionPercentage
    )
    VALUES
    (
        @LeaderId,
        @ProjectId,
        @StartDate,
        'Lead Investigator',
        10,
        100.00
    );
    INSERT INTO dbo.Funds
    (
        GrantId,
        ProjectId,
        AllocationAmount,
        AllocationDate
    )
    VALUES
    (
        @GrantId,
        @ProjectId,
        @AllocationAmount,
        @StartDate
    );
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
*/

-- /*
-- If any step fails, all changes are rolled back.

-- For a practice-only run, replace COMMIT TRANSACTION with
-- ROLLBACK TRANSACTION.

-- The available-grant-balance check is an additional business safeguard.
-- For system-wide enforcement, all other allocation writers must use
-- equivalent checks and locking.
-- */


-- /* =========================================================
--    Question 47
--    ACID transaction properties with database examples.
--    ========================================================= */

-- /*
-- ATOMICITY:
-- All operations succeed together or all are undone.

-- Example:
-- If grant allocation fails in Q46, the project and leader assignment
-- must also be rolled back.

-- CONSISTENCY:
-- A valid database state moves to another valid state, respecting
-- constraints and explicitly implemented business rules.

-- Example:
-- LeaderId must reference an existing researcher, allocation must be
-- positive, and the five-project rule must be enforced.

-- The database cannot enforce business rules that were never implemented.

-- ISOLATION:
-- Concurrent transactions interact according to their isolation levels.

-- Example:
-- Two transactions allocating the same grant's remaining balance need
-- appropriate locking or another concurrency strategy so they do not
-- both spend the same remaining funds.

-- READ COMMITTED alone does not prevent every check-then-insert race.

-- DURABILITY:
-- After a normally fully durable COMMIT succeeds, committed changes
-- survive a crash through transaction-log recovery.

-- Example:
-- The committed project, leader assignment, and funding allocation remain
-- after SQL Server restarts.

-- Durability does not replace backups for media loss or disaster recovery.
-- */


-- /* =========================================================
--    Question 48
--    Compare IN and EXISTS for project P001.
--    ========================================================= */

-- SELECT r.*
-- FROM dbo.Researcher AS r
-- WHERE r.Id IN (
--     SELECT w.ResearcherId
--     FROM dbo.WorksOn AS w
--     WHERE w.ProjectId = 'P001'
-- );

-- SELECT r.*
-- FROM dbo.Researcher AS r
-- WHERE EXISTS (
--     SELECT 1
--     FROM dbo.WorksOn AS w
--     WHERE w.ResearcherId = r.Id
--       AND w.ProjectId = 'P001'
-- );
-- GO

-- /*
-- Both queries are equivalent here.

-- SQL Server can transform both into the same semi-join plan.
-- EXISTS is not automatically faster than IN.

-- Factors influencing performance:
-- - Available indexes and index column order.
-- - Table sizes.
-- - Predicate selectivity and data distribution.
-- - Statistics and cardinality estimates.
-- - Parameter values.
-- - Memory availability.
-- - Optimizer transformations and chosen join strategy.

-- Compare actual execution plans and STATISTICS IO/TIME.

-- The NULL-sensitive difference between NOT IN and NOT EXISTS
-- is a separate issue; these queries use positive membership.
-- */


-- /* =========================================================
--    Question 49
--    Optimize the active-project/researcher query.
--    ========================================================= */

-- /*
-- OPTIMIZATION 1:
-- Cover the Status filter and StartDate ordering with a project index.
-- Q34 already created the following key:
--     (Status, StartDate DESC)
-- For the query in Q49, adding Title can remove project lookups.
-- Use this as a replacement/extension, not an unnecessary duplicate.
-- Run after Q34 if choosing this option:
-- */

-- /*
-- CREATE NONCLUSTERED INDEX IX_ResearchProject_Status_StartDate
-- ON dbo.ResearchProject
-- (
--     Status,
--     StartDate DESC
-- )
-- INCLUDE (Title)
-- WITH (DROP_EXISTING = ON);
-- GO
-- */
-- /*
-- Id is implicitly available as the row locator when the table's
-- clustered index is its Id primary key. Confirm the actual index type
-- if adapting this to a different database.
-- */
-- /*
-- OPTIMIZATION 2:
-- Index WorksOn with ProjectId first to retrieve a project's team.
-- The supplied PK starts with ResearcherId, so it does not replace
-- an index optimized for ProjectId-first lookups.
-- */
-- IF NOT EXISTS (
--     SELECT 1
--     FROM sys.indexes
--     WHERE object_id = OBJECT_ID(N'dbo.WorksOn')
--       AND name = N'IX_WorksOn_ProjectId_ResearcherId'
-- )
-- BEGIN
--     CREATE NONCLUSTERED INDEX IX_WorksOn_ProjectId_ResearcherId
--     ON dbo.WorksOn (ProjectId, ResearcherId);
-- END;
-- GO
-- /*
-- OPTIMIZATION 3:
-- Inspect the actual execution plan, logical reads, and elapsed time.
-- Look for:
-- - Excessive key lookups.
-- - Large sorts.
-- - Sort/hash spills.
-- - Incorrect cardinality estimates.
-- - Blocking.
-- - Stale statistics.
-- Update relevant statistics when evidence indicates they are stale.
-- ADDITIONAL OPTIONS:
-- - Add a SARGable StartDate range if the business requirement allows it.
-- - Return/page only the data the caller actually needs.
-- - Consider a filtered active-project index for a fixed Active-only workload.
-- - Consider a Researcher covering index only if measured lookups justify it.
-- Do not replace LEFT JOIN with INNER JOIN unless losing projects
-- without researchers is acceptable.
-- A CTE rewrite alone does not guarantee better performance.
-- A date-range predicate should look like:
--     p.StartDate >= @FromDate
--     AND p.StartDate < @ToDate
-- Avoid wrapping StartDate in YEAR() or CONVERT() for such filtering.
-- */


-- /* =========================================================
--    Question 50
--    Repeated top-ten most-cited publications with their authors.
--    ========================================================= */

-- /*
-- OPTION A: AD-HOC QUERY
-- Pros:
-- - Flexible.
-- - Reads current data.
-- - No extra stored database object.

-- Cons:
-- - Logic can be duplicated across applications.
-- - Harder to maintain consistently.

-- Parameterized ad-hoc SQL can reuse cached plans;
-- it does not necessarily compile from scratch every time.

-- OPTION B: REGULAR VIEW
-- Pros:
-- - Central reusable query definition.
-- - Composable with other queries.
-- - Reads current data.

-- Cons:
-- - No parameters.
-- - Results are not materialized merely because it is a view.
-- - No inherent performance improvement.
-- - Ordering must be specified by the consuming query.

-- OPTION C: STORED PROCEDURE
-- Pros:
-- - Centralizes the logic.
-- - Supports parameters.
-- - Can provide a controlled permission interface.
-- - Can reuse execution plans.

-- Cons:
-- - Still needs suitable indexes.
-- - Can suffer from parameter-sensitive plans.
-- - Does not automatically cache result rows.

-- OPTION D: INDEXED VIEW
-- Pros:
-- - Stores eligible results.
-- - Can accelerate repeated expensive computations.
-- - Maintained transactionally with base-table modifications.

-- Cons:
-- - Extra storage and write-maintenance overhead.
-- - Strict definition restrictions.
-- - TOP and ORDER BY are not allowed in the indexed-view definition.

-- Therefore the literal top-ten view cannot itself be an indexed view.
-- A broader eligible indexed view could be queried using an outer TOP.

-- CHOICE:
-- A stored procedure with appropriate base-table indexing, after measurement.

-- TOP 10 applied after joining authors can return fewer than ten
-- publications and incomplete author lists.
-- */

-- CREATE OR ALTER PROCEDURE dbo.GetTopCitedPublications
--     @TopCount int = 10
-- AS
-- BEGIN
--     SET NOCOUNT ON;

--     IF @TopCount IS NULL OR @TopCount <= 0
--     BEGIN
--         THROW 51051, 'TopCount must be a positive integer.', 1;
--     END;

--     ;WITH TopPublications AS (
--         SELECT TOP (@TopCount)
--             p.Id,
--             p.Title,
--             p.CitationCount
--         FROM dbo.Publication AS p
--         WHERE p.CitationCount IS NOT NULL
--         ORDER BY p.CitationCount DESC, p.Id
--     )
--     SELECT
--         p.Id AS PublicationId,
--         p.Title,
--         p.CitationCount,
--         a.AuthorName

--     FROM TopPublications AS p
--     LEFT JOIN dbo.PublicationAuthor AS a
--         ON a.PublicationId = p.Id

--     ORDER BY
--         p.CitationCount DESC,
--         p.Id,
--         a.AuthorName;
-- END;
-- GO
