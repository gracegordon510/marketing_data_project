USE marketing_analytics;
GO

/*
=========================================================
TRAFFIC SOURCE AND CAMPAIGN CHANNEL VALIDATION
=========================================================

PURPOSE:
Determine whether an event's traffic_source is consistent with
the channel of its attributed campaign.

VALIDATION CHECKS:
- Measure campaign attribution by traffic source.
- Compare campaign-channel distributions across traffic
  sources.
- Calculate direct matches between traffic_source and campaign
  channel where equivalent labels exist.

KEY FINDINGS:
- Campaign-linked events occur only for Email, Paid Search,
  and Social traffic.
- All Organic events (798,768) and Direct events (199,317)
  are unattributed to campaigns.
- All Paid Search (396,423), Social (298,026), and Email
  events (297,017) are linked to campaigns.
- Matching-channel rates are low: 22.17% for Email, 21.97%
  for Paid Search, and 15.91% for Social.
- Campaign-channel distributions are nearly identical across
  Email, Paid Search, and Social traffic, suggesting that
  campaign_id was assigned independently of traffic_source.
- Affiliate and Display campaign channels do not have direct
  equivalents in the traffic_source field.

ANALYTICAL DECISION:
traffic_source and campaign channel are treated as separate
source-provided dimensions rather than as a consistent
attribution hierarchy.

Performance by traffic source is not interpreted as the
performance of campaigns using the corresponding channel.
=========================================================
*/

/* =========================================================
   1. CAMPAIGN ATTRIBUTION BY TRAFFIC SOURCE
   ========================================================= */

SELECT
    traffic_source,
    COUNT(*) AS total_events,

    SUM(
        CASE WHEN campaign_id <> 0 THEN 1 ELSE 0 END
    ) AS campaign_linked_events,

    SUM(
        CASE WHEN campaign_id = 0 THEN 1 ELSE 0 END
    ) AS unattributed_events,

    ROUND(
        100.0 * SUM(
            CASE WHEN campaign_id <> 0 THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS campaign_linked_pct

FROM dbo.fact_events
GROUP BY traffic_source
ORDER BY total_events DESC;

/* =========================================================
   2. CAMPAIGN CHANNEL DISTRIBUTION BY TRAFFIC SOURCE
   ========================================================= */

SELECT
    e.traffic_source,
    c.channel AS campaign_channel,
    COUNT(*) AS event_count,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (
            PARTITION BY e.traffic_source
        ),
        2
    ) AS pct_of_traffic_source

FROM dbo.fact_events AS e
INNER JOIN dbo.dim_campaigns AS c
    ON e.campaign_id = c.campaign_id

WHERE e.campaign_id <> 0

GROUP BY
    e.traffic_source,
    c.channel

ORDER BY
    e.traffic_source,
    event_count DESC;

/* =========================================================
   3. TRAFFIC SOURCE AND CAMPAIGN CHANNEL ALIGNMENT
   ========================================================= */

SELECT
    e.traffic_source,
    COUNT(*) AS campaign_linked_events,

    SUM(
        CASE
            WHEN e.traffic_source = c.channel
            THEN 1 ELSE 0
        END
    ) AS matching_channel_events,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN e.traffic_source = c.channel
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS matching_channel_pct

FROM dbo.fact_events AS e
INNER JOIN dbo.dim_campaigns AS c
    ON e.campaign_id = c.campaign_id
WHERE e.campaign_id <> 0
GROUP BY e.traffic_source
ORDER BY e.traffic_source;