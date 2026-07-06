INSERT INTO dim_campaigns (
    campaign_code,
    campaign_name,
    campaign_type,
    target_audience,
    channel_used,
    language,
    start_date,
    end_date,
    is_active,
    daily_budget
)
SELECT DISTINCT
    campaign_code,
    campaign_name,
    campaign_type,
    target_audience,
    channel_used,
    language,
    start_date,
    end_date,
    CASE
        WHEN end_date >= CURRENT_DATE THEN TRUE
        ELSE FALSE
    END AS is_active,
    daily_budget
FROM staging_campaigns
WHERE campaign_code IS NOT NULL
ON CONFLICT (campaign_code) DO NOTHING;


INSERT INTO dim_customers (
    email,
    customer_segment,
    age_group,
    country,
    signup_date
)
SELECT DISTINCT
    customer_email,
    customer_segment,
    age_group,
    country,
    signup_date
FROM staging_customers
WHERE customer_email IS NOT NULL
ON CONFLICT (email) DO NOTHING;


INSERT INTO click_events (
    campaign_id,
    user_id,
    clicked_at,
    device,
    location,
    browser,
    session_id,
    cost_per_click
)
SELECT
    c.campaign_id,
    u.user_id,
    s.clicked_at,
    s.device,
    s.location,
    s.browser,
    s.session_id,
    s.cost_per_click
FROM staging_click_events s
JOIN dim_campaigns c
    ON s.campaign_code = c.campaign_code
JOIN dim_customers u
    ON s.customer_email = u.email;


INSERT INTO impression_events (
    campaign_id,
    user_id,
    shown_at,
    device,
    location,
    browser,
    session_id
)
SELECT
    c.campaign_id,
    u.user_id,
    s.shown_at,
    s.device,
    s.location,
    s.browser,
    s.session_id
FROM staging_impression_events s
JOIN dim_campaigns c
    ON s.campaign_code = c.campaign_code
JOIN dim_customers u
    ON s.customer_email = u.email;


INSERT INTO lead_events (
    campaign_id,
    user_id,
    lead_created_at,
    lead_source,
    contact_method
)
SELECT
    c.campaign_id,
    u.user_id,
    s.lead_created_at,
    s.lead_source,
    s.contact_method
FROM staging_lead_events s
JOIN dim_campaigns c
    ON s.campaign_code = c.campaign_code
JOIN dim_customers u
    ON s.customer_email = u.email;


INSERT INTO conversion_events (
    campaign_id,
    user_id,
    converted_at,
    revenue,
    product_type,
    payment_type
)
SELECT
    c.campaign_id,
    u.user_id,
    s.converted_at,
    s.revenue,
    s.product_type,
    s.payment_type
FROM staging_conversion_events s
JOIN dim_campaigns c
    ON s.campaign_code = c.campaign_code
JOIN dim_customers u
    ON s.customer_email = u.email;
