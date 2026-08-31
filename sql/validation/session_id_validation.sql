USE marketing_analytics;
GO

/*
=========================================================
SESSION ID RELIABILITY VALIDATION
=========================================================

PURPOSE:
Determine whether session_id, alone or combined with
customer_id, reliably identifies continuous browsing sessions.

VALIDATION CHECKS:
- Check session_id completeness.
- Calculate events associated with each session ID.
- Count customers associated with each session ID.
- Evaluate apparent session duration.
- Test customer_id and session_id as a combined identifier.

KEY FINDINGS:
- No session IDs are missing.
- The 1,989,551 retained events contain 632,903 distinct
  session IDs.
- 532,330 session IDs (84.11%) are associated with multiple
  customers.
- 532,326 session IDs (84.11%) last longer than 30 minutes.
- 532,202 session IDs (84.09%) span multiple calendar days.
- One session ID is associated with as many as 14 customers.
- The longest apparent session spans 1,094 days.
- Combining session_id with customer_id produces 1,989,512
  customer-session combinations.
- Of these combinations, 1,989,473 contain only one event,
  representing approximately 99.998% of the total.
- The remaining 39 multi-event combinations all last longer
  than 30 minutes and span multiple days.
- The longest customer-session combination spans 1,032 days.

ANALYTICAL DECISION:
Neither session_id alone nor the combination of customer_id
and session_id is used for session-level analysis. The dataset
does not reliably support session duration, events per session,
session conversion rates, session bounce rates, or session-based
customer journeys.

Funnel measures may be reported as aggregate event-count ratios,
but not as session-level conversion rates.
=========================================================
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
    COUNT(*) AS total_sessions,
    ROUND(
    100.0 * SUM(CASE WHEN event_count = 1 THEN 1 ELSE 0 END)
    / NULLIF(COUNT(*), 0),
    2
) AS single_event_session_pct
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
   4. EXAMPLES OF UNRELIABLE SESSIONS
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
        AS maximum_session_length_days,
    ROUND(
    100.0 * SUM(
        CASE
            WHEN DATEDIFF(MINUTE, first_event, last_event) > 30
            THEN 1 ELSE 0
        END
    ) / NULLIF(COUNT(*), 0),
    2
    ) AS sessions_over_30_minutes_pct,
    ROUND(
    100.0 * SUM(
        CASE
            WHEN DATEDIFF(DAY, first_event, last_event) >= 1
            THEN 1 ELSE 0
        END
    ) / NULLIF(COUNT(*), 0),
    2
) AS sessions_spanning_multiple_days_pct
FROM session_summary;


/* =========================================================
   6. COMBINED CUSTOMER AND SESSION ID VALIDATION
   ========================================================= */
WITH customer_sessions AS (
    SELECT
        customer_id,
        session_id,
        COUNT(*) AS event_count,
        MIN(event_timestamp) AS first_event,
        MAX(event_timestamp) AS last_event
    FROM dbo.fact_events
    WHERE session_id IS NOT NULL
    GROUP BY
        customer_id,
        session_id
)
SELECT
    COUNT(*) AS total_customer_sessions,

    SUM(
        CASE WHEN event_count = 1 THEN 1 ELSE 0 END
    ) AS single_event_sessions,

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

FROM customer_sessions;