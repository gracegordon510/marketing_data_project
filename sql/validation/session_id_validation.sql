USE marketing_analytics;
GO

/*
DATA QUALITY NOTE: SESSION ID

Session-level analysis was excluded because session_id did not
reliably identify individual browsing sessions.

Of 633,462 distinct session IDs:
- 533,914 (84.29%) were associated with multiple customers.
- Some were associated with as many as 14 customers.
- 533,786 spanned multiple calendar days.
- The longest apparent session spanned 1,094 days.

Marketing funnel measures are therefore calculated as aggregate
event-count ratios and should not be interpreted as true
session-level conversion rates or customer journeys.
*/


/* =========================================================
   1. SESSION ID COMPLETENESS
   ========================================================= */

SELECT
    COUNT(*) AS total_events,
    SUM(CASE WHEN session_id IS NULL THEN 1 ELSE 0 END)
        AS null_session_ids,
    COUNT(DISTINCT session_id) AS distinct_sessions
FROM dbo.fact_events;


/* =========================================================
   2. NUMBER OF EVENTS PER SESSION
   ========================================================= */

WITH session_event_counts AS (
    SELECT
        session_id,
        COUNT(*) AS event_count
    FROM dbo.fact_events
    WHERE session_id IS NOT NULL
    GROUP BY session_id
)
SELECT
    MIN(event_count) AS minimum_events,
    MAX(event_count) AS maximum_events,
    AVG(1.0 * event_count) AS average_events,
    SUM(CASE WHEN event_count = 1 THEN 1 ELSE 0 END)
        AS single_event_sessions,
    COUNT(*) AS total_sessions
FROM session_event_counts;


/* =========================================================
   3. SESSIONS ASSOCIATED WITH MULTIPLE CUSTOMERS
   ========================================================= */

WITH session_customers AS (
    SELECT
        session_id,
        COUNT(DISTINCT customer_id) AS customer_count
    FROM dbo.fact_events
    WHERE session_id IS NOT NULL
    GROUP BY session_id
)
SELECT
    COUNT(*) AS total_sessions,
    SUM(CASE WHEN customer_count = 1 THEN 1 ELSE 0 END)
        AS single_customer_sessions,
    SUM(CASE WHEN customer_count > 1 THEN 1 ELSE 0 END)
        AS multiple_customer_sessions,
    ROUND(
        100.0 * SUM(CASE WHEN customer_count > 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS multiple_customer_session_percentage,
    MAX(customer_count) AS maximum_customers_in_one_session
FROM session_customers;


/* =========================================================
   4. EXAMPLES OF INVALID SESSIONS
   ========================================================= */

SELECT TOP (20)
    session_id,
    COUNT(*) AS event_count,
    COUNT(DISTINCT customer_id) AS customer_count,
    MIN(event_timestamp) AS first_event,
    MAX(event_timestamp) AS last_event
FROM dbo.fact_events
WHERE session_id IS NOT NULL
GROUP BY session_id
HAVING COUNT(DISTINCT customer_id) > 1
ORDER BY customer_count DESC, event_count DESC;


/* =========================================================
   5. SESSION DURATION REASONABLENESS
   ========================================================= */

WITH session_summary AS (
    SELECT
        session_id,
        MIN(event_timestamp) AS first_event,
        MAX(event_timestamp) AS last_event
    FROM dbo.fact_events
    WHERE session_id IS NOT NULL
    GROUP BY session_id
)
SELECT
    COUNT(*) AS total_sessions,
    SUM(
        CASE
            WHEN DATEDIFF(MINUTE, first_event, last_event) > 30
            THEN 1 ELSE 0
        END
    ) AS sessions_over_30_minutes,
    SUM(
        CASE
            WHEN DATEDIFF(DAY, first_event, last_event) >= 1
            THEN 1 ELSE 0
        END
    ) AS sessions_spanning_multiple_days,
    MAX(DATEDIFF(DAY, first_event, last_event))
        AS maximum_session_length_days
FROM session_summary;