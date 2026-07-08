/*
  FACT TABLE INDEXES
*/

-- Fact Impressions
CREATE INDEX ix_fact_impression_events_campaign_id
    ON dbo.fact_impression_events (campaign_id);
GO

CREATE INDEX ix_fact_impression_events_customer_id
    ON dbo.fact_impression_events (customer_id);
GO

CREATE INDEX ix_fact_impression_events_shown_at
    ON dbo.fact_impression_events (shown_at);
GO


-- Fact Clicks
CREATE INDEX ix_fact_click_events_campaign_id
    ON dbo.fact_click_events (campaign_id);
GO

CREATE INDEX ix_fact_click_events_customer_id
    ON dbo.fact_click_events (customer_id);
GO

CREATE INDEX ix_fact_click_events_clicked_at
    ON dbo.fact_click_events (clicked_at);
GO


-- Fact Leads
CREATE INDEX ix_fact_lead_events_campaign_id
    ON dbo.fact_lead_events (campaign_id);
GO

CREATE INDEX ix_fact_lead_events_customer_id
    ON dbo.fact_lead_events (customer_id);
GO

CREATE INDEX ix_fact_lead_events_lead_created_at
    ON dbo.fact_lead_events (lead_created_at);
GO


-- Fact Conversions
CREATE INDEX ix_fact_conversion_events_campaign_id
    ON dbo.fact_conversion_events (campaign_id);
GO

CREATE INDEX ix_fact_conversion_events_customer_id
    ON dbo.fact_conversion_events (customer_id);
GO

CREATE INDEX ix_fact_conversion_events_converted_at
    ON dbo.fact_conversion_events (converted_at);
GO


/*
  DIMENSION TABLE INDEXES
*/

-- dim_campaigns
-- campaign_id PK index already exists
-- campaign_code UNIQUE index already exists

CREATE INDEX ix_dim_campaigns_campaign_type
    ON dbo.dim_campaigns (campaign_type);
GO

CREATE INDEX ix_dim_campaigns_channel_used
    ON dbo.dim_campaigns (channel_used);
GO

CREATE INDEX ix_dim_campaigns_is_active
    ON dbo.dim_campaigns (is_active);
GO


-- dim_customers
-- customer_id PK index already exists
-- email UNIQUE index already exists

CREATE INDEX ix_dim_customers_customer_segment
    ON dbo.dim_customers (customer_segment);
GO

CREATE INDEX ix_dim_customers_country
    ON dbo.dim_customers (country);
GO

CREATE INDEX ix_dim_customers_signup_date
    ON dbo.dim_customers (signup_date);
GO
