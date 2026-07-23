/*==============================================================================
    File: 01_create_dimension_tables.sql
    Purpose: Create dimension tables for the marketing analytics warehouse.
==============================================================================*/

USE marketing_analytics;
GO

/*==============================================================================
    DIM_CUSTOMERS
==============================================================================*/

IF OBJECT_ID('dbo.dim_customers', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.dim_customers
    (
        customer_id          INT           NOT NULL,
        signup_date          DATE          NOT NULL,
        country              VARCHAR(10)   NOT NULL,
        age                  TINYINT       NOT NULL,
        gender               VARCHAR(20)   NOT NULL,
        loyalty_tier         VARCHAR(20)   NOT NULL,
        acquisition_channel  VARCHAR(30)   NOT NULL,

        CONSTRAINT pk_dim_customers
            PRIMARY KEY CLUSTERED (customer_id),

        CONSTRAINT ck_dim_customers_age
            CHECK (age BETWEEN 0 AND 120),

        CONSTRAINT ck_dim_customers_gender
            CHECK (
                gender IN (
                    'Male',
                    'Female',
                    'Other'
                )
            ),

        CONSTRAINT ck_dim_customers_loyalty_tier
            CHECK (
                loyalty_tier IN (
                    'Bronze',
                    'Silver',
                    'Gold',
                    'Platinum'
                )
            ),

        CONSTRAINT ck_dim_customers_acquisition_channel
            CHECK (
                acquisition_channel IN (
                    'Referral',
                    'Organic',
                    'Paid Search',
                    'Social',
                    'Email'
                )
            )
    );
END;
GO


/*==============================================================================
    DIM_PRODUCTS
==============================================================================*/

IF OBJECT_ID('dbo.dim_products', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.dim_products
    (
        product_id    INT            NOT NULL,
        category      VARCHAR(30)    NOT NULL,
        brand         VARCHAR(100)   NOT NULL,
        base_price    DECIMAL(12, 2) NOT NULL,
        launch_date   DATE           NOT NULL,
        is_premium    BIT            NOT NULL,

        CONSTRAINT pk_dim_products
            PRIMARY KEY CLUSTERED (product_id),

        CONSTRAINT ck_dim_products_category
            CHECK (
                category IN (
                    'Electronics',
                    'Fashion',
                    'Home',
                    'Grocery',
                    'Sport',
                    'Beauty'
                )
            ),

        CONSTRAINT ck_dim_products_base_price
            CHECK (base_price > 0)
    );
END;
GO


/*==============================================================================
    DIM_CAMPAIGNS
==============================================================================*/

IF OBJECT_ID('dbo.dim_campaigns', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.dim_campaigns
    (
        campaign_id       INT           NOT NULL,
        channel           VARCHAR(30)   NOT NULL,
        objective         VARCHAR(30)   NOT NULL,
        target_segment    VARCHAR(30)   NOT NULL,
        start_date        DATE          NULL,
        end_date          DATE          NULL,
        expected_uplift   DECIMAL(6, 4) NULL,

        CONSTRAINT pk_dim_campaigns
            PRIMARY KEY CLUSTERED (campaign_id),

        CONSTRAINT ck_dim_campaigns_channel
            CHECK (
                channel IN (
                    'Paid Search',
                    'Email',
                    'Affiliate',
                    'Display',
                    'Social',
                    'Unattributed'
                )
            ),

        CONSTRAINT ck_dim_campaigns_objective
            CHECK (
                objective IN (
                    'Acquisition',
                    'Cross-sell',
                    'Reactivation',
                    'Retention',
                    'Not Applicable'
                )
            ),

        CONSTRAINT ck_dim_campaigns_target_segment
            CHECK (
                target_segment IN (
                    'All',
                    'Churn Risk',
                    'Deal Seekers',
                    'High Value',
                    'New Customers',
                    'Not Applicable'
                )
            ),

        CONSTRAINT ck_dim_campaigns_expected_uplift
            CHECK (
                expected_uplift IS NULL
                OR expected_uplift BETWEEN 0 AND 1
            ),

        CONSTRAINT ck_dim_campaigns_date_order
            CHECK (
                start_date IS NULL
                OR end_date IS NULL
                OR end_date >= start_date
            )
    );
END;
GO