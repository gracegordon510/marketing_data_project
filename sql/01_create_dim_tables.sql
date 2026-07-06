CREATE TABLE IF NOT EXISTS dim_campaigns (
    campaign_id BIGINT GENERATED ALWAYS AS IDENTITY,
    campaign_code VARCHAR(50) UNIQUE,
    campaign_name VARCHAR(100),
    campaign_type VARCHAR(50),
    target_audience VARCHAR(50),
    channel_used VARCHAR(50),
    language VARCHAR(50),
    start_date DATE,
    end_date DATE,
    is_active BOOLEAN,
    daily_budget NUMERIC(12, 2),

    CONSTRAINT pk_dim_campaigns PRIMARY KEY (campaign_id)
);

CREATE TABLE IF NOT EXISTS dim_customers (
    user_id BIGINT GENERATED ALWAYS AS IDENTITY,
    email VARCHAR(255) UNIQUE,
    customer_segment VARCHAR(50),
    age_group VARCHAR(50),
    country VARCHAR(50),
    signup_date TIMESTAMP,

    CONSTRAINT pk_dim_customers PRIMARY KEY (user_id)
);

CREATE TABLE IF NOT EXISTS impression_events (
    impression_id BIGINT GENERATED ALWAYS AS IDENTITY,
    campaign_id BIGINT,
    user_id BIGINT,
    shown_at TIMESTAMP,
    device VARCHAR(50),
    location VARCHAR(50),
    browser VARCHAR(50),
    session_id VARCHAR(100),

    CONSTRAINT pk_impression_events PRIMARY KEY (impression_id),
    CONSTRAINT fk_impression_campaign 
        FOREIGN KEY (campaign_id) REFERENCES dim_campaigns(campaign_id),
    CONSTRAINT fk_impression_user 
        FOREIGN KEY (user_id) REFERENCES dim_customers(user_id)
);

CREATE TABLE IF NOT EXISTS click_events (
    click_id BIGINT GENERATED ALWAYS AS IDENTITY,
    campaign_id BIGINT,
    user_id BIGINT,
    clicked_at TIMESTAMP,
    device VARCHAR(50),
    location VARCHAR(50),
    browser VARCHAR(50),
    session_id VARCHAR(100),
    cost_per_click NUMERIC(10, 2),

    CONSTRAINT pk_click_events PRIMARY KEY (click_id),
    CONSTRAINT fk_click_campaign 
        FOREIGN KEY (campaign_id) REFERENCES dim_campaigns(campaign_id),
    CONSTRAINT fk_click_user 
        FOREIGN KEY (user_id) REFERENCES dim_customers(user_id)
);

CREATE TABLE IF NOT EXISTS lead_events (
    lead_id BIGINT GENERATED ALWAYS AS IDENTITY,
    campaign_id BIGINT,
    user_id BIGINT,
    lead_created_at TIMESTAMP,
    lead_source VARCHAR(50),
    contact_method VARCHAR(50),

    CONSTRAINT pk_lead_events PRIMARY KEY (lead_id),
    CONSTRAINT fk_lead_campaign 
        FOREIGN KEY (campaign_id) REFERENCES dim_campaigns(campaign_id),
    CONSTRAINT fk_lead_user 
        FOREIGN KEY (user_id) REFERENCES dim_customers(user_id)
);

CREATE TABLE IF NOT EXISTS conversion_events (
    conversion_id BIGINT GENERATED ALWAYS AS IDENTITY,
    campaign_id BIGINT,
    user_id BIGINT,
    converted_at TIMESTAMP,
    revenue NUMERIC(12, 2),
    product_type VARCHAR(50),
    payment_type VARCHAR(50),

    CONSTRAINT pk_conversion_events PRIMARY KEY (conversion_id),
    CONSTRAINT fk_conversion_campaign 
        FOREIGN KEY (campaign_id) REFERENCES dim_campaigns(campaign_id),
    CONSTRAINT fk_conversion_user 
        FOREIGN KEY (user_id) REFERENCES dim_customers(user_id)
);

 
 
 
