USE marketing_analytics;
GO

/* =========================================================
   1. CAMPAIGN PORTFOLIO OVERVIEW
   ========================================================= */

SELECT
    COUNT(*) AS total_campaigns,
    COUNT(DISTINCT channel) AS channel_count,
    COUNT(DISTINCT objective) AS objective_count,
    COUNT(DISTINCT target_segment) AS target_segment_count,

    MIN(start_date) AS earliest_start_date,
    MAX(end_date) AS latest_end_date,

    ROUND(AVG(expected_uplift * 100.0), 2)
        AS average_expected_uplift_pct,

    ROUND(MIN(expected_uplift * 100.0), 2)
        AS minimum_expected_uplift_pct,

    ROUND(MAX(expected_uplift * 100.0), 2)
        AS maximum_expected_uplift_pct,

    ROUND(
        AVG(
            1.0 * DATEDIFF(
                DAY,
                start_date,
                end_date
            ) + 1
        ),
        2
    ) AS average_campaign_duration_days

FROM dbo.dim_campaigns
WHERE campaign_id <> 0;

/* =========================================================
   2A. CAMPAIGN PORTFOLIO BY CHANNEL
   ========================================================= */

SELECT
    channel AS campaign_channel,
    COUNT(*) AS campaign_count,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS campaign_percentage,

    ROUND(
        AVG(expected_uplift * 100.0),
        2
    ) AS average_expected_uplift_pct,

    ROUND(
        AVG(
            1.0 * DATEDIFF(DAY, start_date, end_date) + 1
        ),
        2
    ) AS average_duration_days

FROM dbo.dim_campaigns
WHERE campaign_id <> 0
GROUP BY channel
ORDER BY campaign_count DESC;

/* =========================================================
   2B. CAMPAIGN PORTFOLIO BY OBJECTIVE
   ========================================================= */

SELECT
    objective AS campaign_objective,
    COUNT(*) AS campaign_count,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS campaign_percentage,

    ROUND(
        AVG(expected_uplift * 100.0),
        2
    ) AS average_expected_uplift_pct,

    ROUND(
        AVG(
            1.0 * DATEDIFF(DAY, start_date, end_date) + 1
        ),
        2
    ) AS average_duration_days

FROM dbo.dim_campaigns
WHERE campaign_id <> 0
GROUP BY objective
ORDER BY campaign_count DESC;

/* =========================================================
   2C. CAMPAIGN PORTFOLIO BY TARGET SEGMENT
   ========================================================= */

SELECT
    target_segment AS campaign_target_segment,
    COUNT(*) AS campaign_count,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS campaign_percentage,

    ROUND(
        AVG(expected_uplift * 100.0),
        2
    ) AS average_expected_uplift_pct,

    ROUND(
        AVG(
            1.0 * DATEDIFF(DAY, start_date, end_date) + 1
        ),
        2
    ) AS average_duration_days

FROM dbo.dim_campaigns
WHERE campaign_id <> 0
GROUP BY target_segment
ORDER BY campaign_count DESC;

/* =========================================================
   3A. CAMPAIGN ATTRIBUTION COVERAGE — EVENTS
   ========================================================= */

SELECT
    COUNT(*) AS total_events,

    SUM(
        CASE
            WHEN campaign_id IS NULL OR campaign_id = 0
            THEN 1 ELSE 0
        END
    ) AS unattributed_events,

    SUM(
        CASE
            WHEN campaign_id IS NOT NULL AND campaign_id <> 0
            THEN 1 ELSE 0
        END
    ) AS campaign_linked_events,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN campaign_id IS NOT NULL AND campaign_id <> 0
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS campaign_linked_event_pct

FROM dbo.fact_events;


/* =========================================================
   3B. CAMPAIGN ATTRIBUTION COVERAGE — TRANSACTIONS
   ========================================================= */

SELECT
    COUNT(*) AS total_transactions,

    SUM(
        CASE
            WHEN campaign_id IS NULL OR campaign_id = 0
            THEN 1 ELSE 0
        END
    ) AS unattributed_transactions,

    SUM(
        CASE
            WHEN campaign_id IS NOT NULL AND campaign_id <> 0
            THEN 1 ELSE 0
        END
    ) AS campaign_linked_transactions,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN campaign_id IS NOT NULL AND campaign_id <> 0
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS campaign_linked_transaction_pct

FROM dbo.fact_transactions;

/* =========================================================
   4. ATTRIBUTED ACTIVITY BY CAMPAIGN CHANNEL
   ========================================================= */

WITH event_summary AS (
    SELECT
        c.channel AS campaign_channel,
        COUNT(*) AS attributed_events,
        COUNT(DISTINCT e.campaign_id) AS campaigns_with_events
    FROM dbo.fact_events AS e
    INNER JOIN dbo.dim_campaigns AS c
        ON e.campaign_id = c.campaign_id
    WHERE e.campaign_id <> 0
    GROUP BY c.channel
),
transaction_summary AS (
    SELECT
        c.channel,
        COUNT(*) AS attributed_transactions,
        COUNT(DISTINCT t.campaign_id) AS campaigns_with_transactions
    FROM dbo.fact_transactions AS t
    INNER JOIN dbo.dim_campaigns AS c
        ON t.campaign_id = c.campaign_id
    WHERE t.campaign_id <> 0
    GROUP BY c.channel
)
SELECT
    e.campaign_channel,
    e.attributed_events,
    e.campaigns_with_events,
    COALESCE(t.attributed_transactions, 0)
        AS attributed_transactions,
    COALESCE(t.campaigns_with_transactions, 0)
        AS campaigns_with_transactions
FROM event_summary AS e
LEFT JOIN transaction_summary AS t
    ON e.campaign_channel = t.channel
ORDER BY e.attributed_events DESC;

/* =========================================================
   4A. CAMPAIGN-ATTRIBUTED FUNNEL PERFORMANCE BY CHANNEL
   ========================================================= */

WITH channel_events AS (
    SELECT
        c.channel,

        COUNT(*) AS total_events,

        SUM(CASE WHEN e.event_type = 'view' THEN 1 ELSE 0 END)
            AS views,

        SUM(CASE WHEN e.event_type = 'click' THEN 1 ELSE 0 END)
            AS clicks,

        SUM(CASE WHEN e.event_type = 'add_to_cart' THEN 1 ELSE 0 END)
            AS add_to_carts,

        SUM(CASE WHEN e.event_type = 'purchase' THEN 1 ELSE 0 END)
            AS purchases,

        SUM(CASE WHEN e.event_type = 'bounce' THEN 1 ELSE 0 END)
            AS bounces

    FROM dbo.fact_events AS e
    INNER JOIN dbo.dim_campaigns AS c
        ON e.campaign_id = c.campaign_id

    WHERE e.campaign_id <> 0

    GROUP BY c.channel
)

SELECT
    channel AS campaign_channel,
    total_events,
    views,
    clicks,
    add_to_carts,
    purchases,
    bounces,

    ROUND(
        100.0 * clicks / NULLIF(views, 0),
        2
    ) AS view_to_click_event_rate,

    ROUND(
        100.0 * add_to_carts / NULLIF(clicks, 0),
        2
    ) AS click_to_cart_event_rate,

    ROUND(
        100.0 * purchases / NULLIF(add_to_carts, 0),
        2
    ) AS cart_to_purchase_event_rate,

    ROUND(
        100.0 * purchases / NULLIF(views, 0),
        2
    ) AS view_to_purchase_event_rate,

    ROUND(
        100.0 * bounces / NULLIF(total_events, 0),
        2
    ) AS bounce_event_rate

FROM channel_events
ORDER BY view_to_purchase_event_rate DESC;

/* =========================================================
   4B. CAMPAIGN-ATTRIBUTED FUNNEL PERFORMANCE BY OBJECTIVE
   ========================================================= */

WITH channel_events AS (
    SELECT
        c.objective,

        COUNT(*) AS total_events,

        SUM(CASE WHEN e.event_type = 'view' THEN 1 ELSE 0 END)
            AS views,

        SUM(CASE WHEN e.event_type = 'click' THEN 1 ELSE 0 END)
            AS clicks,

        SUM(CASE WHEN e.event_type = 'add_to_cart' THEN 1 ELSE 0 END)
            AS add_to_carts,

        SUM(CASE WHEN e.event_type = 'purchase' THEN 1 ELSE 0 END)
            AS purchases,

        SUM(CASE WHEN e.event_type = 'bounce' THEN 1 ELSE 0 END)
            AS bounces

    FROM dbo.fact_events AS e
    INNER JOIN dbo.dim_campaigns AS c
        ON e.campaign_id = c.campaign_id

    WHERE e.campaign_id <> 0

    GROUP BY c.objective
)

SELECT
    objective AS campaign_objective,
    total_events,
    views,
    clicks,
    add_to_carts,
    purchases,
    bounces,

    ROUND(
        100.0 * clicks / NULLIF(views, 0),
        2
    ) AS view_to_click_event_rate,

    ROUND(
        100.0 * add_to_carts / NULLIF(clicks, 0),
        2
    ) AS click_to_cart_event_rate,

    ROUND(
        100.0 * purchases / NULLIF(add_to_carts, 0),
        2
    ) AS cart_to_purchase_event_rate,

    ROUND(
        100.0 * purchases / NULLIF(views, 0),
        2
    ) AS view_to_purchase_event_rate,

    ROUND(
        100.0 * bounces / NULLIF(total_events, 0),
        2
    ) AS bounce_event_rate

FROM channel_events
ORDER BY view_to_purchase_event_rate DESC;

/* ============================================================
   4C. CAMPAIGN-ATTRIBUTED FUNNEL PERFORMANCE BY TARGET SEGMENT
   ============================================================ */

WITH channel_events AS (
    SELECT
        c.target_segment,

        COUNT(*) AS total_events,

        SUM(CASE WHEN e.event_type = 'view' THEN 1 ELSE 0 END)
            AS views,

        SUM(CASE WHEN e.event_type = 'click' THEN 1 ELSE 0 END)
            AS clicks,

        SUM(CASE WHEN e.event_type = 'add_to_cart' THEN 1 ELSE 0 END)
            AS add_to_carts,

        SUM(CASE WHEN e.event_type = 'purchase' THEN 1 ELSE 0 END)
            AS purchases,

        SUM(CASE WHEN e.event_type = 'bounce' THEN 1 ELSE 0 END)
            AS bounces

    FROM dbo.fact_events AS e
    INNER JOIN dbo.dim_campaigns AS c
        ON e.campaign_id = c.campaign_id

    WHERE e.campaign_id <> 0

    GROUP BY c.target_segment
)

SELECT
    target_segment AS campaign_target_segment,
    total_events,
    views,
    clicks,
    add_to_carts,
    purchases,
    bounces,

    ROUND(
        100.0 * clicks / NULLIF(views, 0),
        2
    ) AS view_to_click_event_rate,

    ROUND(
        100.0 * add_to_carts / NULLIF(clicks, 0),
        2
    ) AS click_to_cart_event_rate,

    ROUND(
        100.0 * purchases / NULLIF(add_to_carts, 0),
        2
    ) AS cart_to_purchase_event_rate,

    ROUND(
        100.0 * purchases / NULLIF(views, 0),
        2
    ) AS view_to_purchase_event_rate,

    ROUND(
        100.0 * bounces / NULLIF(total_events, 0),
        2
    ) AS bounce_event_rate

FROM channel_events
ORDER BY view_to_purchase_event_rate DESC;

/* =================================================================
   4D. CAMPAIGN-ATTRIBUTED FUNNEL PERFORMANCE BY INDIVIDUAL CAMPAIGN
   ================================================================= */

WITH channel_events AS (
    SELECT
        c.campaign_id,

        COUNT(*) AS total_events,

        SUM(CASE WHEN e.event_type = 'view' THEN 1 ELSE 0 END)
            AS views,

        SUM(CASE WHEN e.event_type = 'click' THEN 1 ELSE 0 END)
            AS clicks,

        SUM(CASE WHEN e.event_type = 'add_to_cart' THEN 1 ELSE 0 END)
            AS add_to_carts,

        SUM(CASE WHEN e.event_type = 'purchase' THEN 1 ELSE 0 END)
            AS purchases,

        SUM(CASE WHEN e.event_type = 'bounce' THEN 1 ELSE 0 END)
            AS bounces

    FROM dbo.fact_events AS e
    INNER JOIN dbo.dim_campaigns AS c
        ON e.campaign_id = c.campaign_id

    WHERE e.campaign_id <> 0

    GROUP BY c.campaign_id
)

SELECT
    campaign_id,
    total_events,
    views,
    clicks,
    add_to_carts,
    purchases,
    bounces,

    ROUND(
        100.0 * clicks / NULLIF(views, 0),
        2
    ) AS view_to_click_event_rate,

    ROUND(
        100.0 * add_to_carts / NULLIF(clicks, 0),
        2
    ) AS click_to_cart_event_rate,

    ROUND(
        100.0 * purchases / NULLIF(add_to_carts, 0),
        2
    ) AS cart_to_purchase_event_rate,

    ROUND(
        100.0 * purchases / NULLIF(views, 0),
        2
    ) AS view_to_purchase_event_rate,

    ROUND(
        100.0 * bounces / NULLIF(total_events, 0),
        2
    ) AS bounce_event_rate

FROM channel_events
ORDER BY view_to_purchase_event_rate DESC;

/* =========================================================
   5A. CAMPAIGN-LINKED FINANCIAL PERFORMANCE BY CHANNEL
   ========================================================= */

WITH channel_performance AS (
    SELECT
        c.channel,
        COUNT(DISTINCT c.campaign_id) AS campaign_count,
        COUNT(*) AS transaction_count,

        COUNT(CASE WHEN t.refund_flag = 0 THEN 1 END)
            AS non_refund_transactions,

        COUNT(CASE WHEN t.refund_flag = 1 THEN 1 END)
            AS refund_transactions,

        SUM(CASE
            WHEN t.refund_flag = 0 THEN t.quantity
            ELSE 0
        END) AS units_sold,

        SUM(CASE
            WHEN t.refund_flag = 1 THEN t.quantity
            ELSE 0
        END) AS units_refunded,

        SUM(CASE
            WHEN t.refund_flag = 0 THEN t.gross_revenue
            ELSE 0
        END) AS gross_sales,

        SUM(CASE
            WHEN t.refund_flag = 0
            THEN t.gross_revenue - t.transaction_amount
            ELSE 0
        END) AS discount_value,

        SUM(CASE
            WHEN t.refund_flag = 0 THEN t.transaction_amount
            ELSE 0
        END) AS net_revenue,

        ABS(SUM(CASE
            WHEN t.refund_flag = 1 THEN t.transaction_amount
            ELSE 0
        END)) AS refund_value

    FROM dbo.fact_transactions AS t
    INNER JOIN dbo.dim_campaigns AS c
        ON t.campaign_id = c.campaign_id
    WHERE t.campaign_id <> 0
    GROUP BY c.channel
)

SELECT
    channel AS campaign_channel,
    campaign_count,
    transaction_count,
    non_refund_transactions,
    refund_transactions,
    units_sold,
    units_refunded,
    ROUND(gross_sales, 2) AS gross_sales,
    ROUND(discount_value, 2) AS discount_value,
    ROUND(net_revenue, 2) AS net_revenue,
    ROUND(refund_value, 2) AS refund_value,

    ROUND(
        100.0 * discount_value / NULLIF(gross_sales, 0),
        2
    ) AS discount_rate_pct,

    ROUND(
        100.0 * refund_transactions / NULLIF(transaction_count, 0),
        2
    ) AS transaction_refund_rate_pct,

    ROUND(
        100.0 * refund_value / NULLIF(gross_sales, 0),
        2
    ) AS refund_impact_pct,

    ROUND(
        net_revenue / NULLIF(non_refund_transactions, 0),
        2
    ) AS average_net_revenue_per_sale,

    ROUND(
        net_revenue / NULLIF(campaign_count, 0),
        2
    ) AS average_net_revenue_per_campaign,

    ROUND(
        100.0 * net_revenue
        / NULLIF(SUM(net_revenue) OVER (), 0),
        2
    ) AS net_revenue_share_pct

FROM channel_performance
ORDER BY net_revenue DESC;

/* =========================================================
   5B. CAMPAIGN-LINKED FINANCIAL PERFORMANCE BY OBJECTIVE
   ========================================================= */

WITH objective_performance AS (
    SELECT
        c.objective,
        COUNT(DISTINCT c.campaign_id) AS campaign_count,
        COUNT(*) AS transaction_count,

        COUNT(CASE WHEN t.refund_flag = 0 THEN 1 END)
            AS non_refund_transactions,

        COUNT(CASE WHEN t.refund_flag = 1 THEN 1 END)
            AS refund_transactions,

        SUM(CASE
            WHEN t.refund_flag = 0 THEN t.quantity
            ELSE 0
        END) AS units_sold,

        SUM(CASE
            WHEN t.refund_flag = 1 THEN t.quantity
            ELSE 0
        END) AS units_refunded,

        SUM(CASE
            WHEN t.refund_flag = 0 THEN t.gross_revenue
            ELSE 0
        END) AS gross_sales,

        SUM(CASE
            WHEN t.refund_flag = 0
            THEN t.gross_revenue - t.transaction_amount
            ELSE 0
        END) AS discount_value,

        SUM(CASE
            WHEN t.refund_flag = 0 THEN t.transaction_amount
            ELSE 0
        END) AS net_revenue,

        ABS(SUM(CASE
            WHEN t.refund_flag = 1 THEN t.transaction_amount
            ELSE 0
        END)) AS refund_value

    FROM dbo.fact_transactions AS t
    INNER JOIN dbo.dim_campaigns AS c
        ON t.campaign_id = c.campaign_id
    WHERE t.campaign_id <> 0
    GROUP BY c.objective
)

SELECT
    objective AS campaign_objective,
    campaign_count,
    transaction_count,
    non_refund_transactions,
    refund_transactions,
    units_sold,
    units_refunded,
    ROUND(gross_sales, 2) AS gross_sales,
    ROUND(discount_value, 2) AS discount_value,
    ROUND(net_revenue, 2) AS net_revenue,
    ROUND(refund_value, 2) AS refund_value,

    ROUND(
        100.0 * discount_value / NULLIF(gross_sales, 0),
        2
    ) AS discount_rate_pct,

    ROUND(
        100.0 * refund_transactions / NULLIF(transaction_count, 0),
        2
    ) AS transaction_refund_rate_pct,

    ROUND(
        100.0 * refund_value / NULLIF(gross_sales, 0),
        2
    ) AS refund_impact_pct,

    ROUND(
        net_revenue / NULLIF(non_refund_transactions, 0),
        2
    ) AS average_net_revenue_per_sale,

    ROUND(
        net_revenue / NULLIF(campaign_count, 0),
        2
    ) AS average_net_revenue_per_campaign,

    ROUND(
        100.0 * net_revenue
        / NULLIF(SUM(net_revenue) OVER (), 0),
        2
    ) AS net_revenue_share_pct

FROM objective_performance
ORDER BY net_revenue DESC;


/* ==========================================================
   5C. CAMPAIGN-LINKED FINANCIAL PERFORMANCE BY TARGET SEGMENT
   ========================================================== */

WITH target_segment_performance AS (
    SELECT
        c.target_segment,
        COUNT(DISTINCT c.campaign_id) AS campaign_count,
        COUNT(*) AS transaction_count,

        COUNT(CASE WHEN t.refund_flag = 0 THEN 1 END)
            AS non_refund_transactions,

        COUNT(CASE WHEN t.refund_flag = 1 THEN 1 END)
            AS refund_transactions,

        SUM(CASE
            WHEN t.refund_flag = 0 THEN t.quantity
            ELSE 0
        END) AS units_sold,

        SUM(CASE
            WHEN t.refund_flag = 1 THEN t.quantity
            ELSE 0
        END) AS units_refunded,

        SUM(CASE
            WHEN t.refund_flag = 0 THEN t.gross_revenue
            ELSE 0
        END) AS gross_sales,

        SUM(CASE
            WHEN t.refund_flag = 0
            THEN t.gross_revenue - t.transaction_amount
            ELSE 0
        END) AS discount_value,

        SUM(CASE
            WHEN t.refund_flag = 0 THEN t.transaction_amount
            ELSE 0
        END) AS net_revenue,

        ABS(SUM(CASE
            WHEN t.refund_flag = 1 THEN t.transaction_amount
            ELSE 0
        END)) AS refund_value

    FROM dbo.fact_transactions AS t
    INNER JOIN dbo.dim_campaigns AS c
        ON t.campaign_id = c.campaign_id
    WHERE t.campaign_id <> 0
    GROUP BY c.target_segment
)

SELECT
    target_segment AS campaign_target_segment,
    campaign_count,
    transaction_count,
    non_refund_transactions,
    refund_transactions,
    units_sold,
    units_refunded,
    ROUND(gross_sales, 2) AS gross_sales,
    ROUND(discount_value, 2) AS discount_value,
    ROUND(net_revenue, 2) AS net_revenue,
    ROUND(refund_value, 2) AS refund_value,

    ROUND(
        100.0 * discount_value / NULLIF(gross_sales, 0),
        2
    ) AS discount_rate_pct,

    ROUND(
        100.0 * refund_transactions / NULLIF(transaction_count, 0),
        2
    ) AS transaction_refund_rate_pct,

    ROUND(
        100.0 * refund_value / NULLIF(gross_sales, 0),
        2
    ) AS refund_impact_pct,

    ROUND(
        net_revenue / NULLIF(non_refund_transactions, 0),
        2
    ) AS average_net_revenue_per_sale,

    ROUND(
        net_revenue / NULLIF(campaign_count, 0),
        2
    ) AS average_net_revenue_per_campaign,

    ROUND(
        100.0 * net_revenue
        / NULLIF(SUM(net_revenue) OVER (), 0),
        2
    ) AS net_revenue_share_pct

FROM target_segment_performance
ORDER BY net_revenue DESC;

/* =========================================================
   6. INDIVIDUAL CAMPAIGN PERFORMANCE
   ========================================================= */

WITH campaign_performance AS (
    SELECT
        c.campaign_id,
        c.channel,
        c.objective,
        c.target_segment,

        COUNT(*) AS transaction_count,

        COUNT(CASE
            WHEN t.refund_flag = 0 THEN 1
        END) AS non_refund_transactions,

        COUNT(CASE
            WHEN t.refund_flag = 1 THEN 1
        END) AS refund_transactions,

        SUM(CASE
            WHEN t.refund_flag = 0 THEN t.gross_revenue
            ELSE 0
        END) AS gross_sales,

        SUM(CASE
            WHEN t.refund_flag = 0
            THEN t.gross_revenue - t.transaction_amount
            ELSE 0
        END) AS discount_value,

        SUM(CASE
            WHEN t.refund_flag = 0 THEN t.transaction_amount
            ELSE 0
        END) AS net_revenue,

        ABS(SUM(CASE
            WHEN t.refund_flag = 1 THEN t.transaction_amount
            ELSE 0
        END)) AS refund_value

    FROM dbo.fact_transactions AS t
    INNER JOIN dbo.dim_campaigns AS c
        ON t.campaign_id = c.campaign_id

    WHERE t.campaign_id <> 0

    GROUP BY
        c.campaign_id,
        c.channel,
        c.objective,
        c.target_segment
)

SELECT
    campaign_id,
    channel,
    objective,
    target_segment,
    transaction_count,
    non_refund_transactions,
    refund_transactions,
    ROUND(gross_sales, 2) AS gross_sales,
    ROUND(discount_value, 2) AS discount_value,
    ROUND(net_revenue, 2) AS net_revenue,
    ROUND(refund_value, 2) AS refund_value,

    ROUND(
        100.0 * refund_transactions
        / NULLIF(transaction_count, 0),
        2
    ) AS transaction_refund_rate_pct,

    ROUND(
        100.0 * refund_value
        / NULLIF(gross_sales, 0),
        2
    ) AS refund_impact_pct,

    ROUND(
        net_revenue
        / NULLIF(non_refund_transactions, 0),
        2
    ) AS average_net_revenue_per_sale,

    ROUND(
        100.0 * net_revenue
        / NULLIF(SUM(net_revenue) OVER (), 0),
        2
    ) AS net_revenue_share_pct,

    DENSE_RANK() OVER (
        ORDER BY net_revenue DESC
    ) AS revenue_rank

FROM campaign_performance
ORDER BY revenue_rank;

/* =========================================================
   7. INDIVIDUAL CAMPAIGN CATEGORIZATION
   ========================================================= */


WITH campaign_performance AS (
    SELECT
        c.campaign_id,
        c.channel,
        c.objective,
        c.target_segment,

        COUNT(*) AS transaction_count,

        COUNT(CASE
            WHEN t.refund_flag = 0 THEN 1
        END) AS non_refund_transactions,

        COUNT(CASE
            WHEN t.refund_flag = 1 THEN 1
        END) AS refund_transactions,

        SUM(CASE
            WHEN t.refund_flag = 0 THEN t.gross_revenue
            ELSE 0
        END) AS gross_sales,

        SUM(CASE
            WHEN t.refund_flag = 0 THEN t.transaction_amount
            ELSE 0
        END) AS net_revenue,

        ABS(SUM(CASE
            WHEN t.refund_flag = 1 THEN t.transaction_amount
            ELSE 0
        END)) AS refund_value

    FROM dbo.fact_transactions AS t
    INNER JOIN dbo.dim_campaigns AS c
        ON t.campaign_id = c.campaign_id
    WHERE t.campaign_id <> 0
    GROUP BY
        c.campaign_id,
        c.channel,
        c.objective,
        c.target_segment
),
campaign_metrics AS (
    SELECT
        *,
        net_revenue
            / NULLIF(non_refund_transactions, 0)
            AS revenue_per_sale,

        100.0 * refund_transactions
            / NULLIF(transaction_count, 0)
            AS refund_rate_pct,

        100.0 * refund_value
            / NULLIF(gross_sales, 0)
            AS refund_impact_pct

    FROM campaign_performance
)
SELECT
    campaign_id,
    channel,
    objective,
    target_segment,
    transaction_count,
    non_refund_transactions,
    ROUND(net_revenue, 2) AS net_revenue,
    ROUND(revenue_per_sale, 2) AS revenue_per_sale,
    ROUND(refund_rate_pct, 2) AS refund_rate_pct,
    ROUND(refund_impact_pct, 2) AS refund_impact_pct,

    ROUND(
        AVG(transaction_count * 1.0) OVER (),
        2
    ) AS portfolio_avg_transactions,

    ROUND(
        AVG(revenue_per_sale) OVER (),
        2
    ) AS portfolio_avg_revenue_per_sale,

    CASE
        WHEN net_revenue < AVG(net_revenue) OVER ()
         AND transaction_count < AVG(transaction_count * 1.0) OVER ()
         AND revenue_per_sale >= AVG(revenue_per_sale) OVER ()
            THEN 'Low revenue — likely low volume'

        WHEN net_revenue < AVG(net_revenue) OVER ()
         AND revenue_per_sale < AVG(revenue_per_sale) OVER ()
            THEN 'Low revenue and below-average efficiency'

        WHEN net_revenue >= AVG(net_revenue) OVER ()
         AND transaction_count >= AVG(transaction_count * 1.0) OVER ()
         AND revenue_per_sale < AVG(revenue_per_sale) OVER ()
            THEN 'High revenue — volume driven'

        WHEN net_revenue >= AVG(net_revenue) OVER ()
         AND revenue_per_sale >= AVG(revenue_per_sale) OVER ()
            THEN 'Strong revenue and efficiency'

        ELSE 'Mixed performance'
    END AS performance_interpretation

FROM campaign_metrics
ORDER BY performance_interpretation, net_revenue DESC;


