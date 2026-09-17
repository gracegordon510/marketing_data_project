USE marketing_analytics;
GO

/* =========================================================
   EXECUTIVE SALES ANALYSIS
   =========================================================

   METRIC DEFINITIONS

   Gross Sales:
   Total original sales value before discounts and refunds.
   Includes the gross value of transactions later refunded.

   Discount Value:
   Difference between gross sales and the absolute post-discount
   transaction amount. Includes discounts originally applied to
   transactions later refunded.

   Refund Value:
   Absolute post-discount value of rows marked as refunded.

   Net Revenue:
   Post-discount revenue retained from completed, non-refunded
   transactions.

   Reconciliation:
   Net Revenue = Gross Sales - Discount Value - Refund Value

   REFUND ASSUMPTION

   The source is treated as containing transactions changed in
   place when refunded. A refunded row represents the latest state
   of the original transaction; a separate earlier purchase row is
   not expected. For this reason, refunded rows are:

   - Included in Gross Sales and Discount Value
   - Included in Refund Value
   - Excluded from Net Revenue
   - Excluded from Completed Transactions, Units Sold, Purchasing
     Customers, and Average Order Value
   ========================================================= */


/* =========================================================
   1. EXECUTIVE KPI SUMMARY
   ========================================================= */

SELECT
    -- Original sales value before discounts and refunds
    SUM(gross_revenue) AS gross_sales,

    -- Discounts originally applied to all transaction records
    SUM(
        gross_revenue - ABS(transaction_amount)
    ) AS discount_value,

    -- Post-discount value reversed through refunds
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

    -- All retained completed and refunded records
    COUNT(*) AS total_transaction_records,

    -- Completed, non-refunded transactions
    SUM(
        CASE WHEN refund_flag = 0 THEN 1 ELSE 0 END
    ) AS completed_transactions,

    -- Customers with at least one completed transaction
    COUNT(
        DISTINCT CASE
            WHEN refund_flag = 0 THEN customer_id
        END
    ) AS purchasing_customers,

    -- Units retained as completed sales
    SUM(
        CASE
            WHEN refund_flag = 0 THEN quantity
            ELSE 0
        END
    ) AS units_sold,

    -- Net revenue per completed transaction
    CAST(
        SUM(
            CASE
                WHEN refund_flag = 0
                    THEN transaction_amount
                ELSE 0
            END
        )
        / NULLIF(
            SUM(
                CASE WHEN refund_flag = 0 THEN 1.0 ELSE 0 END
            ),
            0
        )
        AS DECIMAL(14, 2)
    ) AS average_order_value,

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

    SUM(gross_revenue) AS gross_sales,

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

    COUNT(*) AS total_transaction_records,

    SUM(
        CASE WHEN refund_flag = 0 THEN 1 ELSE 0 END
    ) AS completed_transactions,

    COUNT(
        DISTINCT CASE
            WHEN refund_flag = 0 THEN customer_id
        END
    ) AS purchasing_customers,

    SUM(
        CASE
            WHEN refund_flag = 0 THEN quantity
            ELSE 0
        END
    ) AS units_sold,

    CAST(
        SUM(
            CASE
                WHEN refund_flag = 0
                    THEN transaction_amount
                ELSE 0
            END
        )
        / NULLIF(
            SUM(
                CASE WHEN refund_flag = 0 THEN 1.0 ELSE 0 END
            ),
            0
        )
        AS DECIMAL(14, 2)
    ) AS average_order_value,

    SUM(
        CASE WHEN refund_flag = 1 THEN 1 ELSE 0 END
    ) AS refunded_transactions,

    CAST(
        1.0 * SUM(CASE WHEN refund_flag = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10, 4)
    ) AS refund_rate

FROM dbo.fact_transactions

GROUP BY
    YEAR(transaction_timestamp)

ORDER BY
    transaction_year;


/* =========================================================
   4. MONTHLY PERFORMANCE AND YEAR-OVER-YEAR CHANGE
   ========================================================= */

WITH monthly_performance AS (
    SELECT
        DATEFROMPARTS(
            YEAR(transaction_timestamp),
            MONTH(transaction_timestamp),
            1
        ) AS transaction_month,

        SUM(gross_revenue) AS gross_sales,

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

        COUNT(*) AS total_transaction_records,

        SUM(
            CASE WHEN refund_flag = 0 THEN 1 ELSE 0 END
        ) AS completed_transactions,

        COUNT(
            DISTINCT CASE
                WHEN refund_flag = 0 THEN customer_id
            END
        ) AS purchasing_customers,

        SUM(
            CASE
                WHEN refund_flag = 0 THEN quantity
                ELSE 0
            END
        ) AS units_sold,

        CAST(
            SUM(
                CASE
                    WHEN refund_flag = 0
                        THEN transaction_amount
                    ELSE 0
                END
            )
            / NULLIF(
                SUM(
                    CASE WHEN refund_flag = 0 THEN 1.0 ELSE 0 END
                ),
                0
            )
            AS DECIMAL(14, 2)
        ) AS average_order_value,

        SUM(
            CASE WHEN refund_flag = 1 THEN 1 ELSE 0 END
        ) AS refunded_transactions,

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
    gross_sales,
    discount_value,
    refund_value,
    net_revenue,
    total_transaction_records,
    completed_transactions,
    purchasing_customers,
    units_sold,
    average_order_value,
    refunded_transactions,
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

ORDER BY
    transaction_month;


/* =========================================================
   5. PERFORMANCE BY CALENDAR MONTH
   ========================================================= */

SELECT
    MONTH(transaction_timestamp) AS month_number,
    DATENAME(MONTH, transaction_timestamp) AS month_name,

    -- Average original gross value across all transaction records
    CAST(
        AVG(gross_revenue)
        AS DECIMAL(14, 2)
    ) AS average_gross_sale_value,

    -- Average net revenue for this calendar month across years
    CAST(
        SUM(
            CASE
                WHEN refund_flag = 0 THEN transaction_amount
                ELSE 0
            END
        )
        / NULLIF(
            COUNT(DISTINCT YEAR(transaction_timestamp)) * 1.0,
            0
        )
        AS DECIMAL(14, 2)
    ) AS average_monthly_net_revenue,

    -- Average completed transactions for this month across years
    CAST(
        SUM(
            CASE WHEN refund_flag = 0 THEN 1.0 ELSE 0 END
        )
        / NULLIF(
            COUNT(DISTINCT YEAR(transaction_timestamp)),
            0
        )
        AS DECIMAL(14, 2)
    ) AS average_monthly_completed_transactions,

    -- Average completed units sold for this month across years
    CAST(
        SUM(
            CASE
                WHEN refund_flag = 0 THEN quantity * 1.0
                ELSE 0
            END
        )
        / NULLIF(
            COUNT(DISTINCT YEAR(transaction_timestamp)),
            0
        )
        AS DECIMAL(14, 2)
    ) AS average_monthly_units_sold,

    -- AOV across all completed transactions for this month
    CAST(
        SUM(
            CASE
                WHEN refund_flag = 0
                    THEN transaction_amount
                ELSE 0
            END
        )
        / NULLIF(
            SUM(
                CASE WHEN refund_flag = 0 THEN 1.0 ELSE 0 END
            ),
            0
        )
        AS DECIMAL(14, 2)
    ) AS average_order_value,

    CAST(
        1.0 * SUM(CASE WHEN refund_flag = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10, 4)
    ) AS refund_rate

FROM dbo.fact_transactions

GROUP BY
    MONTH(transaction_timestamp),
    DATENAME(MONTH, transaction_timestamp)

ORDER BY
    month_number;
