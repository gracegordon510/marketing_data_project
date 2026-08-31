# Data Validation Report

This report documents the SQL validations performed on the final marketing analytics warehouse. It summarizes the identified data-quality limitations and the analytical decisions applied to prevent unsupported interpretations.

## 1. Campaign Timing Validation

### Validation objective

Determine whether events and transactions attributed to campaigns occurred during the associated campaigns' active date ranges.

### Method

Campaign-linked activity was defined as activity with a `campaign_id` other than `0`. An event or transaction was considered within the campaign period when its timestamp was on or after the campaign `start_date` and no later than the `end_date`.

Campaign date quality was also checked to confirm that campaign dates were present and that each `end_date` was on or after its corresponding `start_date`.

### Results

All 50 campaigns had complete and valid date ranges.

| Activity type | Campaign-linked rows | Within campaign | Outside campaign | Within campaign % |
| --- | ---: | ---: | ---: | ---: |
| Events | 991,466 | 47,044 | 944,422 | 4.74% |
| Transactions | 73,889 | 3,647 | 70,242 | 4.94% |

### Finding

Approximately 95% of campaign-linked events and transactions occurred outside the active date range of the campaign to which they were attributed. Because the campaign date fields themselves were complete and valid, the issue is an inconsistency between campaign attribution and activity timestamps rather than missing or invalid campaign dates.

### Analytical decision

The `campaign_id` field is retained as source-provided campaign attribution. However, campaign dates are not used to filter activity to campaign periods, evaluate campaign-period performance, or establish causal or incremental campaign uplift.

### SQL validation

See [`campaign_timing_validation.sql`](../sql/data_validation/campaign_timing_validation.sql).

## 2. Session ID Reliability Validation

### Validation objective

Determine whether `session_id` can reliably identify individual browsing sessions.

### Results

| Validation measure | Result | Percentage |
| --- | ---: | ---: |
| Total events | 1,989,551 | — |
| Distinct session IDs | 632,903 | — |
| Missing session IDs | 0 | 0.00% |
| Single-event session IDs | 100,570 | 15.89% |
| Session IDs linked to multiple customers | 532,330 | 84.11% |
| Session IDs longer than 30 minutes | 532,326 | 84.11% |
| Session IDs spanning multiple days | 532,202 | 84.09% |
| Maximum customers associated with one session ID | 14 | — |
| Maximum apparent session length | 1,094 days | — |

Because session IDs were frequently shared across customers, the combination of `customer_id` and `session_id` was also tested.

This produced 1,989,512 distinct customer-session combinations from 1,989,551 events. Of these combinations:

- 1,989,473 contained only one event.
- 39 contained multiple events.
- All 39 multi-event combinations lasted longer than 30 minutes and spanned multiple days.
- The maximum customer-session duration was 1,032 days.

Therefore, approximately 99.998% of customer-session combinations contained only one event, while the few multi-event combinations had implausibly long durations.

### Finding and analytical decision

Neither `session_id` alone nor the combination of `customer_id` and `session_id` reliably represents an individual browsing session. Most session IDs are shared across multiple customers and span implausibly long periods. Combining the fields does not resolve the issue because nearly every resulting customer-session combination contains only one event.

Session IDs are therefore excluded from session-level analysis, including:

- Session duration
- Events per session
- Session-level conversion and bounce rates
- Session-based customer journeys

Customer-level analysis may still use `customer_id`, and funnel activity may be summarized using aggregate event counts. These event-count ratios must not be interpreted as session-based conversion rates or ordered customer journeys.

### SQL validation

See [`session_id_validation.sql`](../sql/data_validation/session_id_validation.sql).

## 3. Traffic Source and Campaign Channel Validation

### Validation objective

Determine whether an event's `traffic_source` is consistent with the channel of its attributed campaign.

### Results

Campaign attribution was limited to Email, Paid Search, and Social traffic. Organic and Direct events were not attributed to campaigns.

| Traffic source | Total events | Campaign-linked events | Unattributed events | Campaign-linked % |
| --- | ---: | ---: | ---: | ---: |
| Organic | 798,768 | 0 | 798,768 | 0.00% |
| Paid Search | 396,423 | 396,423 | 0 | 100.00% |
| Social | 298,026 | 298,026 | 0 | 100.00% |
| Email | 297,017 | 297,017 | 0 | 100.00% |
| Direct | 199,317 | 0 | 199,317 | 0.00% |

Among campaign-linked events, traffic source matched the attributed campaign channel at the following rates:

| Traffic source | Campaign-linked events | Matching-channel events | Matching-channel % |
| --- | ---: | ---: | ---: |
| Email | 297,017 | 65,850 | 22.17% |
| Paid Search | 396,423 | 87,079 | 21.97% |
| Social | 298,026 | 47,420 | 15.91% |

Email-sourced events were associated with Email campaigns only 22.17% of the time. Similarly, Paid Search traffic matched Paid Search campaigns 21.97% of the time, while Social traffic matched Social campaigns only 15.91% of the time.

Campaign-channel proportions were also similar across the three attributed traffic sources. For example, Email-sourced events were distributed as follows:

| Campaign channel | Event count | Percentage of Email traffic |
| --- | ---: | ---: |
| Email | 65,850 | 22.17% |
| Paid Search | 65,080 | 21.91% |
| Affiliate | 65,046 | 21.90% |
| Display | 53,585 | 18.04% |
| Social | 47,456 | 15.98% |

### Finding and analytical decision

Campaign-channel proportions are similar across Email, Paid Search, and Social traffic and closely resemble the overall campaign-channel distribution. The low matching-channel percentages suggest that `campaign_id` may have been assigned independently of `traffic_source` in the synthetic dataset.

Therefore, `traffic_source` and campaign `channel` are treated as separate source-provided dimensions rather than as a consistent attribution hierarchy. Traffic-source performance is not interpreted as the performance of campaigns using the corresponding channel.

### SQL validation

See [`traffic_source_vs_campaign_validation.sql`](../sql/data_validation/traffic_source_vs_campaign_validation.sql).

## 4. Experiment-Group Assignment Validation

### Validation objective

Determine whether `experiment_group` has a consistent assignment unit and can support conventional A/B-test analysis.

The dataset does not include an `experiment_id` or documentation identifying the intended assignment process. Customer-level, customer-campaign-level, session-level, and event-level assignments were therefore considered.

### Experiment-group allocation

All experiment-group values are complete and use one of the three expected labels.

| Experiment group | Events | Unique customers | Event percentage |
| --- | ---: | ---: | ---: |
| Control | 1,192,701 | 100,000 | 59.95% |
| Variant_A | 399,338 | 98,163 | 20.07% |
| Variant_B | 397,512 | 98,047 | 19.98% |

The event allocation follows an approximately 60% Control, 20% Variant A, and 20% Variant B distribution. However, balanced allocation does not establish stable or random assignment.

### Customer-level assignment

| Number of groups per customer | Customers | Customer percentage |
| ---: | ---: | ---: |
| 1 | 40 | 0.04% |
| 2 | 3,710 | 3.71% |
| 3 | 96,250 | 96.25% |

Only 40 customers remained in one experiment group across all their events. Most customers—96.25%—appeared in all three groups. Therefore, `experiment_group` does not represent a stable global customer assignment.

Different assignments could be valid if customers participated in separate campaign experiments. Customer-campaign combinations were therefore tested next.

### Customer-campaign assignment

| Validation measure | Result | Percentage |
| --- | ---: | ---: |
| Total customer-campaign pairs | 899,552 | — |
| Single-event pairs | 813,416 | 90.42% |
| Repeated testable pairs | 86,136 | 9.58% |
| Consistent repeated pairs | 36,684 | 42.59% |
| Inconsistent repeated pairs | 49,452 | 57.41% |

Most customer-campaign pairs contain only one event and cannot demonstrate whether assignment remained stable. Among the 86,136 repeated pairs that could be tested, 49,452—or 57.41%—appeared in more than one experiment group.

The underlying records also show individual customers switching groups within the same campaign. Therefore, `experiment_group` does not represent a stable customer-campaign assignment.

### Assignment-level assessment

| Possible assignment level | Assessment |
| --- | --- |
| Customer | Invalid: 96.25% of customers appear in all three groups |
| Customer-campaign | Unreliable: 57.41% of repeated pairs switch groups |
| Session | Cannot be evaluated because `session_id` is unreliable |
| Event | Possible as a record-level label, but the experiment design and assignment process are undocumented |

### Finding and analytical decision

The dataset does not identify the intended experimental unit. Assignments are not stable at either the customer or customer-campaign level, while session-level assignment cannot be evaluated reliably.

The field appears most consistent with an event-level label. However, events from the same customer cannot be treated as independent experimental participants, and the dataset does not provide the experiment design, assignment method, exposure definition, or outcome definition required to validate an event-level experiment.

Therefore, `experiment_group` is retained for descriptive event summaries only. It is not used to:

- Calculate conversion uplift
- Perform statistical significance testing
- Estimate causal treatment effects
- Compare customer conversion between groups
- Treat individual events as independent experiment participants

The approximately 60%/20%/20% event allocation may be reported descriptively, but it should not be interpreted as evidence of valid randomization.

### SQL validation

See [`experiment_group_validation.sql`](../sql/data_validation/experiment_group_validation.sql).

## 5. Purchase Event and Transaction Reconciliation

### Validation objective

Determine whether retained purchase events reconcile with transaction records using `customer_id`, `product_id`, and the exact timestamp.

### Results

| Validation measure | Result |
| --- | ---: |
| Purchase events | 92,678 |
| Purchase events with a valid product ID | 92,678 |
| Purchase events missing a product ID | 0 |
| Retained transactions | 92,678 |
| Completed transactions | 89,974 |
| Refunded transactions | 2,704 |
| Exact one-to-one matches | 92,678 |
| Matching campaign IDs | 92,678 |
| Conflicting campaign IDs | 0 |
| Matched refunded transactions | 2,704 |
| Duplicate purchase-event keys | 0 |
| Duplicate transaction keys | 0 |
| Valid purchase-event match rate | 100.00% |
| Transaction match rate | 100.00% |

### Finding and analytical decision

All 92,678 retained purchase events have a valid `product_id`. Each purchase event matched exactly one retained transaction with the same customer, product, timestamp, and campaign. This includes all 89,974 completed transactions and all 2,704 refunded transactions.

No conflicting campaign IDs or duplicate matching keys were found. The valid purchase-event match rate and transaction match rate are both 100.00%.

Purchase events may therefore be connected to transaction outcomes at the purchase-record level. However, `fact_transactions` remains the authoritative source for completed sales, refunds, quantities, discounts, and revenue.

This reconciliation establishes correspondence between purchase events and transaction records only. It does not establish an ordered customer journey through earlier views, clicks, or add-to-cart events. Those events remain suitable for aggregate event-count analysis only because reliable session and journey identifiers are unavailable.

### SQL validation

See [`purchase_reconciliation_validation.sql`](../sql/data_validation/purchase_reconciliation_validation.sql).

## 6. Customer and Product Timing Validation

### Validation objective

Determine whether events and transactions occurred on or after the associated customer's signup date and product's launch date.

Activity occurring on the same calendar date as signup or launch was considered valid.

### Results

| Validation measure | Invalid records | Percentage | Entities affected |
| --- | ---: | ---: | ---: |
| Events before customer signup | 993,429 | 49.93% | 94,889 customers |
| Transactions before customer signup | 45,492 | 49.09% | 34,158 customers |
| Product-linked events before product launch | 890,383 | 49.48% | 1,996 products |
| Transactions before product launch | 45,122 | 48.69% | 1,946 products |

Pre-signup event rates were approximately 50% for every event type:

| Event type | Total events | Events before signup | Percentage |
| --- | ---: | ---: | ---: |
| View | 1,043,573 | 521,842 | 50.01% |
| Click | 379,008 | 189,401 | 49.97% |
| Add to cart | 284,370 | 142,270 | 50.03% |
| Bounce | 189,922 | 94,424 | 49.72% |
| Purchase | 92,678 | 45,492 | 49.09% |

Pre-launch rates were also approximately 49% across event types containing product IDs:

| Event type | Product-linked events before launch | Percentage |
| --- | ---: | ---: |
| View | 516,764 | 49.52% |
| Click | 187,958 | 49.59% |
| Add to cart | 140,539 | 49.42% |
| Purchase | 45,122 | 48.69% |

Bounce events are not included in the product-launch comparison because they do not contain product IDs.

The timing inconsistencies are widespread rather than isolated to particular customers, products, or event types.

### Finding and analytical decision

The consistent invalid rates near 50% suggest that customer signup dates and product launch dates were generated independently of event and transaction timestamps in the synthetic dataset.

The records are retained because removing approximately half of the fact-table activity would materially distort the dataset. However, customer signup dates and product launch dates are not used to establish the temporal validity of events or transactions.

The dataset is not used for:

- Customer-tenure calculations
- Pre/post-signup comparisons
- Signup-cohort performance analysis
- Product-age calculations
- Pre/post-launch comparisons
- Product-launch cohort analysis
- Performance-since-launch metrics

Event and transaction timestamps may still be used for calendar-based activity and revenue trends. Signup and launch dates may also be summarized separately as dimension attributes, but they are not used to filter, sequence, or interpret fact-table activity.

### SQL validation

See [`entity_timing_validation.sql`](../sql/data_validation/entity_timing_validation.sql).

## 7. Event Product ID Availability

### Validation objective

Determine whether retained events contain the product information required for product- and category-level analysis.

### Results

Of the 1,989,551 retained events, 1,799,629—or 90.45%—have a valid `product_id`. The remaining 189,922 events are missing a product ID.

| Event type | Total events | Events with product ID | Missing product ID | Product ID coverage |
| --- | ---: | ---: | ---: | ---: |
| View | 1,043,573 | 1,043,573 | 0 | 100.00% |
| Click | 379,008 | 379,008 | 0 | 100.00% |
| Add to cart | 284,370 | 284,370 | 0 | 100.00% |
| Bounce | 189,922 | 0 | 189,922 | 0.00% |
| Purchase | 92,678 | 92,678 | 0 | 100.00% |
| **Total** | **1,989,551** | **1,799,629** | **189,922** | **90.45%** |

All retained view, click, add-to-cart, and purchase events contain valid product IDs. These event types may therefore be used for product- and category-level event analysis.

All 189,922 missing product IDs occur on bounce events. Missing product IDs appear across every page category because bounce events occur across all page categories. Product ID availability is therefore primarily associated with `event_type` rather than `page_category`.

### Finding and analytical decision

Views, clicks, add-to-cart events, and retained purchase events may be used for product- and category-level event analysis because product ID coverage is complete for these event types.

Bounce events are excluded from product-level analysis because none have an associated product ID. They may still be summarized overall or by dimensions that do not require a product.

All 92,678 retained purchase events contain valid product IDs and fully reconcile with the 92,678 retained transaction records. Product-level event ratios involving purchases therefore cover all purchase events retained in the warehouse.

The 10,449 source purchase events with missing product IDs were removed during ETL and are not included in the warehouse results above. Analyses based on retained purchase events therefore exclude these unusable source records.

`fact_transactions` remains the authoritative source for completed sales, refunds, quantities, discounts, and revenue.

### SQL validation

See [`event_product_validation.sql`](../sql/data_validation/event_product_validation.sql).

## 8. Overall Data Suitability and Analytical Scope

### Overall conclusion

The dataset passed structural checks for primary keys, foreign keys, required values, and permitted categorical values. Customer, product, transaction, and event records can therefore be joined and summarized at their documented grains.

However, several fields do not have sufficient logical or temporal consistency to support session analysis, customer journeys, lifecycle analysis, campaign-effectiveness measurement, or experimental conclusions. Downstream reporting will focus on descriptive customer, product, transaction, and event-level analysis while applying the restrictions identified below.

### Analytical suitability summary

| Data area | Suitability | Approved use | Restricted or excluded use |
| --- | --- | --- | --- |
| Customer attributes | Usable | Segmentation by loyalty tier, acquisition channel, country, age, and gender | Historical attribute changes |
| Customer purchasing behaviour | Usable with documented transaction rules | Purchase rate, repeat purchasing, transaction count, revenue, and average order value | Signup cohorts, customer tenure, retention since signup, and time from signup to purchase |
| Product attributes | Usable | Analysis by product, category, brand, premium status, and price band | Historical product pricing |
| Product performance | Usable with timing restrictions | Units sold, transaction volume, revenue, discounts, refunds, and revenue concentration | Product launch performance, product age, and lifecycle analysis |
| Transaction values | Usable with documented refund treatment | Gross sales, post-discount net revenue, discount value, average order value, and separately reported refund value | Verified purchase-to-refund matching, time to refund, and refund-processing analysis |
| Digital events | Usable at the event grain | Event volumes and aggregate event-count ratios by traffic source, device, page category, product, and calendar period | Sequenced funnels, individual customer journeys, and true conversion rates |
| Session fields | Not reliable | Documentation of the supplied fields only | Session counts, session duration, events per session, session conversion, and session bounce rate |
| Campaign identifiers | Limited descriptive use | Source-attributed event, transaction, and revenue comparisons by campaign characteristics | Treating campaign attribution as verified exposure |
| Campaign dates | Not reliable for performance analysis | Describing the campaign dimension | In-campaign filtering, pre/post analysis, campaign lifecycle performance, and causal impact |
| Traffic source and campaign channel | Usable separately | Independent summaries of traffic source and source-attributed campaign channel | Treating the two fields as a consistent attribution hierarchy |
| Experiment groups | Not validated for experimental analysis | Descriptive event counts by supplied experiment label | A/B-test results, statistical significance, incremental uplift, and causal conclusions |

### Downstream analysis decisions

Based on these results, the final analysis and Power BI report may include:

- Executive sales and revenue performance
- Customer segmentation and purchasing behaviour
- Product, category, brand, and premium-status performance
- Discount and refund-record analysis
- Revenue concentration across customers and products
- Recorded monthly transaction, revenue, and event patterns
- Digital event volumes by traffic source, device, page category, and event type
- Aggregate event-count ratios, clearly labelled as descriptive ratios rather than customer or session conversion rates

The following analyses will be excluded:

- Session-level behaviour and session-duration analysis
- Sequenced funnels and customer journey analysis
- Customer signup cohorts, tenure, and retention analysis
- Product launch and lifecycle analysis
- Campaign-window, pre/post, ROI, and incremental-impact analysis
- Conventional A/B testing or experiment-uplift analysis
- Verified purchase-to-refund journeys and time-to-refund analysis

### Reporting requirement

All downstream results should be presented as descriptive findings from a synthetic dataset. Dashboard labels and documentation must distinguish aggregate event-count ratios from customer or session conversion rates and source-provided campaign attribution from verified campaign exposure.

Within these boundaries, the dataset remains suitable for demonstrating ETL development, dimensional modelling, SQL analysis, data-quality assessment, Power BI development, and responsible interpretation of imperfect data.
