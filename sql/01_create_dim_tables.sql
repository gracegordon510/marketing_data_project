DROP TABLE IF EXISTS dbo.dim_campaigns;
CREATE TABLE dim_campaigns (
    campaign_id BIGINT IDENTITY(1,1),
    campaign_code VARCHAR(50) UNIQUE,
    campaign_name VARCHAR(100),
    campaign_type VARCHAR(50),
    target_audience VARCHAR(50),
    marketing_channel VARCHAR(50),
    campaign_language VARCHAR(50),
    start_date DATE,
    end_date DATE,
    is_active BIT NOT NULL DEFAULT 1,
    daily_budget DECIMAL(12, 2),
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),

    CONSTRAINT pk_dim_campaigns 
        PRIMARY KEY (campaign_id),

    CONSTRAINT uq_dim_campaigns_campaign_code 
        UNIQUE (campaign_code),

    CONSTRAINT ck_dim_campaigns_dates 
        CHECK (end_date IS NULL OR end_date >= start_date),

    CONSTRAINT ck_dim_campaigns_budget 
        CHECK (daily_budget IS NULL OR daily_budget >= 0)
);
GO

DROP TABLE IF EXISTS dbo.dim_customers;
CREATE TABLE dim_customers (
    customer_id BIGINT IDENTITY(1,1),
    email VARCHAR(255) UNIQUE,
    customer_segment VARCHAR(50),
    age_group VARCHAR(50),
    country VARCHAR(50),
    signup_date DATETIME2,
    create_at DATETIME2 NOT NULL DEFAULT GETDATE(),

    CONSTRAINT pk_dim_customers 
        PRIMARY KEY (customer_id),

    CONSTRAINT uq_dim_customers_email 
        UNIQUE (email)
);
GO

 
 
 
