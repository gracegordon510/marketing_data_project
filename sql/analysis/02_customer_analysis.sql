USE marketing_analytics;
GO


/* =========================================================
   1. CUSTOMER SUMMARY

      Revenue definitions:
   - gross_revenue: Gross revenue before discounts and refunds
   - retained_gross_revenue: Gross revenue (before discounts) of non-refunded transactions only
   - discount_amount: Discount value on non-refunded transactions
   - refunded_transaction_value: Discounted value of refunded
     transactions
   - net_revenue: Revenue retained from non-refunded
     transactions after discounts
   ========================================================= */


WITH customer_purchases AS (
    SELECT
        customer_id,
        COUNT(DISTINCT transaction_id) AS transaction_count,
        SUM(
            CASE
                WHEN refund_flag = 1 THEN 0
                ELSE transaction_amount
            END
) AS net_revenue

    FROM dbo.fact_transactions
    GROUP BY
        customer_id
)

SELECT
    COUNT(DISTINCT c.customer_id) AS total_customers,

    COUNT(DISTINCT cp.customer_id) AS purchasing_customers,

    COUNT(DISTINCT c.customer_id)
        - COUNT(DISTINCT cp.customer_id) AS non_purchasing_customers,

    CAST(
        100.0 * COUNT(DISTINCT cp.customer_id)
        / NULLIF(COUNT(DISTINCT c.customer_id), 0)
        AS DECIMAL(10, 2)
    ) AS customer_purchase_rate_pct,

    SUM(cp.transaction_count) AS total_transactions,

    CAST(
        AVG(CAST(cp.transaction_count AS DECIMAL(10, 2)))
        AS DECIMAL(10, 2)
    ) AS avg_transactions_per_purchasing_customer,

    CAST(
        SUM(cp.net_revenue)
        AS DECIMAL(18, 2)
    ) AS net_revenue,

    CAST(
        AVG(cp.net_revenue)
        AS DECIMAL(18, 2)
    ) AS avg_net_revenue_per_purchasing_customer

FROM dbo.dim_customers AS c
LEFT JOIN customer_purchases AS cp
    ON c.customer_id = cp.customer_id;


/* =========================================================
   2. lOYALTY TIER ANALYSIS
   ========================================================= */

WITH customer_purchases AS (
    SELECT
        t.customer_id,

        /* All transaction records, including refunded records */
        COUNT(DISTINCT t.transaction_id) AS total_transaction_count,

        /* Non-refunded purchases */
        COUNT(DISTINCT CASE
            WHEN t.refund_flag = 0
            THEN t.transaction_id
        END) AS retained_purchase_count,

        /* Refunded transactions */
        COUNT(DISTINCT CASE
            WHEN t.refund_flag = 1
            THEN t.transaction_id
        END) AS refunded_transaction_count,

        /* Gross value of all transactions */
        SUM(t.gross_revenue) AS total_gross_revenue,

        /* Gross value of non-refunded transactions only */
        SUM(
            CASE
                WHEN t.refund_flag = 0
                THEN t.gross_revenue
                ELSE 0
            END
        ) AS retained_gross_revenue,

        /* Discounts applied to non-refunded transactions */
        SUM(
            CASE
                WHEN t.refund_flag = 0
                THEN t.gross_revenue * t.discount_applied
                ELSE 0
            END
        ) AS discount_amount,

        /* Discounted value of refunded transactions */
        SUM(
            CASE
                WHEN t.refund_flag = 1
                THEN ABS(t.transaction_amount)
                ELSE 0
            END
        ) AS refunded_transaction_value,

        /* Revenue retained after discounts; refunds contribute $0 */
        SUM(
            CASE
                WHEN t.refund_flag = 0
                THEN t.transaction_amount
                ELSE 0
            END
        ) AS net_revenue

    FROM dbo.fact_transactions AS t
    GROUP BY
        t.customer_id
)


SELECT
    c.loyalty_tier,

    /* ---------- Customer metrics ---------- */

    COUNT(DISTINCT c.customer_id) AS total_customers,

    COUNT(DISTINCT cp.customer_id) AS purchasing_customers,

    COUNT(DISTINCT c.customer_id)
        - COUNT(DISTINCT cp.customer_id)
        AS non_purchasing_customers,

    CAST(
        100.0 * COUNT(DISTINCT cp.customer_id)
        / NULLIF(COUNT(DISTINCT c.customer_id), 0)
        AS DECIMAL(10, 2)
    ) AS purchase_rate_pct,


    /* ---------- Transaction metrics ---------- */

    SUM(
        COALESCE(cp.total_transaction_count, 0)
    ) AS total_transaction_records,

    SUM(
        COALESCE(cp.retained_purchase_count, 0)
    ) AS retained_purchases,

    SUM(
        COALESCE(cp.refunded_transaction_count, 0)
    ) AS refunded_transactions,

    CAST(
        1.0 * SUM(COALESCE(cp.retained_purchase_count, 0))
        / NULLIF(COUNT(DISTINCT cp.customer_id), 0)
        AS DECIMAL(10, 2)
    ) AS avg_purchases_per_purchasing_customer,


    /* ---------- Repeat-purchase metrics ---------- */

    COUNT(DISTINCT CASE
        WHEN cp.retained_purchase_count >= 2
        THEN cp.customer_id
    END) AS repeat_purchasing_customers,

    CAST(
        100.0 * COUNT(DISTINCT CASE
            WHEN cp.retained_purchase_count >= 2
            THEN cp.customer_id
        END)
        / NULLIF(
            COUNT(DISTINCT CASE
                WHEN cp.retained_purchase_count >= 1
                THEN cp.customer_id
            END),
            0
        )
        AS DECIMAL(10, 2)
    ) AS repeat_purchase_rate_pct,


    /* ---------- Revenue metrics ---------- */

    CAST(
        SUM(COALESCE(cp.total_gross_revenue, 0))
        AS DECIMAL(18, 2)
    ) AS total_gross_revenue,

    CAST(
        SUM(COALESCE(cp.retained_gross_revenue, 0))
        AS DECIMAL(18, 2)
    ) AS retained_gross_revenue,

    CAST(
        SUM(COALESCE(cp.discount_amount, 0))
        AS DECIMAL(18, 2)
    ) AS discount_amount,

    CAST(
        100.0 * SUM(COALESCE(cp.discount_amount, 0))
        / NULLIF(
            SUM(COALESCE(cp.retained_gross_revenue, 0)),
            0
        )
        AS DECIMAL(10, 2)
    ) AS effective_discount_pct,

    CAST(
        SUM(COALESCE(cp.refunded_transaction_value, 0))
        AS DECIMAL(18, 2)
    ) AS refunded_transaction_value,

    CAST(
        SUM(COALESCE(cp.net_revenue, 0))
        AS DECIMAL(18, 2)
    ) AS net_revenue,


    /* ---------- Customer-value metrics ---------- */

    CAST(
        SUM(COALESCE(cp.net_revenue, 0))
        / NULLIF(COUNT(DISTINCT cp.customer_id), 0)
        AS DECIMAL(18, 2)
    ) AS avg_net_revenue_per_purchasing_customer,

    CAST(
        SUM(COALESCE(cp.net_revenue, 0))
        / NULLIF(SUM(COALESCE(cp.retained_purchase_count, 0)), 0)
        AS DECIMAL(18, 2)
    ) AS avg_retained_purchase_value,


    /* ---------- Refund metric ---------- */

    CAST(
        100.0 * SUM(COALESCE(cp.refunded_transaction_count, 0))
        / NULLIF(
            SUM(COALESCE(cp.total_transaction_count, 0)),
            0
        )
        AS DECIMAL(10, 2)
    ) AS transaction_refund_rate_pct

FROM dbo.dim_customers AS c
LEFT JOIN customer_purchases AS cp
    ON c.customer_id = cp.customer_id

GROUP BY
    c.loyalty_tier

ORDER BY
    net_revenue DESC;
GO

/* =========================================================
   3. ACQUISITION ANALYSIS
   ========================================================= */

WITH customer_purchases AS (
    SELECT
        t.customer_id,

        /* All transaction records, including refunded records */
        COUNT(DISTINCT t.transaction_id) AS total_transaction_count,

        /* Non-refunded purchases */
        COUNT(DISTINCT CASE
            WHEN t.refund_flag = 0
            THEN t.transaction_id
        END) AS retained_purchase_count,

        /* Refunded transactions */
        COUNT(DISTINCT CASE
            WHEN t.refund_flag = 1
            THEN t.transaction_id
        END) AS refunded_transaction_count,

        /* Gross value of all transactions */
        SUM(t.gross_revenue) AS total_gross_revenue,

        /* Gross value of non-refunded transactions only */
        SUM(
            CASE
                WHEN t.refund_flag = 0
                THEN t.gross_revenue
                ELSE 0
            END
        ) AS retained_gross_revenue,

        /* Discounts applied to non-refunded transactions */
        SUM(
            CASE
                WHEN t.refund_flag = 0
                THEN t.gross_revenue * t.discount_applied
                ELSE 0
            END
        ) AS discount_amount,

        /* Discounted value of refunded transactions */
        SUM(
            CASE
                WHEN t.refund_flag = 1
                THEN ABS(t.transaction_amount)
                ELSE 0
            END
        ) AS refunded_transaction_value,

        /* Revenue retained after discounts; refunds contribute $0 */
        SUM(
            CASE
                WHEN t.refund_flag = 0
                THEN t.transaction_amount
                ELSE 0
            END
        ) AS net_revenue

    FROM dbo.fact_transactions AS t
    GROUP BY
        t.customer_id
)


SELECT
    c.acquisition_channel,

    /* ---------- Customer metrics ---------- */

    COUNT(DISTINCT c.customer_id) AS total_customers,

    COUNT(DISTINCT cp.customer_id) AS purchasing_customers,

    COUNT(DISTINCT c.customer_id)
        - COUNT(DISTINCT cp.customer_id)
        AS non_purchasing_customers,

    CAST(
        100.0 * COUNT(DISTINCT cp.customer_id)
        / NULLIF(COUNT(DISTINCT c.customer_id), 0)
        AS DECIMAL(10, 2)
    ) AS purchase_rate_pct,


    /* ---------- Transaction metrics ---------- */

    SUM(
        COALESCE(cp.total_transaction_count, 0)
    ) AS total_transaction_records,

    SUM(
        COALESCE(cp.retained_purchase_count, 0)
    ) AS retained_purchases,

    SUM(
        COALESCE(cp.refunded_transaction_count, 0)
    ) AS refunded_transactions,

    CAST(
        1.0 * SUM(COALESCE(cp.retained_purchase_count, 0))
        / NULLIF(COUNT(DISTINCT cp.customer_id), 0)
        AS DECIMAL(10, 2)
    ) AS avg_purchases_per_purchasing_customer,


    /* ---------- Repeat-purchase metrics ---------- */

    COUNT(DISTINCT CASE
        WHEN cp.retained_purchase_count >= 2
        THEN cp.customer_id
    END) AS repeat_purchasing_customers,

    CAST(
        100.0 * COUNT(DISTINCT CASE
            WHEN cp.retained_purchase_count >= 2
            THEN cp.customer_id
        END)
        / NULLIF(
            COUNT(DISTINCT CASE
                WHEN cp.retained_purchase_count >= 1
                THEN cp.customer_id
            END),
            0
        )
        AS DECIMAL(10, 2)
    ) AS repeat_purchase_rate_pct,


    /* ---------- Revenue metrics ---------- */

    CAST(
        SUM(COALESCE(cp.total_gross_revenue, 0))
        AS DECIMAL(18, 2)
    ) AS total_gross_revenue,

    CAST(
        SUM(COALESCE(cp.retained_gross_revenue, 0))
        AS DECIMAL(18, 2)
    ) AS retained_gross_revenue,

    CAST(
        SUM(COALESCE(cp.discount_amount, 0))
        AS DECIMAL(18, 2)
    ) AS discount_amount,

    CAST(
        100.0 * SUM(COALESCE(cp.discount_amount, 0))
        / NULLIF(
            SUM(COALESCE(cp.retained_gross_revenue, 0)),
            0
        )
        AS DECIMAL(10, 2)
    ) AS effective_discount_pct,

    CAST(
        SUM(COALESCE(cp.refunded_transaction_value, 0))
        AS DECIMAL(18, 2)
    ) AS refunded_transaction_value,

    CAST(
        SUM(COALESCE(cp.net_revenue, 0))
        AS DECIMAL(18, 2)
    ) AS net_revenue,


    /* ---------- Customer-value metrics ---------- */

    CAST(
        SUM(COALESCE(cp.net_revenue, 0))
        / NULLIF(COUNT(DISTINCT cp.customer_id), 0)
        AS DECIMAL(18, 2)
    ) AS avg_net_revenue_per_purchasing_customer,

    CAST(
        SUM(COALESCE(cp.net_revenue, 0))
        / NULLIF(SUM(COALESCE(cp.retained_purchase_count, 0)), 0)
        AS DECIMAL(18, 2)
    ) AS avg_retained_purchase_value,


    /* ---------- Refund metric ---------- */

    CAST(
        100.0 * SUM(COALESCE(cp.refunded_transaction_count, 0))
        / NULLIF(
            SUM(COALESCE(cp.total_transaction_count, 0)),
            0
        )
        AS DECIMAL(10, 2)
    ) AS transaction_refund_rate_pct

FROM dbo.dim_customers AS c
LEFT JOIN customer_purchases AS cp
    ON c.customer_id = cp.customer_id

GROUP BY
    c.acquisition_channel

ORDER BY
    net_revenue DESC;
GO

/* =========================================================
   4. ACQUISITION ANALYSIS
   ========================================================= */

WITH customer_purchases AS (
    SELECT
        t.customer_id,

        /* All transaction records, including refunded records */
        COUNT(DISTINCT t.transaction_id) AS total_transaction_count,

        /* Non-refunded purchases */
        COUNT(DISTINCT CASE
            WHEN t.refund_flag = 0
            THEN t.transaction_id
        END) AS retained_purchase_count,

        /* Refunded transactions */
        COUNT(DISTINCT CASE
            WHEN t.refund_flag = 1
            THEN t.transaction_id
        END) AS refunded_transaction_count,

        /* Gross value of all transactions */
        SUM(t.gross_revenue) AS total_gross_revenue,

        /* Gross value of non-refunded transactions only */
        SUM(
            CASE
                WHEN t.refund_flag = 0
                THEN t.gross_revenue
                ELSE 0
            END
        ) AS retained_gross_revenue,

        /* Discounts applied to non-refunded transactions */
        SUM(
            CASE
                WHEN t.refund_flag = 0
                THEN t.gross_revenue * t.discount_applied
                ELSE 0
            END
        ) AS discount_amount,

        /* Discounted value of refunded transactions */
        SUM(
            CASE
                WHEN t.refund_flag = 1
                THEN ABS(t.transaction_amount)
                ELSE 0
            END
        ) AS refunded_transaction_value,

        /* Revenue retained after discounts; refunds contribute $0 */
        SUM(
            CASE
                WHEN t.refund_flag = 0
                THEN t.transaction_amount
                ELSE 0
            END
        ) AS net_revenue

    FROM dbo.fact_transactions AS t
    GROUP BY
        t.customer_id
)


SELECT
    c.country,

    /* ---------- Customer metrics ---------- */

    COUNT(DISTINCT c.customer_id) AS total_customers,

    COUNT(DISTINCT cp.customer_id) AS purchasing_customers,

    COUNT(DISTINCT c.customer_id)
        - COUNT(DISTINCT cp.customer_id)
        AS non_purchasing_customers,

    CAST(
        100.0 * COUNT(DISTINCT cp.customer_id)
        / NULLIF(COUNT(DISTINCT c.customer_id), 0)
        AS DECIMAL(10, 2)
    ) AS purchase_rate_pct,


    /* ---------- Transaction metrics ---------- */

    SUM(
        COALESCE(cp.total_transaction_count, 0)
    ) AS total_transaction_records,

    SUM(
        COALESCE(cp.retained_purchase_count, 0)
    ) AS retained_purchases,

    SUM(
        COALESCE(cp.refunded_transaction_count, 0)
    ) AS refunded_transactions,

    CAST(
        1.0 * SUM(COALESCE(cp.retained_purchase_count, 0))
        / NULLIF(COUNT(DISTINCT cp.customer_id), 0)
        AS DECIMAL(10, 2)
    ) AS avg_purchases_per_purchasing_customer,


    /* ---------- Repeat-purchase metrics ---------- */

    COUNT(DISTINCT CASE
        WHEN cp.retained_purchase_count >= 2
        THEN cp.customer_id
    END) AS repeat_purchasing_customers,

    CAST(
        100.0 * COUNT(DISTINCT CASE
            WHEN cp.retained_purchase_count >= 2
            THEN cp.customer_id
        END)
        / NULLIF(
            COUNT(DISTINCT CASE
                WHEN cp.retained_purchase_count >= 1
                THEN cp.customer_id
            END),
            0
        )
        AS DECIMAL(10, 2)
    ) AS repeat_purchase_rate_pct,


    /* ---------- Revenue metrics ---------- */

    CAST(
        SUM(COALESCE(cp.total_gross_revenue, 0))
        AS DECIMAL(18, 2)
    ) AS total_gross_revenue,

    CAST(
        SUM(COALESCE(cp.retained_gross_revenue, 0))
        AS DECIMAL(18, 2)
    ) AS retained_gross_revenue,

    CAST(
        SUM(COALESCE(cp.discount_amount, 0))
        AS DECIMAL(18, 2)
    ) AS discount_amount,

    CAST(
        100.0 * SUM(COALESCE(cp.discount_amount, 0))
        / NULLIF(
            SUM(COALESCE(cp.retained_gross_revenue, 0)),
            0
        )
        AS DECIMAL(10, 2)
    ) AS effective_discount_pct,

    CAST(
        SUM(COALESCE(cp.refunded_transaction_value, 0))
        AS DECIMAL(18, 2)
    ) AS refunded_transaction_value,

    CAST(
        SUM(COALESCE(cp.net_revenue, 0))
        AS DECIMAL(18, 2)
    ) AS net_revenue,


    /* ---------- Customer-value metrics ---------- */

    CAST(
        SUM(COALESCE(cp.net_revenue, 0))
        / NULLIF(COUNT(DISTINCT cp.customer_id), 0)
        AS DECIMAL(18, 2)
    ) AS avg_net_revenue_per_purchasing_customer,

    CAST(
        SUM(COALESCE(cp.net_revenue, 0))
        / NULLIF(SUM(COALESCE(cp.retained_purchase_count, 0)), 0)
        AS DECIMAL(18, 2)
    ) AS avg_retained_purchase_value,


    /* ---------- Refund metric ---------- */

    CAST(
        100.0 * SUM(COALESCE(cp.refunded_transaction_count, 0))
        / NULLIF(
            SUM(COALESCE(cp.total_transaction_count, 0)),
            0
        )
        AS DECIMAL(10, 2)
    ) AS transaction_refund_rate_pct

FROM dbo.dim_customers AS c
LEFT JOIN customer_purchases AS cp
    ON c.customer_id = cp.customer_id

GROUP BY
    c.country

ORDER BY
    net_revenue DESC;
GO