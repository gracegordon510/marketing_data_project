/* =============================================================================
   EXPERIMENT-GROUP DATA VALIDATION
   =============================================================================

   Purpose:
   --------
   This script evaluates whether dbo.fact_events.experiment_group can support
   a valid campaign-level A/B test.

   Expected experiment groups:
       - Control
       - Variant_A
       - Variant_B

   Assumed assignment unit:
   ------------------------
   The analysis assumes that a customer should remain in the same experiment
   group for every event associated with the same campaign.

   A customer may validly belong to different groups for different campaigns.
   However, switching groups within the same campaign suggests unstable or
   event-level assignment.

   Validation questions:
   ---------------------
   1. Are experiment-group values complete and valid?
   2. Is the overall allocation reasonably balanced?
   3. Do customers remain in one group within each campaign?
   4. How many customer-campaign pairs have enough events to test stability?
   5. How common is switching among repeated customer-campaign pairs?
   6. Is assignment instability concentrated in particular campaigns?
   7. Are all three experiment groups represented within each campaign?
   8. Do the experiment groups overlap in time?
   9. Does assignment remain stable during valid campaign dates?
   10. Are device and traffic-source distributions comparable across groups?

   Important limitations:
   ----------------------
   - campaign_id = 0 represents unattributed activity and is excluded from
     campaign-level validation.
   - Customer-campaign pairs containing only one event cannot demonstrate
     whether assignment was stable.
   - Campaign dates are known to have significant data-quality issues.
   - session_id is not used because sessions are not reliably associated with
     individual customers.
   - Even stable assignment would not prove randomization without documentation
     describing the experiment design and assignment process.

   Interpretation:
   ---------------
   A conventional A/B test requires stable group assignment. If a substantial
   percentage of repeated customer-campaign pairs appear in multiple groups,
   experiment_group should not be used for conversion uplift, statistical
   significance, or causal conclusions.

   Database:
       marketing_analytics

   Tables:
       dbo.fact_events
       dbo.dim_campaigns
   ============================================================================= */


/* =============================================================================
   1. VALIDATE EXPERIMENT-GROUP VALUES
   =============================================================================
   Identifies NULL values, unexpected labels, spelling differences, and the
   number of events and customers associated with each recorded value.
   ============================================================================= */

SELECT
    COALESCE(experiment_group, 'NULL') AS experiment_group,
    COUNT(*) AS event_count,
    COUNT(DISTINCT customer_id) AS unique_customer_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS event_pct
FROM dbo.fact_events
GROUP BY experiment_group
ORDER BY event_count DESC;


/* Return only invalid or missing experiment-group values. */

SELECT
    experiment_group,
    COUNT(*) AS invalid_event_count
FROM dbo.fact_events
WHERE experiment_group IS NULL
   OR experiment_group NOT IN (
       'Control',
       'Variant_A',
       'Variant_B'
   )
GROUP BY experiment_group
ORDER BY invalid_event_count DESC;


/* =============================================================================
   2. CHECK OVERALL EXPERIMENT-GROUP ALLOCATION
   =============================================================================
   Shows the distribution of events across the three expected groups.

   A balanced or intentionally weighted distribution is encouraging, but it
   does not prove that customers were assigned consistently or randomly.
   ============================================================================= */

SELECT
    experiment_group,
    COUNT(*) AS event_count,
    COUNT(DISTINCT customer_id) AS unique_customer_count,
    COUNT(DISTINCT CASE
        WHEN campaign_id <> 0 THEN campaign_id
    END) AS campaign_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS event_pct
FROM dbo.fact_events
WHERE experiment_group IN (
    'Control',
    'Variant_A',
    'Variant_B'
)
GROUP BY experiment_group
ORDER BY event_count DESC;


/* =============================================================================
   3. CHECK ASSIGNMENT ACROSS ALL EVENTS FOR EACH CUSTOMER
   =============================================================================
   This is a descriptive check only.

   Customers may legitimately appear in different groups across different
   campaigns, so this result should not be used by itself to determine whether
   experiment assignment is valid.
   ============================================================================= */

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
    COUNT(*) AS unique_customer_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_pct,
    SUM(event_count) AS event_count
FROM customer_assignment
GROUP BY experiment_group_count
ORDER BY experiment_group_count;


/* =============================================================================
   4. TEST ASSIGNMENT WITHIN EACH CUSTOMER-CAMPAIGN PAIR
   =============================================================================
   This is the main assignment-integrity check.

   A customer-campaign pair should normally contain only one distinct
   experiment group. Multiple groups indicate assignment switching within the
   same campaign.

   Single-event pairs are included here but cannot truly demonstrate stability.
   ============================================================================= */

WITH customer_campaign_assignment AS (
    SELECT
        customer_id,
        campaign_id,
        COUNT(*) AS event_count,
        COUNT(DISTINCT experiment_group) AS experiment_group_count
    FROM dbo.fact_events
    WHERE experiment_group IN (
        'Control',
        'Variant_A',
        'Variant_B'
    )
      AND campaign_id <> 0
    GROUP BY
        customer_id,
        campaign_id
)
SELECT
    experiment_group_count,
    COUNT(*) AS customer_campaign_pairs,
    COUNT(DISTINCT customer_id) AS customers_represented,
    SUM(event_count) AS event_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS pair_pct
FROM customer_campaign_assignment
GROUP BY experiment_group_count
ORDER BY experiment_group_count;


/* =============================================================================
   5. DETERMINE HOW MANY PAIRS CAN BE TESTED FOR STABILITY
   =============================================================================
   Customer-campaign pairs with one event have no opportunity to reveal
   switching. Pairs with multiple events provide a meaningful stability test.
   ============================================================================= */

WITH customer_campaign_assignment AS (
    SELECT
        customer_id,
        campaign_id,
        COUNT(*) AS event_count
    FROM dbo.fact_events
    WHERE experiment_group IN (
        'Control',
        'Variant_A',
        'Variant_B'
    )
      AND campaign_id <> 0
    GROUP BY
        customer_id,
        campaign_id
),
pair_classification AS (
    SELECT
        CASE
            WHEN event_count = 1 THEN 'One event - not testable'
            ELSE 'Multiple events - testable'
        END AS pair_type,
        event_count
    FROM customer_campaign_assignment
)
SELECT
    pair_type,
    COUNT(*) AS customer_campaign_pairs,
    SUM(event_count) AS event_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS pair_pct
FROM pair_classification
GROUP BY pair_type
ORDER BY pair_type;


/* =============================================================================
   6. TEST STABILITY AMONG REPEATED CUSTOMER-CAMPAIGN PAIRS
   =============================================================================
   This is the most important validation query.

   Only pairs with multiple events are included. A pair is inconsistent when
   the same customer appears in more than one experiment group for the same
   campaign.
   ============================================================================= */

WITH customer_campaign_assignment AS (
    SELECT
        customer_id,
        campaign_id,
        COUNT(*) AS event_count,
        COUNT(DISTINCT experiment_group) AS experiment_group_count
    FROM dbo.fact_events
    WHERE experiment_group IN (
        'Control',
        'Variant_A',
        'Variant_B'
    )
      AND campaign_id <> 0
    GROUP BY
        customer_id,
        campaign_id
)
SELECT
    experiment_group_count,
    COUNT(*) AS repeated_customer_campaign_pairs,
    SUM(event_count) AS event_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS repeated_pair_pct
FROM customer_campaign_assignment
WHERE event_count > 1
GROUP BY experiment_group_count
ORDER BY experiment_group_count;


/* Summarize the overall inconsistency rate among testable pairs. */

WITH customer_campaign_assignment AS (
    SELECT
        customer_id,
        campaign_id,
        COUNT(*) AS event_count,
        COUNT(DISTINCT experiment_group) AS experiment_group_count
    FROM dbo.fact_events
    WHERE experiment_group IN (
        'Control',
        'Variant_A',
        'Variant_B'
    )
      AND campaign_id <> 0
    GROUP BY
        customer_id,
        campaign_id
),
repeated_pairs AS (
    SELECT
        customer_id,
        campaign_id,
        event_count,
        experiment_group_count
    FROM customer_campaign_assignment
    WHERE event_count > 1
)
SELECT
    COUNT(*) AS testable_customer_campaign_pairs,

    SUM(
        CASE
            WHEN experiment_group_count = 1 THEN 1
            ELSE 0
        END
    ) AS consistent_pairs,

    SUM(
        CASE
            WHEN experiment_group_count > 1 THEN 1
            ELSE 0
        END
    ) AS inconsistent_pairs,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN experiment_group_count > 1 THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS inconsistent_pair_pct
FROM repeated_pairs;


/* =============================================================================
   7. MEASURE ASSIGNMENT INSTABILITY BY CAMPAIGN
   =============================================================================
   Determines whether switching is limited to certain campaigns or widespread.

   Only customer-campaign pairs with multiple events are included.
   ============================================================================= */

WITH customer_campaign_assignment AS (
    SELECT
        customer_id,
        campaign_id,
        COUNT(*) AS event_count,
        COUNT(DISTINCT experiment_group) AS experiment_group_count
    FROM dbo.fact_events
    WHERE experiment_group IN (
        'Control',
        'Variant_A',
        'Variant_B'
    )
      AND campaign_id <> 0
    GROUP BY
        customer_id,
        campaign_id
)
SELECT
    campaign_id,
    COUNT(*) AS repeated_customer_pairs,

    SUM(
        CASE
            WHEN experiment_group_count = 1 THEN 1
            ELSE 0
        END
    ) AS consistent_pairs,

    SUM(
        CASE
            WHEN experiment_group_count > 1 THEN 1
            ELSE 0
        END
    ) AS inconsistent_pairs,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN experiment_group_count > 1 THEN 1
                ELSE 0
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


/* =============================================================================
   8. VIEW EXAMPLES OF INCONSISTENT ASSIGNMENTS
   =============================================================================
   Returns sample customer-campaign pairs that appear in multiple experiment
   groups. This allows the underlying event records to be inspected.
   ============================================================================= */

WITH inconsistent_pairs AS (
    SELECT
        customer_id,
        campaign_id
    FROM dbo.fact_events
    WHERE experiment_group IN (
        'Control',
        'Variant_A',
        'Variant_B'
    )
      AND campaign_id <> 0
    GROUP BY
        customer_id,
        campaign_id
    HAVING COUNT(DISTINCT experiment_group) > 1
)
SELECT TOP (100)
    e.event_id,
    e.event_timestamp,
    e.customer_id,
    e.campaign_id,
    e.experiment_group,
    e.event_type,
    e.device_type,
    e.traffic_source,
    e.page_type
FROM dbo.fact_events AS e
INNER JOIN inconsistent_pairs AS i
    ON e.customer_id = i.customer_id
   AND e.campaign_id = i.campaign_id
ORDER BY
    e.customer_id,
    e.campaign_id,
    e.event_timestamp;


/* =============================================================================
   9. CHECK GROUP REPRESENTATION AND BALANCE WITHIN EACH CAMPAIGN
   =============================================================================
   Shows the event and customer distribution for each experiment group within
   each campaign.

   Look for:
       - Missing experiment groups
       - Extremely uneven allocations
       - Very small groups
       - Large differences between event and customer distributions
   ============================================================================= */

SELECT
    campaign_id,
    experiment_group,
    COUNT(*) AS event_count,
    COUNT(DISTINCT customer_id) AS unique_customer_count,
    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (PARTITION BY campaign_id),
        2
    ) AS campaign_event_pct
FROM dbo.fact_events
WHERE experiment_group IN (
    'Control',
    'Variant_A',
    'Variant_B'
)
  AND campaign_id <> 0
GROUP BY
    campaign_id,
    experiment_group
ORDER BY
    campaign_id,
    experiment_group;


/* Identify campaigns that do not contain all three expected groups. */

SELECT
    campaign_id,
    COUNT(DISTINCT experiment_group) AS experiment_groups_present,
    COUNT(*) AS event_count,
    COUNT(DISTINCT customer_id) AS unique_customer_count
FROM dbo.fact_events
WHERE experiment_group IN (
    'Control',
    'Variant_A',
    'Variant_B'
)
  AND campaign_id <> 0
GROUP BY campaign_id
HAVING COUNT(DISTINCT experiment_group) < 3
ORDER BY campaign_id;


/* =============================================================================
   10. CHECK WHETHER GROUPS OVERLAP IN TIME
   =============================================================================
   Control and variant groups should operate during comparable periods.
   Non-overlapping time periods could introduce seasonal or time-based bias.
   ============================================================================= */

SELECT
    campaign_id,
    experiment_group,
    MIN(event_timestamp) AS first_event_timestamp,
    MAX(event_timestamp) AS last_event_timestamp,
    COUNT(*) AS event_count,
    COUNT(DISTINCT customer_id) AS unique_customer_count
FROM dbo.fact_events
WHERE experiment_group IN (
    'Control',
    'Variant_A',
    'Variant_B'
)
  AND campaign_id <> 0
GROUP BY
    campaign_id,
    experiment_group
ORDER BY
    campaign_id,
    experiment_group;


/* =============================================================================
   11. CHECK CAMPAIGN-DATE VALIDITY BY EXPERIMENT GROUP
   =============================================================================
   Determines how many experiment-labelled events occur before, during, or
   after the associated campaign's recorded dates.
   ============================================================================= */

WITH event_date_status AS (
    SELECT
        e.campaign_id,
        e.experiment_group,
        CASE
            WHEN e.event_timestamp < c.start_date
                THEN 'Before campaign'
            WHEN e.event_timestamp >= DATEADD(DAY, 1, c.end_date)
                THEN 'After campaign'
            ELSE 'Within campaign'
        END AS date_status
    FROM dbo.fact_events AS e
    INNER JOIN dbo.dim_campaigns AS c
        ON e.campaign_id = c.campaign_id
    WHERE e.experiment_group IN (
        'Control',
        'Variant_A',
        'Variant_B'
    )
      AND e.campaign_id <> 0
)
SELECT
    campaign_id,
    experiment_group,
    date_status,
    COUNT(*) AS event_count,
    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (
            PARTITION BY campaign_id, experiment_group
        ),
        2
    ) AS group_event_pct
FROM event_date_status
GROUP BY
    campaign_id,
    experiment_group,
    date_status
ORDER BY
    campaign_id,
    experiment_group,
    date_status;


/* =============================================================================
   12. REPEAT THE STABILITY TEST USING ONLY VALID CAMPAIGN-DATE EVENTS
   =============================================================================
   Tests assignment stability using only events that occurred between the
   recorded campaign start and end dates.

   The remaining population may be small or selective because most
   campaign-linked events are known to fall outside the campaign dates.
   ============================================================================= */

WITH valid_campaign_events AS (
    SELECT
        e.customer_id,
        e.campaign_id,
        e.experiment_group
    FROM dbo.fact_events AS e
    INNER JOIN dbo.dim_campaigns AS c
        ON e.campaign_id = c.campaign_id
    WHERE e.experiment_group IN (
        'Control',
        'Variant_A',
        'Variant_B'
    )
      AND e.campaign_id <> 0
      AND e.event_timestamp >= c.start_date
      AND e.event_timestamp < DATEADD(DAY, 1, c.end_date)
),
customer_campaign_assignment AS (
    SELECT
        customer_id,
        campaign_id,
        COUNT(*) AS event_count,
        COUNT(DISTINCT experiment_group) AS experiment_group_count
    FROM valid_campaign_events
    GROUP BY
        customer_id,
        campaign_id
)
SELECT
    experiment_group_count,
    COUNT(*) AS repeated_customer_campaign_pairs,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS repeated_pair_pct
FROM customer_campaign_assignment
WHERE event_count > 1
GROUP BY experiment_group_count
ORDER BY experiment_group_count;


/* =============================================================================
   13. CHECK DEVICE-TYPE COMPARABILITY
   =============================================================================
   Large differences in device distribution could indicate non-random
   assignment or another systematic difference between groups.
   ============================================================================= */

SELECT
    experiment_group,
    COALESCE(device_type, 'Unknown') AS device_type,
    COUNT(*) AS event_count,
    COUNT(DISTINCT customer_id) AS unique_customer_count,
    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (PARTITION BY experiment_group),
        2
    ) AS group_event_pct
FROM dbo.fact_events
WHERE experiment_group IN (
    'Control',
    'Variant_A',
    'Variant_B'
)
  AND campaign_id <> 0
GROUP BY
    experiment_group,
    device_type
ORDER BY
    experiment_group,
    event_count DESC;


/* =============================================================================
   14. CHECK TRAFFIC-SOURCE COMPARABILITY
   =============================================================================
   Large differences in traffic-source distribution could influence event
   outcomes independently of the experiment variant.
   ============================================================================= */

SELECT
    experiment_group,
    COALESCE(traffic_source, 'Unknown') AS traffic_source,
    COUNT(*) AS event_count,
    COUNT(DISTINCT customer_id) AS unique_customer_count,
    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (PARTITION BY experiment_group),
        2
    ) AS group_event_pct
FROM dbo.fact_events
WHERE experiment_group IN (
    'Control',
    'Variant_A',
    'Variant_B'
)
  AND campaign_id <> 0
GROUP BY
    experiment_group,
    traffic_source
ORDER BY
    experiment_group,
    event_count DESC;


/* =============================================================================
   15. FINAL DATA-QUALITY SUMMARY
   =============================================================================
   Produces one summary row containing the main experiment-assignment metrics.
   ============================================================================= */

WITH customer_campaign_assignment AS (
    SELECT
        customer_id,
        campaign_id,
        COUNT(*) AS event_count,
        COUNT(DISTINCT experiment_group) AS experiment_group_count
    FROM dbo.fact_events
    WHERE experiment_group IN (
        'Control',
        'Variant_A',
        'Variant_B'
    )
      AND campaign_id <> 0
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
                THEN 1
            ELSE 0
        END
    ) AS consistent_repeated_pairs,

    SUM(
        CASE
            WHEN event_count > 1
             AND experiment_group_count > 1
                THEN 1
            ELSE 0
        END
    ) AS inconsistent_repeated_pairs,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN event_count > 1
                 AND experiment_group_count > 1
                    THEN 1
                ELSE 0
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


/* =============================================================================
   EXPECTED CONCLUSION BASED ON CURRENT RESULTS
   =============================================================================

   Current findings indicate:

   - Experiment events follow an approximately 60% Control, 20% Variant_A,
     and 20% Variant_B distribution.
   - Approximately 90.35% of customer-campaign pairs contain only one event,
     so their assignment stability cannot be tested.
   - Among repeated customer-campaign pairs, approximately 57.45% appear in
     more than one experiment group.
   - The inconsistency is widespread across campaigns.

   Therefore, experiment_group appears to have been assigned to individual
   event records rather than maintained as a stable customer-campaign
   assignment.

   Recommended analytical treatment:
   -----------------------------------
   - Do not calculate customer conversion uplift by experiment group.
   - Do not perform conventional A/B-test significance testing.
   - Do not interpret differences as causal variant effects.
   - Do not treat event rows as independent experimental participants.
   - The approximate 60/20/20 event distribution may be reported descriptively.
   - Present assignment instability as a data-quality limitation.
   ============================================================================= */