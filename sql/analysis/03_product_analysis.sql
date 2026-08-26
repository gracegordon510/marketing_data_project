USE marketing_analytics;
GO

/* =========================================================
   1. CATEGORY PERFORMANCE
   ========================================================= */
   SELECT
    p.category,

    COUNT(t.transaction_id) AS transaction_count,

    SUM(t.quantity) AS units_recorded,

    SUM(
        CASE
            WHEN t.refund_flag = 0 THEN t.quantity
            ELSE 0
        END
    ) AS units_sold,

    SUM(
        CASE
            WHEN t.refund_flag = 1 THEN t.quantity
            ELSE 0
        END
    ) AS units_refunded,

    -- Pre-discount value of all transaction records,
    -- including refunded transactions
    ROUND(
        SUM(t.gross_revenue),
        2
    ) AS gross_revenue,

    -- Pre-discount value of completed, non-refunded sales
    ROUND(
        SUM(
            CASE
                WHEN t.refund_flag = 0 THEN t.gross_revenue
                ELSE 0
            END
        ),
        2
    ) AS gross_sales,

    -- Amount paid after discounts on completed sales
    ROUND(
        SUM(
            CASE
                WHEN t.refund_flag = 0 THEN t.transaction_amount
                ELSE 0
            END
        ),
        2
    ) AS net_revenue,

    -- Category share of total retained net revenue
    ROUND(
        100.0
        * SUM(
            CASE
                WHEN t.refund_flag = 0 THEN t.transaction_amount
                ELSE 0
            END
        )
        / NULLIF(
            SUM(
                SUM(
                    CASE
                        WHEN t.refund_flag = 0
                            THEN t.transaction_amount
                        ELSE 0
                    END
                )
            ) OVER (),
            0
        ),
        2
    ) AS percent_of_total_net_revenue,

    -- Amount returned to customers
    ROUND(
        ABS(
            SUM(
                CASE
                    WHEN t.refund_flag = 1
                        THEN t.transaction_amount
                    ELSE 0
                END
            )
        ),
        2
    ) AS refund_value,

    -- Difference between pre-discount and paid value
    -- on completed sales
    ROUND(
        SUM(
            CASE
                WHEN t.refund_flag = 0
                    THEN t.gross_revenue - t.transaction_amount
                ELSE 0
            END
        ),
        2
    ) AS discount_value,

    -- Average amount paid per completed transaction
    ROUND(
        AVG(
            CASE
                WHEN t.refund_flag = 0
                    THEN t.transaction_amount
            END
        ),
        2
    ) AS average_transaction_value,

    -- Discounts as a percentage of completed gross sales
    ROUND(
        100.0
        * SUM(
            CASE
                WHEN t.refund_flag = 0
                    THEN t.gross_revenue - t.transaction_amount
                ELSE 0
            END
        )
        / NULLIF(
            SUM(
                CASE
                    WHEN t.refund_flag = 0 THEN t.gross_revenue
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS discount_rate_pct,

    -- Refunded value relative to the pre-discount value
    -- of all recorded transactions
    ROUND(
        100.0
        * ABS(
            SUM(
                CASE
                    WHEN t.refund_flag = 1
                        THEN t.transaction_amount
                    ELSE 0
                END
            )
        )
        / NULLIF(SUM(t.gross_revenue), 0),
        2
    ) AS refund_impact_pct,

    -- Refunded units as a percentage of all recorded units
    ROUND(
        100.0
        * SUM(
            CASE
                WHEN t.refund_flag = 1 THEN t.quantity
                ELSE 0
            END
        )
        / NULLIF(SUM(t.quantity), 0),
        2
    ) AS unit_refund_rate_pct

FROM dbo.fact_transactions AS t

INNER JOIN dbo.dim_products AS p
    ON t.product_id = p.product_id

GROUP BY
    p.category

ORDER BY
    net_revenue DESC;


/* =========================================================
   2. INDIVIDUAL PRODUCT PERFORMANCE
   ========================================================= */

   WITH product_metrics AS (
    SELECT
        p.product_id,
        p.category,

        COUNT(t.transaction_id) AS transaction_count,

        -- Units from all recorded transactions
        SUM(t.quantity) AS units_recorded,

        -- Units retained after excluding refunded records
        SUM(
            CASE
                WHEN t.refund_flag = 0 THEN t.quantity
                ELSE 0
            END
        ) AS units_sold,

        SUM(
            CASE
                WHEN t.refund_flag = 1 THEN t.quantity
                ELSE 0
            END
        ) AS units_refunded,

        -- Pre-discount value of all transaction records,
        -- including refunded records
        SUM(t.gross_revenue) AS gross_revenue,

        -- Pre-discount value of non-refunded sales
        SUM(
            CASE
                WHEN t.refund_flag = 0 THEN t.gross_revenue
                ELSE 0
            END
        ) AS gross_sales,

        -- Amount paid after discounts on non-refunded sales
        SUM(
            CASE
                WHEN t.refund_flag = 0 THEN t.transaction_amount
                ELSE 0
            END
        ) AS net_revenue,

        -- Discount value on non-refunded sales
        SUM(
            CASE
                WHEN t.refund_flag = 0
                    THEN t.gross_revenue - t.transaction_amount
                ELSE 0
            END
        ) AS discount_value,

        -- Amount returned to customers
        ABS(
            SUM(
                CASE
                    WHEN t.refund_flag = 1 THEN t.transaction_amount
                    ELSE 0
                END
            )
        ) AS refund_value,

        -- Product share of total retained net revenue
        100.0
        * SUM(
            CASE
                WHEN t.refund_flag = 0 THEN t.transaction_amount
                ELSE 0
            END
        )
        / NULLIF(
            SUM(
                SUM(
                    CASE
                        WHEN t.refund_flag = 0
                            THEN t.transaction_amount
                        ELSE 0
                    END
                )
            ) OVER (),
            0
        ) AS percent_of_total_net_revenue,

        -- Refunded units relative to all recorded units
        100.0
        * SUM(
            CASE
                WHEN t.refund_flag = 1 THEN t.quantity
                ELSE 0
            END
        )
        / NULLIF(SUM(t.quantity), 0)
            AS unit_refund_rate_pct,

        -- Refunded value relative to the pre-discount value
        -- of all recorded transactions
        100.0
        * ABS(
            SUM(
                CASE
                    WHEN t.refund_flag = 1 THEN t.transaction_amount
                    ELSE 0
                END
            )
        )
        / NULLIF(SUM(t.gross_revenue), 0)
            AS refund_impact_pct,

        -- Discount value relative to completed gross sales
        100.0
        * SUM(
            CASE
                WHEN t.refund_flag = 0
                    THEN t.gross_revenue - t.transaction_amount
                ELSE 0
            END
        )
        / NULLIF(
            SUM(
                CASE
                    WHEN t.refund_flag = 0 THEN t.gross_revenue
                    ELSE 0
                END
            ),
            0
        ) AS discount_rate_pct

    FROM dbo.fact_transactions AS t

    INNER JOIN dbo.dim_products AS p
        ON t.product_id = p.product_id

    GROUP BY
        p.product_id,
        p.category
),

product_benchmarks AS (
    SELECT
        *,

        PERCENTILE_CONT(0.50) WITHIN GROUP (
            ORDER BY unit_refund_rate_pct
        ) OVER () AS median_product_refund_rate,

        PERCENTILE_CONT(0.50) WITHIN GROUP (
            ORDER BY net_revenue
        ) OVER () AS median_product_revenue

    FROM product_metrics
)

SELECT
    product_id,
    category,
    transaction_count,
    units_recorded,
    units_sold,
    units_refunded,

    ROUND(gross_revenue, 2) AS gross_revenue,
    ROUND(gross_sales, 2) AS gross_sales,
    ROUND(discount_value, 2) AS discount_value,
    ROUND(discount_rate_pct, 2) AS discount_rate_pct,
    ROUND(refund_value, 2) AS refund_value,
    ROUND(refund_impact_pct, 2) AS refund_impact_pct,
    ROUND(net_revenue, 2) AS net_revenue,

    ROUND(
        percent_of_total_net_revenue,
        4
    ) AS percent_of_total_net_revenue,

    ROUND(
        unit_refund_rate_pct,
        2
    ) AS unit_refund_rate_pct,

    ROUND(
        median_product_refund_rate,
        2
    ) AS median_product_refund_rate,

    ROUND(
        median_product_revenue,
        2
    ) AS median_product_revenue,

    CASE
        WHEN net_revenue >= median_product_revenue
             AND unit_refund_rate_pct <= median_product_refund_rate
            THEN 'High revenue, low refunds'

        WHEN net_revenue >= median_product_revenue
             AND unit_refund_rate_pct > median_product_refund_rate
            THEN 'High revenue, high refunds'

        WHEN net_revenue < median_product_revenue
             AND unit_refund_rate_pct <= median_product_refund_rate
            THEN 'Low revenue, low refunds'

        WHEN net_revenue < median_product_revenue
             AND unit_refund_rate_pct > median_product_refund_rate
            THEN 'Low revenue, high refunds'
    END AS performance_group

FROM product_benchmarks

ORDER BY
    performance_group,
    net_revenue DESC;

/* =========================================================
   3. PRODUCT REVENUE CONCENTRATION — DETAILED
   ========================================================= */

WITH product_revenue AS (
    SELECT
        p.product_id,
        p.category,

        COUNT(t.transaction_id) AS transaction_count,
        SUM(t.quantity) AS units_recorded,

        SUM(
            CASE
                WHEN t.refund_flag = 0 THEN t.transaction_amount
                ELSE 0
            END
        ) AS net_revenue

    FROM dbo.fact_transactions AS t

    INNER JOIN dbo.dim_products AS p
        ON t.product_id = p.product_id

    GROUP BY
        p.product_id,
        p.category
),

ranked_products AS (
    SELECT
        *,

        ROW_NUMBER() OVER (
            ORDER BY net_revenue DESC
        ) AS revenue_rank,

        COUNT(*) OVER () AS total_product_count,

        SUM(net_revenue) OVER () AS total_net_revenue,

        SUM(net_revenue) OVER (
            ORDER BY net_revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND CURRENT ROW
        ) AS cumulative_net_revenue

    FROM product_revenue
)

SELECT
    product_id,
    category,
    revenue_rank,
    transaction_count,
    units_recorded,

    ROUND(net_revenue, 2) AS net_revenue,

    ROUND(
        100.0 * net_revenue
        / NULLIF(total_net_revenue, 0),
        4
    ) AS revenue_share_pct,

    ROUND(
        100.0 * cumulative_net_revenue
        / NULLIF(total_net_revenue, 0),
        2
    ) AS cumulative_revenue_pct,

    ROUND(
        100.0 * revenue_rank
        / NULLIF(total_product_count, 0),
        2
    ) AS cumulative_product_pct

FROM ranked_products

ORDER BY
    revenue_rank;


/* =========================================================
   4. PRODUCT REVENUE CONCENTRATION — SUMMARY
   ========================================================= */

WITH product_revenue AS (
    SELECT
        p.product_id,

        SUM(
            CASE
                WHEN t.refund_flag = 0 THEN t.transaction_amount
                ELSE 0
            END
        ) AS net_revenue

    FROM dbo.fact_transactions AS t

    INNER JOIN dbo.dim_products AS p
        ON t.product_id = p.product_id

    GROUP BY
        p.product_id
),

ranked_products AS (
    SELECT
        product_id,
        net_revenue,

        ROW_NUMBER() OVER (
            ORDER BY net_revenue DESC
        ) AS revenue_rank,

        COUNT(*) OVER () AS total_product_count,

        SUM(net_revenue) OVER () AS total_net_revenue

    FROM product_revenue
)

SELECT
    total_product_count,

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN revenue_rank <= 10 THEN net_revenue
                ELSE 0
            END
        )
        / NULLIF(MAX(total_net_revenue), 0),
        2
    ) AS top_10_revenue_share_pct,

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN revenue_rank
                     <= CEILING(total_product_count * 0.20)
                    THEN net_revenue
                ELSE 0
            END
        )
        / NULLIF(MAX(total_net_revenue), 0),
        2
    ) AS top_20_percent_revenue_share_pct

FROM ranked_products

GROUP BY
    total_product_count;


/* =========================================================
   5. TOP, BOTTOM, AND HIGH-REFUND PRODUCTS
   ========================================================= */

WITH product_performance AS (
    SELECT
        p.product_id,
        p.category,

        COUNT(t.transaction_id) AS transaction_count,

        SUM(t.quantity) AS units_recorded,

        SUM(
            CASE
                WHEN t.refund_flag = 0 THEN t.quantity
                ELSE 0
            END
        ) AS units_sold,

        SUM(
            CASE
                WHEN t.refund_flag = 1 THEN t.quantity
                ELSE 0
            END
        ) AS units_refunded,

        SUM(t.gross_revenue) AS gross_revenue,

        SUM(
            CASE
                WHEN t.refund_flag = 0 THEN t.gross_revenue
                ELSE 0
            END
        ) AS gross_sales,

        SUM(
            CASE
                WHEN t.refund_flag = 0 THEN t.transaction_amount
                ELSE 0
            END
        ) AS net_revenue,

        ABS(
            SUM(
                CASE
                    WHEN t.refund_flag = 1 THEN t.transaction_amount
                    ELSE 0
                END
            )
        ) AS refund_value,

        100.0
        * SUM(
            CASE
                WHEN t.refund_flag = 1 THEN t.quantity
                ELSE 0
            END
        )
        / NULLIF(SUM(t.quantity), 0)
            AS unit_refund_rate_pct

    FROM dbo.fact_transactions AS t

    INNER JOIN dbo.dim_products AS p
        ON t.product_id = p.product_id

    GROUP BY
        p.product_id,
        p.category
),

ranked_products AS (
    SELECT
        *,

        ROW_NUMBER() OVER (
            ORDER BY net_revenue DESC
        ) AS top_revenue_rank,

        ROW_NUMBER() OVER (
            ORDER BY net_revenue ASC
        ) AS bottom_revenue_rank,

        ROW_NUMBER() OVER (
            ORDER BY unit_refund_rate_pct DESC
        ) AS refund_rate_rank

    FROM product_performance
)

SELECT
    product_id,
    category,
    transaction_count,
    units_recorded,
    units_sold,
    units_refunded,

    ROUND(gross_revenue, 2) AS gross_revenue,
    ROUND(gross_sales, 2) AS gross_sales,
    ROUND(net_revenue, 2) AS net_revenue,
    ROUND(refund_value, 2) AS refund_value,
    ROUND(unit_refund_rate_pct, 2) AS unit_refund_rate_pct,

    top_revenue_rank,
    bottom_revenue_rank,
    refund_rate_rank

FROM ranked_products

WHERE top_revenue_rank <= 10
   OR bottom_revenue_rank <= 10
   OR refund_rate_rank <= 10

ORDER BY
    net_revenue DESC;


/* =========================================================
   6. CATEGORY PERFORMANCE RELATIVE TO CATALOG SIZE
   ========================================================= */

WITH category_catalog AS (
    SELECT
        category,
        COUNT(*) AS product_count

    FROM dbo.dim_products

    GROUP BY
        category
),

category_sales AS (
    SELECT
        p.category,

        SUM(
            CASE
                WHEN t.refund_flag = 0 THEN t.quantity
                ELSE 0
            END
        ) AS units_sold,

        SUM(
            CASE
                WHEN t.refund_flag = 0 THEN t.transaction_amount
                ELSE 0
            END
        ) AS net_revenue

    FROM dbo.fact_transactions AS t

    INNER JOIN dbo.dim_products AS p
        ON t.product_id = p.product_id

    GROUP BY
        p.category
)

SELECT
    c.category,
    c.product_count,

    ROUND(
        100.0 * c.product_count
        / NULLIF(SUM(c.product_count) OVER (), 0),
        2
    ) AS catalog_share_pct,

    s.units_sold,

    ROUND(
        s.net_revenue,
        2
    ) AS net_revenue,

    ROUND(
        100.0 * s.net_revenue
        / NULLIF(SUM(s.net_revenue) OVER (), 0),
        2
    ) AS revenue_share_pct,

    ROUND(
        s.net_revenue
        / NULLIF(c.product_count, 0),
        2
    ) AS revenue_per_product,

    ROUND(
        (
            100.0 * s.net_revenue
            / NULLIF(SUM(s.net_revenue) OVER (), 0)
        )
        -
        (
            100.0 * c.product_count
            / NULLIF(SUM(c.product_count) OVER (), 0)
        ),
        2
    ) AS revenue_vs_catalog_share_pp

FROM category_catalog AS c

INNER JOIN category_sales AS s
    ON c.category = s.category

ORDER BY
    s.net_revenue DESC;


/* =========================================================
   7. MONTHLY CATEGORY PERFORMANCE
   ========================================================= */

SELECT
    DATEFROMPARTS(
        YEAR(t.transaction_timestamp),
        MONTH(t.transaction_timestamp),
        1
    ) AS revenue_month,

    p.category,

    COUNT(t.transaction_id) AS transaction_count,

    SUM(t.quantity) AS units_recorded,

    SUM(
        CASE
            WHEN t.refund_flag = 0 THEN t.quantity
            ELSE 0
        END
    ) AS units_sold,

    SUM(
        CASE
            WHEN t.refund_flag = 1 THEN t.quantity
            ELSE 0
        END
    ) AS units_refunded,

    -- Pre-discount value of all records
    SUM(t.gross_revenue) AS gross_revenue,

    -- Pre-discount value of non-refunded sales
    SUM(
        CASE
            WHEN t.refund_flag = 0 THEN t.gross_revenue
            ELSE 0
        END
    ) AS gross_sales,

    -- Discounts on non-refunded sales
    SUM(
        CASE
            WHEN t.refund_flag = 0
                THEN t.gross_revenue - t.transaction_amount
            ELSE 0
        END
    ) AS discount_value,

    -- Amount paid on non-refunded sales
    SUM(
        CASE
            WHEN t.refund_flag = 0 THEN t.transaction_amount
            ELSE 0
        END
    ) AS net_revenue,

    -- Amount associated with refunded records
    ABS(
        SUM(
            CASE
                WHEN t.refund_flag = 1 THEN t.transaction_amount
                ELSE 0
            END
        )
    ) AS refund_value

FROM dbo.fact_transactions AS t

INNER JOIN dbo.dim_products AS p
    ON t.product_id = p.product_id

GROUP BY
    DATEFROMPARTS(
        YEAR(t.transaction_timestamp),
        MONTH(t.transaction_timestamp),
        1
    ),
    p.category

ORDER BY
    revenue_month,
    p.category;