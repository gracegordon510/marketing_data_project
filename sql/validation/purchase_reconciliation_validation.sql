USE marketing_analytics;
GO

/*
=========================================================
PURCHASE EVENT AND TRANSACTION RECONCILIATION
=========================================================

PURPOSE:
Determine whether purchase events in fact_events correspond
to records in fact_transactions and can be connected to
transaction outcomes and revenue.

VALIDATION CHECKS:
- Compare purchase-event and transaction counts.
- Match records using customer_id, product_id, and the exact
  event or transaction timestamp.
- Check campaign_id agreement among matched records.
- Confirm that the matching key is unique in both tables.
- Confirm whether refunded transactions have corresponding
  purchase events.

KEY FINDINGS:
- fact_events contains 92,678 retained purchase events.
- All 92,678 purchase events have a valid product_id; none
  are missing a product_id.
- fact_transactions contains 92,678 retained records:
  89,974 completed transactions and 2,704 refunded
  transactions.
- All 92,678 purchase events matched exactly one retained
  transaction with the same customer, product, and timestamp.
- All 92,678 matched records have the same campaign_id.
- All 2,704 refunded transactions matched purchase events.
- No duplicate matching keys were found in either table.
- No conflicting campaign IDs were found.
- The valid purchase-event match rate and transaction match
  rate are both 100.00%.

ANALYTICAL DECISION:
Purchase events may be connected to transaction outcomes at
the purchase-record level.

fact_transactions remains the authoritative source for
completed sales, refunds, quantities, discounts, and revenue.

This reconciliation establishes correspondence between
purchase events and transaction records only. It does not
establish an ordered customer journey through earlier views,
clicks, or add-to-cart events. Those events remain suitable
for aggregate event-count analysis only because reliable
session and journey identifiers are unavailable.
=========================================================
*/


/* =========================================================
   1. PURCHASE EVENT AND TRANSACTION COUNTS
   ========================================================= */

SELECT
    COUNT(*) AS purchase_events,

    SUM(
        CASE
            WHEN product_id IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS purchase_events_with_product_id,

    SUM(
        CASE
            WHEN product_id IS NULL
            THEN 1 ELSE 0
        END
    ) AS purchase_events_missing_product_id,

    (
        SELECT COUNT(*)
        FROM dbo.fact_transactions
    ) AS total_transactions,

    (
        SELECT COUNT(*)
        FROM dbo.fact_transactions
        WHERE refund_flag = 0
    ) AS completed_transactions,

    (
        SELECT COUNT(*)
        FROM dbo.fact_transactions
        WHERE refund_flag = 1
    ) AS refunded_transactions

FROM dbo.fact_events

WHERE event_type = 'purchase';


/* =========================================================
   2. EXACT RECORD-LEVEL RECONCILIATION
   =========================================================
   Records are matched using:
   - customer_id
   - product_id
   - exact timestamp

   ROW_NUMBER prevents duplicate matching-key combinations
   from creating artificial many-to-many matches.
   ========================================================= */

WITH ranked_purchase_events AS (
    SELECT
        event_id,
        event_timestamp,
        customer_id,
        product_id,
        campaign_id,

        ROW_NUMBER() OVER (
            PARTITION BY
                customer_id,
                product_id,
                event_timestamp
            ORDER BY event_id
        ) AS match_number

    FROM dbo.fact_events

    WHERE event_type = 'purchase'
      AND product_id IS NOT NULL
),
ranked_transactions AS (
    SELECT
        transaction_id,
        transaction_timestamp,
        customer_id,
        product_id,
        campaign_id,
        refund_flag,

        ROW_NUMBER() OVER (
            PARTITION BY
                customer_id,
                product_id,
                transaction_timestamp
            ORDER BY transaction_id
        ) AS match_number

    FROM dbo.fact_transactions
),
exact_matches AS (
    SELECT
        e.event_id,
        t.transaction_id,
        e.campaign_id AS event_campaign_id,
        t.campaign_id AS transaction_campaign_id,
        t.refund_flag

    FROM ranked_purchase_events AS e

    INNER JOIN ranked_transactions AS t
        ON e.customer_id = t.customer_id
       AND e.product_id = t.product_id
       AND e.event_timestamp = t.transaction_timestamp
       AND e.match_number = t.match_number
)
SELECT
    COUNT(*) AS exact_matches,

    SUM(
        CASE
            WHEN event_campaign_id = transaction_campaign_id
            THEN 1 ELSE 0
        END
    ) AS matching_campaign_ids,

    SUM(
        CASE
            WHEN event_campaign_id <> transaction_campaign_id
            THEN 1 ELSE 0
        END
    ) AS conflicting_campaign_ids,

    SUM(
        CASE
            WHEN refund_flag = 1
            THEN 1 ELSE 0
        END
    ) AS matched_refunded_transactions,

    ROUND(
        100.0 * COUNT(*)
        / NULLIF(
            (
                SELECT COUNT(*)
                FROM dbo.fact_events
                WHERE event_type = 'purchase'
                  AND product_id IS NOT NULL
            ),
            0
        ),
        2
    ) AS valid_purchase_event_match_pct,

    ROUND(
        100.0 * COUNT(*)
        / NULLIF(
            (
                SELECT COUNT(*)
                FROM dbo.fact_transactions
            ),
            0
        ),
        2
    ) AS transaction_match_pct

FROM exact_matches;


/* =========================================================
   3. MATCHING-KEY UNIQUENESS
   =========================================================
   Tests whether customer_id, product_id, and timestamp
   uniquely identify records in both fact tables.
   ========================================================= */

WITH purchase_event_keys AS (
    SELECT
        customer_id,
        product_id,
        event_timestamp,
        COUNT(*) AS record_count

    FROM dbo.fact_events

    WHERE event_type = 'purchase'
      AND product_id IS NOT NULL

    GROUP BY
        customer_id,
        product_id,
        event_timestamp
),
transaction_keys AS (
    SELECT
        customer_id,
        product_id,
        transaction_timestamp,
        COUNT(*) AS record_count

    FROM dbo.fact_transactions

    GROUP BY
        customer_id,
        product_id,
        transaction_timestamp
)
SELECT
    (
        SELECT COUNT(*)
        FROM purchase_event_keys
        WHERE record_count > 1
    ) AS duplicate_purchase_event_keys,

    (
        SELECT COALESCE(SUM(record_count), 0)
        FROM purchase_event_keys
        WHERE record_count > 1
    ) AS purchase_events_in_duplicate_keys,

    (
        SELECT COUNT(*)
        FROM transaction_keys
        WHERE record_count > 1
    ) AS duplicate_transaction_keys,

    (
        SELECT COALESCE(SUM(record_count), 0)
        FROM transaction_keys
        WHERE record_count > 1
    ) AS transactions_in_duplicate_keys;