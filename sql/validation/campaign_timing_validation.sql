USE marketing_analytics;
GO

/*
DATA QUALITY NOTE: CAMPAIGN TIMING

Events and transactions can be associated with campaigns through
campaign_id. However, campaign start_date and end_date do not align
reliably with the timestamps of attributed activity.

Campaign_id is therefore treated as source-provided attribution.
Campaign dates are not used to filter performance, establish exposure,
or measure causal or incremental uplift.
*/

SELECT
    COUNT(*) AS campaign_linked_events,

    SUM(
        CASE
            WHEN e.event_timestamp >= c.start_date
             AND e.event_timestamp < DATEADD(DAY, 1, c.end_date)
            THEN 1 ELSE 0
        END
    ) AS events_during_campaign,

    SUM(
        CASE
            WHEN e.event_timestamp < c.start_date
              OR e.event_timestamp >= DATEADD(DAY, 1, c.end_date)
            THEN 1 ELSE 0
        END
    ) AS events_outside_campaign,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN e.event_timestamp >= c.start_date
                 AND e.event_timestamp < DATEADD(DAY, 1, c.end_date)
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS within_campaign_pct

FROM dbo.fact_events AS e
INNER JOIN dbo.dim_campaigns AS c
    ON e.campaign_id = c.campaign_id
WHERE e.campaign_id <> 0;



SELECT
    COUNT(*) AS campaign_linked_transactions,

    SUM(
        CASE
            WHEN t.transaction_timestamp >= c.start_date
             AND t.transaction_timestamp < DATEADD(DAY, 1, c.end_date)
            THEN 1 ELSE 0
        END
    ) AS events_during_campaign,

    SUM(
        CASE
            WHEN t.transaction_timestamp < c.start_date
              OR t.transaction_timestamp >= DATEADD(DAY, 1, c.end_date)
            THEN 1 ELSE 0
        END
    ) AS events_outside_campaign,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN t.transaction_timestamp >= c.start_date
                 AND t.transaction_timestamp < DATEADD(DAY, 1, c.end_date)
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS within_campaign_pct

FROM dbo.fact_transactions AS t
INNER JOIN dbo.dim_campaigns AS c
    ON t.campaign_id = c.campaign_id
WHERE t.campaign_id <> 0;