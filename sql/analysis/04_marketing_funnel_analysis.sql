USE marketing_analytics;
GO


/* =========================================================
   1. MARKETING FUNNEL EVENT SUMMARY
   ========================================================= */

SELECT
    COUNT(*) AS total_events,

    SUM(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS views,
    SUM(CASE WHEN event_type = 'click' THEN 1 ELSE 0 END) AS clicks,
    SUM(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END) AS add_to_carts,
    SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchases,
    SUM(CASE WHEN event_type = 'bounce' THEN 1 ELSE 0 END) AS bounces,

    ROUND(
        100.0 * SUM(CASE WHEN event_type = 'click' THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END), 0),
        2
    ) AS view_to_click_event_rate,

    ROUND(
        100.0 * SUM(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN event_type = 'click' THEN 1 ELSE 0 END), 0),
        2
    ) AS click_to_cart_event_rate,

    ROUND(
        100.0 * SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END), 0),
        2
    ) AS cart_to_purchase_event_rate,

    ROUND(
        100.0 * SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END), 0),
        2
    ) AS view_to_purchase_event_rate,

    ROUND(
        100.0 * SUM(CASE WHEN event_type = 'bounce' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS bounce_event_rate

FROM dbo.fact_events;


/* =========================================================
   2. FUNNEL EVENT PERFORMANCE BY TRAFFIC SOURCE
   ========================================================= */

SELECT
    traffic_source,

    COUNT(*) AS total_events,

    SUM(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS views,
    SUM(CASE WHEN event_type = 'click' THEN 1 ELSE 0 END) AS clicks,
    SUM(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END) AS add_to_carts,
    SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchases,
    SUM(CASE WHEN event_type = 'bounce' THEN 1 ELSE 0 END) AS bounces,

    ROUND(
        100.0 * SUM(CASE WHEN event_type = 'click' THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END), 0),
        2
    ) AS view_to_click_event_rate,

    ROUND(
        100.0 * SUM(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN event_type = 'click' THEN 1 ELSE 0 END), 0),
        2
    ) AS click_to_cart_event_rate,

    ROUND(
        100.0 * SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END), 0),
        2
    ) AS cart_to_purchase_event_rate,

    ROUND(
        100.0 * SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END), 0),
        2
    ) AS view_to_purchase_event_rate,

    ROUND(
        100.0 * SUM(CASE WHEN event_type = 'bounce' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS bounce_event_rate

FROM dbo.fact_events
GROUP BY traffic_source
ORDER BY view_to_purchase_event_rate DESC;


/* =========================================================
   3. PERFORMANCE BY DEVICE TYPE
   ========================================================= */

SELECT
    COALESCE(device_type, 'Unknown') AS device_type,

    COUNT(*) AS total_events,

    SUM(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS views,
    SUM(CASE WHEN event_type = 'click' THEN 1 ELSE 0 END) AS clicks,
    SUM(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END)
        AS add_to_carts,
    SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END)
        AS purchases,
    SUM(CASE WHEN event_type = 'bounce' THEN 1 ELSE 0 END) AS bounces,

    ROUND(
        100.0 * SUM(CASE WHEN event_type = 'click' THEN 1 ELSE 0 END)
        / NULLIF(
            SUM(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END),
            0
        ),
        2
    ) AS view_to_click_event_rate,

    ROUND(
        100.0 * SUM(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END)
        / NULLIF(
            SUM(CASE WHEN event_type = 'click' THEN 1 ELSE 0 END),
            0
        ),
        2
    ) AS click_to_cart_event_rate,

    ROUND(
        100.0 * SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END)
        / NULLIF(
            SUM(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END),
            0
        ),
        2
    ) AS cart_to_purchase_event_rate,

    ROUND(
        100.0 * SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END)
        / NULLIF(
            SUM(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END),
            0
        ),
        2
    ) AS view_to_purchase_event_rate,

    ROUND(
        100.0 * SUM(CASE WHEN event_type = 'bounce' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS bounce_event_rate

FROM dbo.fact_events
GROUP BY COALESCE(device_type, 'Unknown')
ORDER BY view_to_purchase_event_rate DESC;

/* =========================================================
   4. MONTHLY FUNNEL EVENT TRENDS
   ========================================================= */

WITH monthly_events AS (
    SELECT
        DATEFROMPARTS(
            YEAR(event_timestamp),
            MONTH(event_timestamp),
            1
        ) AS event_month,

        COUNT(*) AS total_events,

        SUM(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END)
            AS views,

        SUM(CASE WHEN event_type = 'click' THEN 1 ELSE 0 END)
            AS clicks,

        SUM(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END)
            AS add_to_carts,

        SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END)
            AS purchases,

        SUM(CASE WHEN event_type = 'bounce' THEN 1 ELSE 0 END)
            AS bounces

    FROM dbo.fact_events
    GROUP BY
        DATEFROMPARTS(
            YEAR(event_timestamp),
            MONTH(event_timestamp),
            1
        )
)

SELECT
    event_month,
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

FROM monthly_events
ORDER BY event_month;


/* =========================================================
   5. SEASONAL FUNNEL PERFORMANCE BY TRAFFIC SOURCE
   ========================================================= */

WITH seasonal_events AS (
    SELECT
        traffic_source,

        CASE
            WHEN MONTH(event_timestamp) IN (11, 12)
                THEN 'Holiday'
            ELSE 'Non-Holiday'
        END AS season,

        COUNT(*) AS total_events,

        SUM(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END)
            AS views,

        SUM(CASE WHEN event_type = 'click' THEN 1 ELSE 0 END)
            AS clicks,

        SUM(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END)
            AS add_to_carts,

        SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END)
            AS purchases,

        SUM(CASE WHEN event_type = 'bounce' THEN 1 ELSE 0 END)
            AS bounces

    FROM dbo.fact_events
    GROUP BY
        traffic_source,
        CASE
            WHEN MONTH(event_timestamp) IN (11, 12)
                THEN 'Holiday'
            ELSE 'Non-Holiday'
        END
)

SELECT
    traffic_source,
    season,
    total_events,
    views,
    clicks,
    add_to_carts,
    purchases,

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

FROM seasonal_events
ORDER BY traffic_source, season;
