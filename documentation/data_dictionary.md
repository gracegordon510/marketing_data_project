# Marketing Analytics Data Dictionary

## 1. Purpose

This document defines the structure, meaning, relationships, constraints, and appropriate analytical use of data in the `marketing_analytics` SQL Server database.

The warehouse supports customer, product, transaction, digital-event, and marketing-campaign analysis. It was created from a synthetic marketing and e-commerce dataset using a Python ETL pipeline and a SQL Server dimensional model.

The SQL warehouse schema is the authoritative source for column names, data types, nullability, keys, and constraints. Descriptive ranges and data-quality observations are based on the exploratory data analysis (EDA) of the source files.

## 2. Database Overview

| Table | Table Type | Grain |
| --- | --- | --- |
| `dbo.dim_customers` | Dimension | One row per unique customer |
| `dbo.dim_products` | Dimension | One row per unique product |
| `dbo.dim_campaigns` | Dimension | One row per campaign, including the unattributed reference record |
| `dbo.fact_events` | Fact | One row per recorded digital event |
| `dbo.fact_transactions` | Fact | One row per retained purchase or refund transaction record |

### Source profile

| Dataset | Source Rows | Source Columns | Primary Identifier |
| --- | ---: | ---: | --- |
| Campaigns | 50 | 7 | `campaign_id` |
| Customers | 100,000 | 7 | `customer_id` |
| Products | 2,000 | 6 | `product_id` |
| Events | 2,000,000 | 12 | `event_id` |
| Transactions | 103,127 | 9 | `transaction_id` |

Source counts describe the raw files before ETL filtering or the addition of warehouse reference records. They should not be assumed to equal current warehouse row counts after future pipeline runs.

## 3. Relationships

| Fact Table | Foreign Key | Referenced Table | Referenced Key | Cardinality |
| --- | --- | --- | --- | --- |
| `dbo.fact_events` | `customer_id` | `dbo.dim_customers` | `customer_id` | Many events to one customer |
| `dbo.fact_events` | `product_id` | `dbo.dim_products` | `product_id` | Many events to zero or one product |
| `dbo.fact_events` | `campaign_id` | `dbo.dim_campaigns` | `campaign_id` | Many events to one campaign/reference record |
| `dbo.fact_transactions` | `customer_id` | `dbo.dim_customers` | `customer_id` | Many transactions to one customer |
| `dbo.fact_transactions` | `product_id` | `dbo.dim_products` | `product_id` | Many transactions to one product |
| `dbo.fact_transactions` | `campaign_id` | `dbo.dim_campaigns` | `campaign_id` | Many transactions to one campaign/reference record |

## 4. General Conventions

| Convention | Definition |
| --- | --- |
| Currency | Monetary values are stored as decimals with two decimal places. The source documentation does not identify a currency. |
| Percentage rates | Rates such as `discount_applied` and `expected_uplift` are stored as proportions between 0 and 1. For example, `0.10` represents 10%. |
| Timestamps | Event and transaction timestamps are stored to the nearest second using `DATETIME2(0)`. |
| Unattributed campaign | `campaign_id = 0` means that no marketing campaign was attributed to the record. |
| Unknown device | A null `device_type` means device information was not captured. It may be labelled `Unknown` in reporting without changing the stored value. |
| Source attribution | `acquisition_channel`, `traffic_source`, and campaign `channel` describe different concepts and must not be used interchangeably. |

## 5. Dimension Tables

## `dbo.dim_customers`

### Purpose

Stores demographic, signup, loyalty, and acquisition attributes used to segment customers.

### Grain

One row represents one unique customer.

### Keys

- Primary key: `customer_id`
- Primary key index: clustered
- Referenced by `dbo.fact_events.customer_id`
- Referenced by `dbo.fact_transactions.customer_id`

### Column definitions

| Column | SQL Data Type | Nullable | Key | Business Definition | Allowed Values / Range | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `customer_id` | `INT` | No | PK | Unique identifier assigned to a customer | Unique integer | Source contained 100,000 unique IDs and no duplicate primary keys. |
| `signup_date` | `DATE` | No | — | Date the customer registered | Source range: 2021-01-01 to 2023-12-31 | — |
| `country` | `VARCHAR(10)` | No | — | Customer's recorded country | US, IN, UK, BR, CA, DE, AU | Values are country codes supplied by the source. |
| `age` | `TINYINT` | No | — | Customer's recorded age | Warehouse constraint: 0–120; observed source range: 18–70 | The source has a pronounced but retained spike at age 18. |
| `gender` | `VARCHAR(20)` | No | — | Customer's recorded gender category | Male, Female, Other | — |
| `loyalty_tier` | `VARCHAR(20)` | No | — | Customer's recorded loyalty-program tier | Bronze, Silver, Gold, Platinum | Represents the available tier, not a history of tier changes. |
| `acquisition_channel` | `VARCHAR(30)` | No | — | Channel credited with originally acquiring the customer | Referral, Organic, Paid Search, Social, Email | Not the same as event-level `traffic_source` or campaign `channel`. |

### Data profile and usage notes

- No source null values or duplicate `customer_id` values were identified.
- There were 1,313 duplicate combinations when `customer_id` was excluded. These are retained because customers can share the same demographic and acquisition attributes.
- Approximately 60% of customers are in the Bronze tier.
- Organic and Paid Search are the two most common acquisition channels, at approximately 30% each.
- The United States is the largest recorded market, at approximately 35% of customers.
- Customer attributes describe the available current record. The dataset does not contain slowly changing dimension history.

## `dbo.dim_products`

### Purpose

Stores product category, brand, pricing, launch, and premium-status attributes.

### Grain

One row represents one unique product.

### Keys

- Primary key: `product_id`
- Primary key index: clustered
- Referenced by `dbo.fact_events.product_id`
- Referenced by `dbo.fact_transactions.product_id`

### Column definitions

| Column | SQL Data Type | Nullable | Key | Business Definition | Allowed Values / Range | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `product_id` | `INT` | No | PK | Unique identifier assigned to a product | Unique integer | Source contained 2,000 unique IDs and no duplicate primary keys. |
| `category` | `VARCHAR(30)` | No | — | Product's assigned merchandise category | Electronics, Fashion, Home, Grocery, Sports, Beauty | — |
| `brand` | `VARCHAR(100)` | No | — | Brand assigned to the product | Source contained 100 brands | Brand names are source-provided labels. |
| `base_price` | `DECIMAL(12, 2)` | No | — | Standard unit price of the product before transaction-specific discounts | Greater than 0; observed source range: 5.11–464.58 | — |
| `launch_date` | `DATE` | No | — | Recorded product launch date | Source range: 2021-01-01 to 2023-12-31 | Converted from source text to a date during ETL. |
| `is_premium` | `BIT` | No | — | Indicates whether the product is classified as premium | 0 = No, 1 = Yes | Premium status is strongly associated with higher source prices. |

### Data profile and usage notes

- No source null values, duplicate primary keys, or full duplicate product records were identified.
- Product prices are right-skewed: the source median is approximately 61 and the mean is approximately 71.
- Electronics represent approximately 23% of the catalog, have the highest average price, and contain most products priced above 300.
- This is not a historical price dimension. `base_price` is the available product price and does not preserve price changes over time.

## `dbo.dim_campaigns`

### Purpose

Stores marketing campaign characteristics and the required unattributed reference record.

### Grain

One row represents one source campaign or the `campaign_id = 0` reference member.

### Keys

- Primary key: `campaign_id`
- Primary key index: clustered
- Referenced by `dbo.fact_events.campaign_id`
- Referenced by `dbo.fact_transactions.campaign_id`

### Column definitions

| Column | SQL Data Type | Nullable | Key | Business Definition | Allowed Values / Range | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `campaign_id` | `INT` | No | PK | Unique campaign or reference-record identifier | 0 or a source campaign ID | `0` is the seeded unattributed member; source campaigns use IDs 1–50. |
| `channel` | `VARCHAR(30)` | No | — | Marketing channel assigned to the campaign | Paid Search, Email, Affiliate, Display, Social, Unattributed | `Unattributed` is used only for the reference member. |
| `objective` | `VARCHAR(30)` | No | — | Campaign's stated business objective | Acquisition, Cross-sell, Reactivation, Retention, Not Applicable | `Not Applicable` is used for campaign 0. |
| `target_segment` | `VARCHAR(30)` | No | — | Customer segment the campaign is intended to target | All, Churn Risk, Deal Seekers, High Value, New Customers, Not Applicable | Does not prove that each attributed customer belongs to the stated segment. |
| `start_date` | `DATE` | Yes | — | Recorded campaign start date | Source range: 2021-01-20 to 2023-11-04 | Null only for the unattributed member under the current seed design. |
| `end_date` | `DATE` | Yes | — | Recorded campaign end date | Source range: 2021-02-02 to 2024-01-06 | Constraint permits only dates on or after `start_date`. |
| `expected_uplift` | `DECIMAL(6, 4)` | Yes | — | Expected proportional improvement associated with the campaign | 0–1; observed source range: 0.022–0.144 | This is an expectation, not measured or causal uplift. Null for campaign 0. |

### Seeded reference record

| Column | Seeded Value |
| --- | --- |
| `campaign_id` | 0 |
| `channel` | Unattributed |
| `objective` | Not Applicable |
| `target_segment` | Not Applicable |
| `start_date` | NULL |
| `end_date` | NULL |
| `expected_uplift` | NULL |

The reference row converts the source's business value `campaign_id = 0` into a valid foreign-key relationship. It is not a real campaign and should normally be excluded from campaign-performance rankings.

### Data profile and usage notes

- The source contained 50 complete campaigns with unique primary keys and no full duplicate records.
- Source campaign durations range from 8 to 89 days, with a median of approximately 54 days.
- Campaign dates are not reliable for linking activity to an active campaign period. Only approximately 4.66% of campaign-linked source events and 4.87% of campaign-linked source transactions occurred within their recorded campaign dates.
- Treat `campaign_id` as source-provided categorical attribution. Do not use campaign dates to establish exposure, filter performance, compare pre/post periods, or calculate incremental impact.
- `expected_uplift` must not be presented as realized performance.

## 6. Fact Tables

## `dbo.fact_events`

### Purpose

Stores customer digital interactions for event-volume, traffic-source, device, page, product, campaign, and limited experiment analysis.

### Grain

One row represents one recorded digital event. A row does not represent a session, transaction, or unique customer journey.

### Keys

- Primary key: `event_id`
- Primary key index: clustered
- Foreign key: `customer_id` → `dbo.dim_customers.customer_id`
- Foreign key: `product_id` → `dbo.dim_products.product_id`
- Foreign key: `campaign_id` → `dbo.dim_campaigns.campaign_id`

### Column definitions

| Column | SQL Data Type | Nullable | Key | Business Definition | Allowed Values / Range | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `event_id` | `BIGINT` | No | PK | Unique identifier assigned to an event record | Unique integer | Source contained 2,000,000 unique event IDs. |
| `event_timestamp` | `DATETIME2(0)` | No | — | Date and time when the event was recorded | Source range: 2021-01-01 to 2023-12-31 | Renamed from source `timestamp` and converted during ETL. |
| `event_type` | `VARCHAR(30)` | No | — | Type of digital interaction | view, click, add_to_cart, bounce, purchase | Values are enforced by a check constraint. |
| `customer_id` | `INT` | No | FK | Customer associated with the event | Valid customer ID | Source foreign-key validation passed. |
| `product_id` | `INT` | Yes | FK | Product associated with the event, when applicable | Valid product ID or NULL | Source had 200,371 nulls (approximately 10%); these are plausible for non-product activity. |
| `campaign_id` | `INT` | No | FK | Source-provided campaign attribution | 0 or valid campaign ID | `0` means unattributed. Timing does not validate attribution. |
| `session_id` | `VARCHAR(100)` | Yes | — | Source-provided identifier intended to identify a browsing session | Text identifier or NULL | Unreliable and excluded from session analysis. |
| `device_type` | `VARCHAR(20)` | Yes | — | Device category associated with the event | Desktop, Mobile, Tablet, or NULL | Source had 40,300 nulls (approximately 2%). |
| `traffic_source` | `VARCHAR(30)` | No | — | Recorded source through which the event arrived | Email, Organic, Paid Search, Social, Direct | Capitalization was standardized during ETL. |
| `page_category` | `VARCHAR(30)` | No | — | Category of page associated with the event | PLP, PDP, CHECKOUT, HOME, CART | PLP means product listing page; PDP means product detail page. |
| `session_duration_sec` | `DECIMAL(12, 2)` | Yes | — | Source-provided session-duration value in seconds | NULL or value ≥ 0; observed source range: 0.1–7,533.8 | Not suitable for session-level analysis because `session_id` is unreliable. |
| `experiment_group` | `VARCHAR(30)` | No | — | Experiment label recorded on the event | Control, Variant_A, Variant_B | Event-level label; not a validated permanent customer assignment. |

### Source profile

| Attribute | Observation |
| --- | --- |
| Event rows | 2,000,000 |
| Unique customers | 100,000 |
| Distinct session IDs | 633,462 |
| Views | Approximately 52% of events |
| Clicks | Approximately 19% of events |
| Add-to-cart events | Approximately 14% of events |
| Bounces | Approximately 10% of events |
| Purchases | Approximately 5% of events |
| Organic traffic | Approximately 40% of events |
| Paid Search traffic | Approximately 20% of events |
| Mobile events | Approximately 60% of events |

### Event funnel interpretation

The following event-count ratios may be used as descriptive funnel indicators:

| Metric | Definition | Interpretation Restriction |
| --- | --- | --- |
| View-to-click ratio | Click events ÷ view events | Aggregate event ratio, not the percentage of viewers who clicked |
| Click-to-cart ratio | Add-to-cart events ÷ click events | Aggregate event ratio, not a sequenced customer journey |
| Cart-to-purchase ratio | Purchase events ÷ add-to-cart events | Aggregate event ratio, not a session conversion rate |
| Event-based bounce share | Bounce events ÷ the explicitly stated event denominator | Must not be described as a session bounce rate |

### Known limitations

### Invalid Rows
The source contained 10,449 purchase-event rows with a missing product_id. Because purchase events require a valid product ID for reconciliation with transactions and product-level analysis, these rows are removed during ETL. Therefore, the warehouse event count is lower than the raw source count.

#### Session identifiers

- Of 633,462 distinct session IDs, 533,914 (84.29%) were associated with multiple customers.
- Some session IDs were associated with as many as 14 customers.
- 533,786 session IDs spanned multiple calendar days, and the longest apparent session spanned 1,094 days.
- Do not calculate sessions, customer journeys, events per session, session conversion, or session bounce rate from `session_id`.
- Do not use `session_duration_sec` to calculate reliable session-duration metrics.

#### Campaign timing and attribution

- Approximately 95.34% of campaign-linked source events fall outside the associated campaign dates.
- `campaign_id` may be used only as source-provided categorical attribution, not proof that exposure occurred during the campaign.
- Traffic source and campaign channel do not form a consistent attribution hierarchy. Their distributions indicate that campaign assignment was likely independent of traffic source in the synthetic data.
- Analyze `traffic_source` and campaign `channel` separately and disclose this limitation when comparing them.

#### Experiment groups

- Experiment group is recorded at the event level.
- A customer may validly have different assignments in different campaigns, so overall customer-level group counts are not sufficient to validate an experiment.
- Assignment integrity must be tested at the customer-campaign grain, particularly among pairs with multiple events.
- Single-event customer-campaign pairs cannot demonstrate stability.
- Even stable labels would not prove random assignment without experiment-design documentation.
- Do not report causal uplift, statistical significance, or conventional A/B-test results unless within-campaign assignment stability and the experiment design are validated.

## `dbo.fact_transactions`

### Purpose

Stores retained purchase and refund records for customer, product, revenue, discount, refund, campaign, and time-based analysis.

### Grain

One row represents the latest recorded state of one transaction as supplied and transformed by the pipeline. The analysis assumes that when a transaction was refunded, its original row was changed in place: refund_flag was set to 1 and transaction_amount became negative. Therefore, a separate earlier purchase row is not expected for that refunded transaction.

### Keys

- Primary key: `transaction_id`
- Primary key index: clustered
- Foreign key: `customer_id` → `dbo.dim_customers.customer_id`
- Foreign key: `product_id` → `dbo.dim_products.product_id`
- Foreign key: `campaign_id` → `dbo.dim_campaigns.campaign_id`

### Column definitions

| Column | SQL Data Type | Nullable | Key | Business Definition | Allowed Values / Range | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `transaction_id` | `BIGINT` | No | PK | Unique identifier assigned to a transaction record | Unique integer | Source contained 103,127 unique transaction IDs before ETL filtering. |
| `transaction_timestamp` | `DATETIME2(0)` | No | — | Date and time associated with the transaction | Source range: 2021-01-01 to 2023-12-31 | Renamed from source `timestamp` and converted during ETL. |
| `customer_id` | `INT` | No | FK | Customer associated with the transaction | Valid customer ID | Source foreign-key validation passed. |
| `product_id` | `INT` | No | FK | Product associated with the transaction | Valid product ID | Raw transactions with missing product and revenue information are unusable and removed before load. |
| `campaign_id` | `INT` | No | FK | Source-provided campaign attribution | 0 or valid campaign ID | `0` means unattributed. Timing does not validate attribution. |
| `quantity` | `SMALLINT` | No | — | Number of units recorded on the transaction | Warehouse constraint: ≥ 1; observed source values: 1–4 | Used with `base_price` to calculate `gross_revenue`. |
| `transaction_amount` | `DECIMAL(14, 2)` | No | — | Final recorded transaction value after discount | Positive for completed sales and negative for transactions changed to refunded status | The source column named `gross_revenue` was renamed to `transaction_amount`. |
| `gross_revenue` | `DECIMAL(14, 2)` | No | — | Product base price multiplied by quantity before discounts and regardless of final refund status | Greater than 0 | Derived during ETL using the product dimension. Always positive, including on refund rows. |
| `discount_applied` | `DECIMAL(6, 4)` | No | — | Discount rate recorded for the transaction | 0–1; observed source values: 0%, 5%, 10%, 15%, 20% | A value of `0.10` represents a 10% discount. |
| `refund_flag` | `BIT` | No | — | Indicates whether the transaction row represents a refund | 0 = purchase, 1 = refund | A refunded row is assumed to be the original transaction changed in place, not an additional refund event. |

### Source-to-warehouse transformations

| Source Field / Condition | Warehouse Treatment |
| --- | --- |
| Source `timestamp` | Renamed to `transaction_timestamp` and converted to datetime |
| Source `gross_revenue` | Renamed to `transaction_amount` because it represents the post-discount amount paid and is negative for refunds |
| Product `base_price` × transaction `quantity` | Creates warehouse `gross_revenue` |
| Missing `campaign_id` or source value 0, according to pipeline rule | Stored as `campaign_id = 0` and linked to the unattributed campaign record |
| Missing `product_id` and corresponding source revenue | Transaction is unusable for the non-null fact schema and is removed before load |
| Source `refund_flag` | Converted to SQL `BIT` semantics |

### Standard metric definitions

These definitions reflect the selected interpretation that refund rows are independently generated records rather than verified reversals of known purchases.

| Metric | Definition |
| --- | --- |
| Completed transaction count | Count of rows where `refund_flag = 0` |
| Refund transaction count | Count of rows where `refund_flag = 1` |
| Units sold | Sum of `quantity` where `refund_flag = 0` |
| Units recorded as refunded | Sum of `quantity` where `refund_flag = 1` |
| Gross sales | Sum of `gross_revenue` where `refund_flag = 0` |
| Net revenue | Sum of `transaction_amount` where `refund_flag = 0` |
| Discount value | Sum of `gross_revenue - transaction_amount` where `refund_flag = 0` |
| Refund value | Absolute sum of `transaction_amount` where `refund_flag = 1` |
| Average order value | Net revenue ÷ completed transaction count |
| Refund rate | Refund transaction count ÷ total transaction record count, unless another denominator is explicitly stated |
| Purchasing customer | Customer with at least one row where `refund_flag = 0` |
| Repeat customer | Purchasing customer with more than one row where `refund_flag = 0` |

### Known Limitations

#### Refund interpretation

Refund records are assumed to represent transactions whose original purchase rows were updated in place. Only 18 of 3,029 raw refund records could be matched to a separate earlier purchase for the same customer and product, which supports this interpretation. However, the dataset does not provide transaction-status history to confirm it.

#### Missing transaction history

Each transaction row contains only its final recorded state. For refunded transactions, the original purchase state, original purchase timestamp, and date of the refund-status change are unavailable.

Therefore, the data should not be used to calculate:

- Time to refund
- Refund-processing time
- Purchase-to-refund status transitions

#### Refund timestamps

Refunded transactions may still be analyzed using their customer, product, campaign, quantity, and recorded timestamp attributes. However, the timestamp should not be interpreted as a confirmed purchase date or refund date.

#### Revenue calculations

The signed `transaction_amount` should not be summed across all rows as the documented net-revenue measure. Revenue calculations must follow the defined treatment of completed and refunded transactions.

#### Campaign timing

Only approximately 4.87% of campaign-linked source transactions occurred within their associated campaign periods. Campaign dates should not be used to validate transaction attribution or evaluate campaign-period performance.

#### Removed transaction rows

The source contained 10,449 transaction rows with both a missing `product_id` and missing source revenue. Because the fact table requires a valid product and the information needed to derive revenue, these unusable rows are removed during ETL. The warehouse transaction count is therefore lower than the raw source count.

## 7. Indexes

All primary keys are clustered indexes. The following nonclustered indexes support common joins, filters, and dashboard queries:

| Table | Index | Indexed Column |
| --- | --- | --- |
| `dbo.fact_events` | `ix_fact_events_customer_id` | `customer_id` |
| `dbo.fact_events` | `ix_fact_events_product_id` | `product_id` |
| `dbo.fact_events` | `ix_fact_events_campaign_id` | `campaign_id` |
| `dbo.fact_events` | `ix_fact_events_timestamp` | `event_timestamp` |
| `dbo.fact_events` | `ix_fact_events_event_type` | `event_type` |
| `dbo.fact_transactions` | `ix_fact_transactions_customer_id` | `customer_id` |
| `dbo.fact_transactions` | `ix_fact_transactions_product_id` | `product_id` |
| `dbo.fact_transactions` | `ix_fact_transactions_campaign_id` | `campaign_id` |
| `dbo.fact_transactions` | `ix_fact_transactions_timestamp` | `transaction_timestamp` |

Indexes improve query access but do not change the grain or meaning of the data.

## 8. Data Quality and Analytical Suitability Summary

| Data Area | Status | Approved Use | Restricted or Excluded Use |
| --- | --- | --- | --- |
| Customer identifiers and attributes | Usable | Segmentation, purchasing behaviour, loyalty, acquisition, country, age, and gender analysis | Historical changes to customer attributes |
| Product identifiers and attributes | Usable | Product/category performance, price, premium positioning, and revenue analysis | Historical product pricing |
| Transaction revenue | Usable with defined rules | Gross sales, post-discount revenue, discount value, separately reported refund value | Treating refunds as verified reversals without a purchase link |
| Event volumes | Usable at event grain | Event counts and aggregate event-count ratios by source, device, page, product, and time | Sequential customer funnels without reliable journey keys |
| Session data | Not reliable | None beyond documenting the supplied fields | Sessions, session duration, events per session, session conversion, session bounce rate, and customer journeys |
| Campaign identifiers | Limited use | Source-provided categorical comparisons by campaign attributes | Proof of valid exposure or attribution |
| Campaign dates | Not reliable for performance | Describing the campaign dimension itself | In-campaign filtering, lifecycle performance, pre/post analysis, or causal impact |
| Traffic source vs. campaign channel | Separate descriptive fields | Independent traffic-source and campaign-channel summaries | Treating the fields as a consistent attribution hierarchy |
| Experiment groups | Not validated for causal analysis | Descriptive counts after clearly stating the grain | Uplift, significance tests, or causal A/B-test conclusions without assignment validation |

## 9. Power BI Modelling Guidance

- Build one-to-many, single-direction relationships from each dimension to its fact tables.
- Treat `dim_customers`, `dim_products`, and `dim_campaigns` as shared dimensions.
- Create a dedicated date dimension for event and transaction reporting rather than joining the two fact tables directly.
- Do not create a direct relationship between `fact_events` and `fact_transactions` unless a valid business key and grain are established.
- Use explicit DAX measures that reproduce the metric definitions in this document.
- Label event funnel measures as event-based ratios, not session or user conversion rates.
- Exclude campaign 0 from campaign rankings but retain it in totals when unattributed activity is relevant.
- Display `Unknown` for null device values through a reporting label or dimension treatment while preserving the underlying null semantics.
- Include concise report notes for campaign timing, session IDs, refunds, and experiment-group limitations.
