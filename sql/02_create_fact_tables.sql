DROP TABLE IF EXISTS dbo.fact_impression_events;
CREATE TABLE dbo.fact_impression_events (
    impression_id BIGINT IDENTITY(1,1) NOT NULL,
    campaign_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    shown_at DATETIME2(0) NOT NULL,
    device VARCHAR(50) NULL,
    location VARCHAR(50) NULL,
    browser VARCHAR(50) NULL,
    session_id VARCHAR(100) NULL,

    CONSTRAINT pk_fact_impression_events
        PRIMARY KEY (impression_id),

    CONSTRAINT fk_fact_impression_events_campaign
        FOREIGN KEY (campaign_id)
        REFERENCES dbo.dim_campaigns (campaign_id),

    CONSTRAINT fk_fact_impression_events_customer
        FOREIGN KEY (user_id)
        REFERENCES dbo.dim_customers (user_id)
);
GO

DROP TABLE IF EXISTS dbo.fact_click_events;
CREATE TABLE dbo.fact_click_events (
    click_id BIGINT IDENTITY(1,1) NOT NULL,
    campaign_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    clicked_at DATETIME2(0) NOT NULL,
    device VARCHAR(50) NULL,
    location VARCHAR(50) NULL,
    browser VARCHAR(50) NULL,
    session_id VARCHAR(100) NULL,
    cost_per_click DECIMAL(10,2) NULL,

    CONSTRAINT pk_fact_click_events
        PRIMARY KEY (click_id),

    CONSTRAINT fk_fact_click_events_campaign
        FOREIGN KEY (campaign_id)
        REFERENCES dbo.dim_campaigns (campaign_id),

    CONSTRAINT fk_fact_click_events_customer
        FOREIGN KEY (user_id)
        REFERENCES dbo.dim_customers (user_id),

    CONSTRAINT ck_fact_click_events_cost_per_click
        CHECK (cost_per_click IS NULL OR cost_per_click >= 0)
);
GO

DROP TABLE IF EXISTS dbo.fact_lead_events;
CREATE TABLE dbo.fact_lead_events (
    lead_id BIGINT IDENTITY(1,1) NOT NULL,
    campaign_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    lead_created_at DATETIME2(0) NOT NULL,
    lead_source VARCHAR(50) NULL,
    contact_method VARCHAR(50) NULL,

    CONSTRAINT pk_fact_lead_events
        PRIMARY KEY (lead_id),

    CONSTRAINT fk_fact_lead_events_campaign
        FOREIGN KEY (campaign_id)
        REFERENCES dbo.dim_campaigns (campaign_id),

    CONSTRAINT fk_fact_lead_events_customer
        FOREIGN KEY (user_id)
        REFERENCES dbo.dim_customers (user_id)
);
GO

DROP TABLE IF EXISTS dbo.fact_conversion_events;
CREATE TABLE dbo.fact_conversion_events (
    conversion_id BIGINT IDENTITY(1,1) NOT NULL,
    campaign_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    converted_at DATETIME2(0) NOT NULL,
    revenue DECIMAL(12,2) NOT NULL,
    product_type VARCHAR(50) NULL,
    payment_type VARCHAR(50) NULL,

    CONSTRAINT pk_fact_conversion_events 
        PRIMARY KEY (conversion_id),

    CONSTRAINT fk_fact_conversion_events_campaign
        FOREIGN KEY (campaign_id)
        REFERENCES dbo.dim_campaigns (campaign_id),

    CONSTRAINT fk_fact_conversion_events_customer
        FOREIGN KEY (user_id)
        REFERENCES dbo.dim_customers (user_id),

    CONSTRAINT ck_fact_conversion_events_revenue
        CHECK (revenue >= 0)
);
GO