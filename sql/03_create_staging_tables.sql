CREATE TABLE IF NOT EXISTS staging_campaigns (
    campaign_code VARCHAR(50),
    campaign_name VARCHAR(100),
    campaign_type VARCHAR(50),
    target_audience VARCHAR(50),
    channel_used VARCHAR(50),
    language VARCHAR(50),
    start_date DATE,
    end_date DATE,
    daily_budget NUMERIC(12, 2)
);

CREATE TABLE IF NOT EXISTS staging_customers (
    customer_email VARCHAR(255),
    customer_segment VARCHAR(50),
    age_group VARCHAR(50),
    country VARCHAR(50),
    signup_date TIMESTAMP
);

CREATE TABLE IF NOT EXISTS staging_impression_events (
    campaign_code VARCHAR(50),
    customer_email VARCHAR(255),
    shown_at TIMESTAMP,
    device VARCHAR(50),
    location VARCHAR(50),
    browser VARCHAR(50),
    session_id VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS staging_click_events (
    campaign_code VARCHAR(50),
    customer_email VARCHAR(255),
    clicked_at TIMESTAMP,
    device VARCHAR(50),
    location VARCHAR(50),
    browser VARCHAR(50),
    session_id VARCHAR(100),
    cost_per_click NUMERIC(10, 2)
);

CREATE TABLE IF NOT EXISTS staging_lead_events (
    campaign_code VARCHAR(50),
    customer_email VARCHAR(255),
    lead_created_at TIMESTAMP,
    lead_source VARCHAR(50),
    contact_method VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS staging_conversion_events (
    campaign_code VARCHAR(50),
    customer_email VARCHAR(255),
    converted_at TIMESTAMP,
    revenue NUMERIC(12, 2),
    product_type VARCHAR(50),
    payment_type VARCHAR(50)
);