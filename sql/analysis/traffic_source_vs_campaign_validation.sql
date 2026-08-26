USE marketing_analytics;
GO

/*
DATA QUALITY NOTE: TRAFFIC SOURCE VS CAMPAIGN CHANNEL

Campaign-linked events were distributed across campaign channels in
nearly identical proportions for Email, Paid Search, and Social traffic.

For example, Email-sourced events were not primarily associated with
Email campaigns. Instead, their campaign-channel distribution closely
matched the overall campaign portfolio.

This suggests that campaign_id was assigned independently of
traffic_source in the synthetic dataset. Traffic source and campaign
channel are therefore analyzed as separate source-provided fields and
are not treated as a consistent attribution hierarchy.
*/

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