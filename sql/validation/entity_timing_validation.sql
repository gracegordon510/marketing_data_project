USE marketing_analytics;
GO

/*
=========================================================
CUSTOMER AND PRODUCT TIMING VALIDATION
=========================================================

PURPOSE:
Determine whether events and transactions occur on or after
the associated customer's signup date and the associated
product's launch date.

VALIDATION CHECKS:
- Identify events recorded before customer signup.
- Identify transactions recorded before customer signup.
- Identify product-linked events recorded before product
  launch.
- Identify transactions recorded before product launch.
- Examine timing inconsistencies by event type.
- Inspect examples of inconsistent records.

DATE TREATMENT:
signup_date and launch_date are stored as dates without a
time component. Activity occurring on the same calendar date
is treated as valid.

Activity is considered inconsistent only when:

- event date < customer signup date
- transaction date < customer signup date
- event date < product launch date
- transaction date < product launch date

KEY FINDINGS:
- 993,429 of 1,989,551 events (49.93%) occurred before
  the associated customer's signup date.
- Pre-signup events affected 94,889 customers.
- 45,492 of 92,678 transactions (49.09%) occurred before
  the associated customer's signup date.
- Pre-signup transactions affected 34,158 customers.
- 890,383 of 1,799,629 product-linked events (49.48%)
  occurred before the associated product's launch date.
- Pre-launch events affected 1,996 of 2,000 products.
- 45,122 of 92,678 transactions (48.69%) occurred before
  the associated product's launch date.
- Pre-launch transactions affected 1,946 products.
- Pre-signup rates were approximately 50% across every
  event type.
- Pre-launch rates were approximately 49% across all event
  types containing product IDs.
- Bounce events were excluded from product-launch validation
  because they do not contain product IDs.
- The timing inconsistencies are widespread rather than
  isolated to particular customers, products, or event types.

ANALYTICAL DECISION:
Customer signup dates and product launch dates are not used to
establish whether event or transaction activity is temporally
valid.

The dataset is not used for:

- Customer-tenure calculations
- Pre/post-signup comparisons
- Signup-cohort performance analysis
- Product-age calculations
- Pre/post-launch comparisons
- Product-launch cohort analysis
- Performance-since-launch metrics

Event and transaction timestamps may still be used to describe
when recorded activity occurred. Customer signup dates and
product launch dates may be summarized separately as dimension
attributes, but they are not used to filter, sequence, or
interpret fact-table activity.

The records are retained because removing approximately half of
the fact-table activity would materially distort the dataset.
The consistent invalid rates near 50% suggest that the dimension
dates and activity timestamps were generated independently in
the synthetic source.
=========================================================
*/


/* =========================================================
   1. EVENT TIMING RELATIVE TO CUSTOMER SIGNUP
   ========================================================= */

SELECT
    COUNT(*) AS total_events,

    SUM(
        CASE
            WHEN CAST(e.event_timestamp AS DATE) < c.signup_date
            THEN 1 ELSE 0
        END
    ) AS events_before_signup,

    SUM(
        CASE
            WHEN CAST(e.event_timestamp AS DATE) >= c.signup_date
            THEN 1 ELSE 0
        END
    ) AS events_on_or_after_signup,

    COUNT(
        DISTINCT CASE
            WHEN CAST(e.event_timestamp AS DATE) < c.signup_date
            THEN e.customer_id
        END
    ) AS customers_with_pre_signup_events,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN CAST(e.event_timestamp AS DATE) < c.signup_date
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS events_before_signup_pct

FROM dbo.fact_events AS e

INNER JOIN dbo.dim_customers AS c
    ON e.customer_id = c.customer_id;


/* =========================================================
   2. TRANSACTION TIMING RELATIVE TO CUSTOMER SIGNUP
   ========================================================= */

SELECT
    COUNT(*) AS total_transactions,

    SUM(
        CASE
            WHEN CAST(t.transaction_timestamp AS DATE) < c.signup_date
            THEN 1 ELSE 0
        END
    ) AS transactions_before_signup,

    SUM(
        CASE
            WHEN CAST(t.transaction_timestamp AS DATE) >= c.signup_date
            THEN 1 ELSE 0
        END
    ) AS transactions_on_or_after_signup,

    COUNT(
        DISTINCT CASE
            WHEN CAST(t.transaction_timestamp AS DATE) < c.signup_date
            THEN t.customer_id
        END
    ) AS customers_with_pre_signup_transactions,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN CAST(t.transaction_timestamp AS DATE) < c.signup_date
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS transactions_before_signup_pct

FROM dbo.fact_transactions AS t

INNER JOIN dbo.dim_customers AS c
    ON t.customer_id = c.customer_id;


/* =========================================================
   3. EVENT TIMING RELATIVE TO PRODUCT LAUNCH
   =========================================================
   Events with null product_id are excluded because they
   cannot be evaluated against a product launch date.
   ========================================================= */

SELECT
    COUNT(*) AS product_linked_events,

    SUM(
        CASE
            WHEN CAST(e.event_timestamp AS DATE) < p.launch_date
            THEN 1 ELSE 0
        END
    ) AS events_before_product_launch,

    SUM(
        CASE
            WHEN CAST(e.event_timestamp AS DATE) >= p.launch_date
            THEN 1 ELSE 0
        END
    ) AS events_on_or_after_product_launch,

    COUNT(
        DISTINCT CASE
            WHEN CAST(e.event_timestamp AS DATE) < p.launch_date
            THEN e.product_id
        END
    ) AS products_with_pre_launch_events,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN CAST(e.event_timestamp AS DATE) < p.launch_date
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS events_before_product_launch_pct

FROM dbo.fact_events AS e

INNER JOIN dbo.dim_products AS p
    ON e.product_id = p.product_id;


/* =========================================================
   4. TRANSACTION TIMING RELATIVE TO PRODUCT LAUNCH
   ========================================================= */

SELECT
    COUNT(*) AS total_transactions,

    SUM(
        CASE
            WHEN CAST(t.transaction_timestamp AS DATE) < p.launch_date
            THEN 1 ELSE 0
        END
    ) AS transactions_before_product_launch,

    SUM(
        CASE
            WHEN CAST(t.transaction_timestamp AS DATE) >= p.launch_date
            THEN 1 ELSE 0
        END
    ) AS transactions_on_or_after_product_launch,

    COUNT(
        DISTINCT CASE
            WHEN CAST(t.transaction_timestamp AS DATE) < p.launch_date
            THEN t.product_id
        END
    ) AS products_with_pre_launch_transactions,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN CAST(t.transaction_timestamp AS DATE) < p.launch_date
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS transactions_before_product_launch_pct

FROM dbo.fact_transactions AS t

INNER JOIN dbo.dim_products AS p
    ON t.product_id = p.product_id;


/* =========================================================
   5. TIMING CONSISTENCY BY EVENT TYPE
   =========================================================
   Helps determine whether inconsistencies are concentrated
   in certain types of activity.
   ========================================================= */

SELECT
    e.event_type,
    COUNT(*) AS total_events,

    SUM(
        CASE
            WHEN CAST(e.event_timestamp AS DATE) < c.signup_date
            THEN 1 ELSE 0
        END
    ) AS events_before_signup,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN CAST(e.event_timestamp AS DATE) < c.signup_date
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS events_before_signup_pct,

    SUM(
        CASE
            WHEN e.product_id IS NOT NULL
             AND CAST(e.event_timestamp AS DATE) < p.launch_date
            THEN 1 ELSE 0
        END
    ) AS events_before_product_launch,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN e.product_id IS NOT NULL
                 AND CAST(e.event_timestamp AS DATE) < p.launch_date
                THEN 1 ELSE 0
            END
        )
        / NULLIF(
            SUM(
                CASE
                    WHEN e.product_id IS NOT NULL
                    THEN 1 ELSE 0
                END
            ),
            0
        ),
        2
    ) AS product_linked_events_before_launch_pct

FROM dbo.fact_events AS e

INNER JOIN dbo.dim_customers AS c
    ON e.customer_id = c.customer_id

LEFT JOIN dbo.dim_products AS p
    ON e.product_id = p.product_id

GROUP BY e.event_type

ORDER BY total_events DESC;


/* =========================================================
   6. EXAMPLES OF CUSTOMER TIMING INCONSISTENCIES
   ========================================================= */

SELECT TOP (20)
    e.event_id AS record_id,
    'Event' AS record_type,
    e.event_type,
    e.customer_id,
    c.signup_date,
    e.event_timestamp AS activity_timestamp,
    DATEDIFF(
        DAY,
        c.signup_date,
        CAST(e.event_timestamp AS DATE)
    ) AS days_from_signup

FROM dbo.fact_events AS e

INNER JOIN dbo.dim_customers AS c
    ON e.customer_id = c.customer_id

WHERE CAST(e.event_timestamp AS DATE) < c.signup_date

UNION ALL

SELECT TOP (20)
    t.transaction_id AS record_id,
    'Transaction' AS record_type,
    NULL AS event_type,
    t.customer_id,
    c.signup_date,
    t.transaction_timestamp AS activity_timestamp,
    DATEDIFF(
        DAY,
        c.signup_date,
        CAST(t.transaction_timestamp AS DATE)
    ) AS days_from_signup

FROM dbo.fact_transactions AS t

INNER JOIN dbo.dim_customers AS c
    ON t.customer_id = c.customer_id

WHERE CAST(t.transaction_timestamp AS DATE) < c.signup_date

ORDER BY
    days_from_signup,
    record_type,
    record_id;


/* =========================================================
   7. EXAMPLES OF PRODUCT TIMING INCONSISTENCIES
   ========================================================= */

SELECT TOP (20)
    e.event_id AS record_id,
    'Event' AS record_type,
    e.event_type,
    e.product_id,
    p.launch_date,
    e.event_timestamp AS activity_timestamp,
    DATEDIFF(
        DAY,
        p.launch_date,
        CAST(e.event_timestamp AS DATE)
    ) AS days_from_launch

FROM dbo.fact_events AS e

INNER JOIN dbo.dim_products AS p
    ON e.product_id = p.product_id

WHERE CAST(e.event_timestamp AS DATE) < p.launch_date

UNION ALL

SELECT TOP (20)
    t.transaction_id AS record_id,
    'Transaction' AS record_type,
    NULL AS event_type,
    t.product_id,
    p.launch_date,
    t.transaction_timestamp AS activity_timestamp,
    DATEDIFF(
        DAY,
        p.launch_date,
        CAST(t.transaction_timestamp AS DATE)
    ) AS days_from_launch

FROM dbo.fact_transactions AS t

INNER JOIN dbo.dim_products AS p
    ON t.product_id = p.product_id

WHERE CAST(t.transaction_timestamp AS DATE) < p.launch_date

ORDER BY
    days_from_launch,
    record_type,
    record_id;