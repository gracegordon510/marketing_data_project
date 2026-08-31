USE marketing_analytics;
GO

/*
=========================================================
EXPERIMENT-GROUP ASSIGNMENT VALIDATION
=========================================================

PURPOSE:
Determine whether experiment_group has a consistent assignment
unit and can support conventional A/B-test analysis.

VALIDATION CHECKS:
- Validate experiment-group values and event allocation.
- Test assignment stability at the customer level.
- Test assignment stability within customer-campaign pairs.
- Measure assignment inconsistency by campaign.
- Inspect examples of customers switching groups.

KEY FINDINGS:
- Control, Variant_A, and Variant_B are the only recorded
  experiment-group values.
- Event allocation is approximately 60% Control, 20%
  Variant_A, and 20% Variant_B.
- 96.25% of customers appear in all three groups.
- 90.42% of customer-campaign pairs contain only one event and
  cannot be tested for assignment stability.
- Among repeated customer-campaign pairs, 57.41% appear in
  multiple experiment groups.
- Session-level assignment cannot be evaluated because
  session_id is unreliable.

ANALYTICAL DECISION:
The dataset does not identify a reliable experimental unit.
experiment_group is retained for descriptive event summaries
only and is not used to calculate conversion uplift, perform
significance testing, estimate causal effects, compare customer
conversion between groups, or treat event rows as independent
experimental participants.

The approximately 60%/20%/20% event allocation may be reported
descriptively but is not evidence of valid randomization.
=========================================================
*/

/* =========================================================
   1. EXPERIMENT-GROUP VALUES AND EVENT ALLOCATION
   ========================================================= */

SELECT
    COALESCE(experiment_group, 'NULL') AS experiment_group,
    COUNT(*) AS event_count,
    COUNT(DISTINCT customer_id) AS unique_customers,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS event_pct,

    CASE
        WHEN experiment_group IN (
            'Control',
            'Variant_A',
            'Variant_B'
        )
        THEN 'Valid'
        ELSE 'Invalid'
    END AS validation_status

FROM dbo.fact_events

GROUP BY experiment_group

ORDER BY event_count DESC;


/* =========================================================
   2. CUSTOMER-LEVEL ASSIGNMENT STABILITY
   =========================================================
   Tests whether each customer remains in one experiment group
   across all recorded events.

   Customers in multiple groups do not meet the requirements
   of a global customer-level assignment.
   ========================================================= */

WITH customer_assignment AS (
    SELECT
        customer_id,
        COUNT(*) AS event_count,
        COUNT(DISTINCT experiment_group) AS experiment_group_count

    FROM dbo.fact_events

    WHERE experiment_group IN (
        'Control',
        'Variant_A',
        'Variant_B'
    )

    GROUP BY customer_id
)
SELECT
    experiment_group_count,
    COUNT(*) AS customer_count,
    SUM(event_count) AS event_count,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_pct

FROM customer_assignment

GROUP BY experiment_group_count

ORDER BY experiment_group_count;


/* =========================================================
   3. CUSTOMER-CAMPAIGN ASSIGNMENT STABILITY
   =========================================================
   Tests whether customers remain in one experiment group
   within each attributed campaign.

   Only pairs with multiple events can reveal assignment
   switching.
   ========================================================= */

WITH customer_campaign_assignment AS (
    SELECT
        customer_id,
        campaign_id,
        COUNT(*) AS event_count,
        COUNT(DISTINCT experiment_group) AS experiment_group_count

    FROM dbo.fact_events

    WHERE campaign_id <> 0
      AND experiment_group IN (
          'Control',
          'Variant_A',
          'Variant_B'
      )

    GROUP BY
        customer_id,
        campaign_id
)
SELECT
    COUNT(*) AS total_customer_campaign_pairs,

    SUM(
        CASE
            WHEN event_count = 1 THEN 1
            ELSE 0
        END
    ) AS single_event_pairs,

    SUM(
        CASE
            WHEN event_count > 1 THEN 1
            ELSE 0
        END
    ) AS testable_repeated_pairs,

    SUM(
        CASE
            WHEN event_count > 1
             AND experiment_group_count = 1
            THEN 1 ELSE 0
        END
    ) AS consistent_repeated_pairs,

    SUM(
        CASE
            WHEN event_count > 1
             AND experiment_group_count > 1
            THEN 1 ELSE 0
        END
    ) AS inconsistent_repeated_pairs,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN event_count = 1 THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS single_event_pair_pct,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN event_count > 1
                 AND experiment_group_count > 1
                THEN 1 ELSE 0
            END
        )
        / NULLIF(
            SUM(
                CASE
                    WHEN event_count > 1 THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS repeated_pair_inconsistency_pct

FROM customer_campaign_assignment;


/* =========================================================
   4. ASSIGNMENT INSTABILITY BY CAMPAIGN
   =========================================================
   Determines whether customer-campaign assignment switching
   is isolated to certain campaigns or widespread.
   ========================================================= */

WITH customer_campaign_assignment AS (
    SELECT
        customer_id,
        campaign_id,
        COUNT(*) AS event_count,
        COUNT(DISTINCT experiment_group) AS experiment_group_count

    FROM dbo.fact_events

    WHERE campaign_id <> 0
      AND experiment_group IN (
          'Control',
          'Variant_A',
          'Variant_B'
      )

    GROUP BY
        customer_id,
        campaign_id
)
SELECT
    campaign_id,
    COUNT(*) AS repeated_customer_pairs,

    SUM(
        CASE
            WHEN experiment_group_count = 1
            THEN 1 ELSE 0
        END
    ) AS consistent_pairs,

    SUM(
        CASE
            WHEN experiment_group_count > 1
            THEN 1 ELSE 0
        END
    ) AS inconsistent_pairs,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN experiment_group_count > 1
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS inconsistent_pair_pct

FROM customer_campaign_assignment

WHERE event_count > 1

GROUP BY campaign_id

ORDER BY
    inconsistent_pair_pct DESC,
    repeated_customer_pairs DESC;


/* =========================================================
   5. EXAMPLES OF ASSIGNMENT SWITCHING
   =========================================================
   Returns sample event records where a customer appears in
   multiple groups within the same campaign.
   ========================================================= */

WITH inconsistent_pairs AS (
    SELECT
        customer_id,
        campaign_id

    FROM dbo.fact_events

    WHERE campaign_id <> 0
      AND experiment_group IN (
          'Control',
          'Variant_A',
          'Variant_B'
      )

    GROUP BY
        customer_id,
        campaign_id

    HAVING COUNT(DISTINCT experiment_group) > 1
)
SELECT TOP (20)
    e.event_id,
    e.event_timestamp,
    e.customer_id,
    e.campaign_id,
    e.experiment_group,
    e.event_type

FROM dbo.fact_events AS e

INNER JOIN inconsistent_pairs AS i
    ON e.customer_id = i.customer_id
   AND e.campaign_id = i.campaign_id

ORDER BY
    e.customer_id,
    e.campaign_id,
    e.event_timestamp;