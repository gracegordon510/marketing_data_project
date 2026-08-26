USE marketing_analytics;
GO

/* =========================================================
   1. EXECUTIVE KPI SUMMARY
   ========================================================= */

SELECT
    -- Revenue before discounts and refunds
    SUM(gross_revenue) AS gross_revenue,

    -- Total discounts applied to all purchases
    SUM(
        gross_revenue - ABS(transaction_amount)
    ) AS discount_value,

    -- Post-discount value of refunded purchases
    SUM(
        CASE
            WHEN refund_flag = 1
                THEN ABS(transaction_amount)
            ELSE 0
        END
    ) AS refund_value,

    -- Post-discount revenue retained after refunds
    SUM(
        CASE
            WHEN refund_flag = 0
                THEN transaction_amount
            ELSE 0
        END
    ) AS net_revenue,

    COUNT(DISTINCT transaction_id) AS total_transactions,

    COUNT(DISTINCT customer_id) AS purchasing_customers,

    SUM(quantity) AS units_sold,

    AVG(ABS(transaction_amount))
        AS average_transaction_value,

    SUM(
        CASE WHEN refund_flag = 1 THEN 1 ELSE 0 END
    ) AS refunded_transactions,

    CAST(
        1.0 * SUM(CASE WHEN refund_flag = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10, 4)
    ) AS refund_rate

FROM dbo.fact_transactions;

/* =========================================================
   2. REPORTING PERIOD
   ========================================================= */

SELECT
    MIN(transaction_timestamp) AS first_transaction,
    MAX(transaction_timestamp) AS last_transaction,
    DATEDIFF(
        DAY,
        MIN(transaction_timestamp),
        MAX(transaction_timestamp)
    ) + 1 AS reporting_period_days
FROM dbo.fact_transactions;


/* =========================================================
   3. YEARLY PERFORMANCE
   ========================================================= */

SELECT
    YEAR(transaction_timestamp) AS transaction_year,

    SUM(gross_revenue) AS gross_revenue,

    SUM(
        gross_revenue - ABS(transaction_amount)
    ) AS discount_value,

    SUM(
        CASE
            WHEN refund_flag = 1
                THEN ABS(transaction_amount)
            ELSE 0
        END
    ) AS refund_value,

    SUM(
        CASE
            WHEN refund_flag = 0
                THEN transaction_amount
            ELSE 0
        END
    ) AS net_revenue,

    COUNT(DISTINCT transaction_id) AS total_transactions,
    COUNT(DISTINCT customer_id) AS purchasing_customers,
    SUM(quantity) AS units_sold,

    AVG(ABS(transaction_amount))
        AS average_transaction_value,

    CAST(
        1.0 * SUM(CASE WHEN refund_flag = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10, 4)
    ) AS refund_rate

FROM dbo.fact_transactions
GROUP BY YEAR(transaction_timestamp)
ORDER BY transaction_year;

/* =========================================================
   4. MONTHLY PERFORMANCE
   ========================================================= */

WITH monthly_performance AS (
    SELECT
        DATEFROMPARTS(
            YEAR(transaction_timestamp),
            MONTH(transaction_timestamp),
            1
        ) AS transaction_month,

        SUM(gross_revenue) AS gross_revenue,

        SUM(
            gross_revenue - ABS(transaction_amount)
        ) AS discount_value,

        SUM(
            CASE
                WHEN refund_flag = 1
                    THEN ABS(transaction_amount)
                ELSE 0
            END
        ) AS refund_value,

        SUM(
            CASE
                WHEN refund_flag = 0
                    THEN transaction_amount
                ELSE 0
            END
        ) AS net_revenue,

        COUNT(DISTINCT transaction_id) AS total_transactions,
        COUNT(DISTINCT customer_id) AS purchasing_customers,
        SUM(quantity) AS units_sold,

        AVG(ABS(transaction_amount))
            AS average_transaction_value,

        CAST(
            1.0 * SUM(CASE WHEN refund_flag = 1 THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0)
            AS DECIMAL(10, 4)
        ) AS refund_rate

    FROM dbo.fact_transactions
    GROUP BY
        YEAR(transaction_timestamp),
        MONTH(transaction_timestamp)
)

SELECT
    transaction_month,
    gross_revenue,
    discount_value,
    refund_value,
    net_revenue,
    total_transactions,
    purchasing_customers,
    units_sold,
    average_transaction_value,
    refund_rate,

    LAG(net_revenue, 12) OVER (
        ORDER BY transaction_month
    ) AS net_revenue_previous_year,

    CAST(
        100.0 * (
            net_revenue
            - LAG(net_revenue, 12) OVER (
                ORDER BY transaction_month
            )
        )
        / NULLIF(
            LAG(net_revenue, 12) OVER (
                ORDER BY transaction_month
            ),
            0
        )
        AS DECIMAL(10, 2)
    ) AS net_revenue_yoy_percentage

FROM monthly_performance
ORDER BY transaction_month;

/* =========================================================
   5. PERFORMANCE BY CALENDAR MONTH
   ========================================================= */

SELECT
    MONTH(transaction_timestamp) AS month_number,
    DATENAME(MONTH, transaction_timestamp) AS month_name,

    AVG(gross_revenue) AS average_gross_revenue_per_transaction,

    SUM(
        CASE
            WHEN refund_flag = 0 THEN transaction_amount
            ELSE 0
        END
    ) / COUNT(DISTINCT YEAR(transaction_timestamp))
        AS average_monthly_net_revenue,

    COUNT(DISTINCT transaction_id)
        / COUNT(DISTINCT YEAR(transaction_timestamp))
        AS average_monthly_transactions,

    SUM(quantity)
        / COUNT(DISTINCT YEAR(transaction_timestamp))
        AS average_monthly_units_sold,

    AVG(ABS(transaction_amount))
        AS average_transaction_value,

    CAST(
        1.0 * SUM(CASE WHEN refund_flag = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10, 4)
    ) AS refund_rate

FROM dbo.fact_transactions
GROUP BY
    MONTH(transaction_timestamp),
    DATENAME(MONTH, transaction_timestamp)
ORDER BY month_number;