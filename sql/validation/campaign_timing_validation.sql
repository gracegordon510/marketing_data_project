USE marketing_analytics;
GO

/*
=========================================================
CAMPAIGN TIMING VALIDATION
=========================================================

PURPOSE:
Determine whether events and transactions attributed to a
campaign occurred during the campaign's recorded active period.

VALIDATION CHECKS:
- Check campaign dates for missing or invalid values.
- Compare event timestamps with campaign dates.
- Compare transaction timestamps with campaign dates.
- Calculate the percentage of attributed activity occurring
  inside and outside the campaign window.

KEY FINDINGS:
- Only 4.74% of campaign-linked events occurred during the
  associated campaign's active period.
- Only 4.94% of campaign-linked transactions occurred during
  the associated campaign's active period.
- Approximately 95% of attributed activity occurred outside
  the recorded campaign dates.

ANALYTICAL DECISION:
Campaign dates are not used to establish campaign exposure,
filter campaign performance, compare active and inactive
periods, or estimate incremental uplift. campaign_id is
retained as source-provided attribution only.

Campaign end_date is treated as inclusive. Activity is inside
the campaign window when its timestamp is on or after
start_date and before the day following end_date.
=========================================================
*/

/* =========================================================
   1. CAMPAIGN DATE INTEGRITY
   ========================================================= */

SELECT
    COUNT(*) AS total_campaigns,

    SUM(
        CASE
            WHEN start_date IS NULL OR end_date IS NULL
            THEN 1 ELSE 0
        END
    ) AS campaigns_with_missing_dates,

    SUM(
        CASE
            WHEN end_date < start_date
            THEN 1 ELSE 0
        END
    ) AS campaigns_with_invalid_date_range

FROM dbo.dim_campaigns
WHERE campaign_id <> 0;


/* =========================================================
   2. EVENT TIMING VALIDATION
   ========================================================= */

SELECT
    COUNT(*) AS campaign_linked_events,

    SUM(
        CASE
            WHEN e.event_timestamp < c.start_date
            THEN 1 ELSE 0
        END
    ) AS events_before_campaign,

    SUM(
        CASE
            WHEN e.event_timestamp >= c.start_date
             AND e.event_timestamp < DATEADD(DAY, 1, c.end_date)
            THEN 1 ELSE 0
        END
    ) AS events_during_campaign,

    SUM(
        CASE
            WHEN e.event_timestamp >= DATEADD(DAY, 1, c.end_date)
            THEN 1 ELSE 0
        END
    ) AS events_after_campaign,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN e.event_timestamp >= c.start_date
                 AND e.event_timestamp < DATEADD(DAY, 1, c.end_date)
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS within_campaign_pct,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN e.event_timestamp < c.start_date
                  OR e.event_timestamp >= DATEADD(DAY, 1, c.end_date)
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS outside_campaign_pct

FROM dbo.fact_events AS e
INNER JOIN dbo.dim_campaigns AS c
    ON e.campaign_id = c.campaign_id
WHERE e.campaign_id <> 0;


/* =========================================================
   3. TRANSACTION TIMING VALIDATION
   ========================================================= */

SELECT
    COUNT(*) AS campaign_linked_transactions,

    SUM(
        CASE
            WHEN t.transaction_timestamp < c.start_date
            THEN 1 ELSE 0
        END
    ) AS transactions_before_campaign,

    SUM(
        CASE
            WHEN t.transaction_timestamp >= c.start_date
             AND t.transaction_timestamp < DATEADD(DAY, 1, c.end_date)
            THEN 1 ELSE 0
        END
    ) AS transactions_during_campaign,

    SUM(
        CASE
            WHEN t.transaction_timestamp >= DATEADD(DAY, 1, c.end_date)
            THEN 1 ELSE 0
        END
    ) AS transactions_after_campaign,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN t.transaction_timestamp >= c.start_date
                 AND t.transaction_timestamp < DATEADD(DAY, 1, c.end_date)
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS within_campaign_pct,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN t.transaction_timestamp < c.start_date
                  OR t.transaction_timestamp >= DATEADD(DAY, 1, c.end_date)
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS outside_campaign_pct

FROM dbo.fact_transactions AS t
INNER JOIN dbo.dim_campaigns AS c
    ON t.campaign_id = c.campaign_id
WHERE t.campaign_id <> 0;