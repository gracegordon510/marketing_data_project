USE marketing_analytics;
GO

/*
=========================================================
EVENT PRODUCT ID AVAILABILITY VALIDATION
=========================================================

PURPOSE:
Determine whether product_id is sufficiently available and
consistent across event types and page categories to support
product-level event and funnel analysis.

VALIDATION CHECKS:
- Measure overall product_id completeness.
- Calculate missing-product rates by event type.
- Calculate missing-product rates by page category.
- Examine missing-product rates by event type and page
  category together.
- Determine how many purchase and add-to-cart events cannot
  be included in product-level analysis.

IMPORTANT CONTEXT:
product_id is nullable in fact_events because some digital
activity may not relate to a specific product.

Missing product IDs may be reasonable for general HOME-page
or bounce activity. Missing product IDs on purchase,
add-to-cart, or product-detail activity more directly limit
product-level funnel analysis.

Purchase events with missing product IDs cannot be connected
to retained transaction records because the corresponding
source transactions were excluded during ETL.

KEY FINDINGS:
- fact_events contains 1,989,551 retained events.
- 1,799,629 events (90.45%) have a valid product_id.
- 189,922 events (9.55%) have a null product_id.
- All 1,043,573 view events have a valid product_id.
- All 379,008 click events have a valid product_id.
- All 284,370 add-to-cart events have a valid product_id.
- All 92,678 retained purchase events have a valid product_id.
- All 189,922 bounce events have a null product_id.
- Missing product IDs appear across all page categories because
  bounce events occur across all page categories.
- Product ID availability is primarily associated with
  event_type rather than page_category.
- The 10,449 source purchase events with missing product IDs
  were removed during ETL and are not included in the retained
  warehouse events.

ANALYTICAL DECISION:
Views, clicks, add-to-cart events, and retained purchase events
may be used for product- and category-level event analysis
because product ID coverage is complete for these event types.

Bounce events are excluded from product-level analysis because
none have an associated product ID. They may still be summarized
overall or by dimensions that do not require a product.

All 92,678 retained purchase events have valid product IDs and
fully reconcile with the 92,678 retained transaction records.

Product-level event ratios involving purchases describe all
purchase events retained in the warehouse. However, they exclude
the 10,449 unusable source purchase events removed during ETL.

fact_transactions remains the authoritative source for completed
sales, refunds, quantities, discounts, and revenue.
=========================================================
*/


/* =========================================================
   1. OVERALL PRODUCT ID AVAILABILITY
   ========================================================= */

SELECT
    COUNT(*) AS total_events,

    SUM(
        CASE
            WHEN product_id IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS events_with_product_id,

    SUM(
        CASE
            WHEN product_id IS NULL
            THEN 1 ELSE 0
        END
    ) AS events_missing_product_id,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN product_id IS NOT NULL
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS product_id_available_pct,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN product_id IS NULL
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS product_id_missing_pct

FROM dbo.fact_events;


/* =========================================================
   2. PRODUCT ID AVAILABILITY BY EVENT TYPE
   ========================================================= */

SELECT
    event_type,
    COUNT(*) AS total_events,

    SUM(
        CASE
            WHEN product_id IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS events_with_product_id,

    SUM(
        CASE
            WHEN product_id IS NULL
            THEN 1 ELSE 0
        END
    ) AS events_missing_product_id,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN product_id IS NULL
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS product_id_missing_pct

FROM dbo.fact_events

GROUP BY event_type

ORDER BY total_events DESC;


/* =========================================================
   3. PRODUCT ID AVAILABILITY BY PAGE CATEGORY
   ========================================================= */

SELECT
    page_category,
    COUNT(*) AS total_events,

    SUM(
        CASE
            WHEN product_id IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS events_with_product_id,

    SUM(
        CASE
            WHEN product_id IS NULL
            THEN 1 ELSE 0
        END
    ) AS events_missing_product_id,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN product_id IS NULL
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS product_id_missing_pct

FROM dbo.fact_events

GROUP BY page_category

ORDER BY total_events DESC;


/* =========================================================
   4. PRODUCT ID AVAILABILITY BY EVENT TYPE AND PAGE
   =========================================================
   Determines whether missing product IDs are concentrated
   in particular event and page combinations.
   ========================================================= */

SELECT
    event_type,
    page_category,
    COUNT(*) AS total_events,

    SUM(
        CASE
            WHEN product_id IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS events_with_product_id,

    SUM(
        CASE
            WHEN product_id IS NULL
            THEN 1 ELSE 0
        END
    ) AS events_missing_product_id,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN product_id IS NULL
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS product_id_missing_pct

FROM dbo.fact_events

GROUP BY
    event_type,
    page_category

ORDER BY
    event_type,
    page_category;