/*==============================================================================
    File: 03_create_fact_tables.sql
    Purpose: Create fact tables for marketing events and transactions.
==============================================================================*/

USE marketing_analytics;
GO

/*==============================================================================
    FACT_EVENTS
==============================================================================*/

IF OBJECT_ID('dbo.fact_events', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.fact_events
    (
        event_id               BIGINT          NOT NULL,
        event_timestamp        DATETIME2(0)    NOT NULL,
        event_type             VARCHAR(30)     NOT NULL,
        customer_id            INT             NOT NULL,
        product_id             INT             NULL,
        campaign_id            INT             NOT NULL,
        session_id             VARCHAR(100)    NULL,
        device_type            VARCHAR(20)     NULL,
        traffic_source         VARCHAR(30)     NOT NULL,
        page_category          VARCHAR(30)     NOT NULL,
        session_duration_sec   DECIMAL(12, 2)  NULL,
        experiment_group       VARCHAR(30)     NOT NULL,

        CONSTRAINT pk_fact_events
            PRIMARY KEY CLUSTERED (event_id),

        CONSTRAINT fk_fact_events_customer
            FOREIGN KEY (customer_id)
            REFERENCES dbo.dim_customers (customer_id),

        CONSTRAINT fk_fact_events_product
            FOREIGN KEY (product_id)
            REFERENCES dbo.dim_products (product_id),

        CONSTRAINT fk_fact_events_campaign
            FOREIGN KEY (campaign_id)
            REFERENCES dbo.dim_campaigns (campaign_id),

        CONSTRAINT ck_fact_events_event_type
            CHECK (
                event_type IN (
                    'View',
                    'Click',
                    'Add to Cart',
                    'Bounce',
                    'Purchase'
                )
            ),

        CONSTRAINT ck_fact_events_device_type
            CHECK (
                device_type IS NULL
                OR device_type IN (
                    'Desktop',
                    'Mobile',
                    'Tablet'
                )
            ),

        CONSTRAINT ck_fact_events_traffic_source
            CHECK (
                traffic_source IN (
                    'Email',
                    'Organic',
                    'Paid Search',
                    'Social',
                    'Direct'
                )
            ),

        CONSTRAINT ck_fact_events_page_category
            CHECK (
                page_category IN (
                    'PLP',
                    'PDP',
                    'Checkout',
                    'Home',
                    'Cart'
                )
            ),

        CONSTRAINT ck_fact_events_session_duration
            CHECK (
                session_duration_sec IS NULL
                OR session_duration_sec >= 0
            ),

        CONSTRAINT ck_fact_events_experiment_group
            CHECK (
                experiment_group IN (
                    'Control',
                    'Variant_A',
                    'Variant_B'
                )
            )
    );
END;
GO


/*==============================================================================
    FACT_TRANSACTIONS
==============================================================================*/

IF OBJECT_ID('dbo.fact_transactions', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.fact_transactions
    (
        transaction_id        BIGINT          NOT NULL,
        transaction_timestamp DATETIME2(0)    NOT NULL,
        customer_id           INT             NOT NULL,
        product_id            INT             NOT NULL,
        campaign_id           INT             NOT NULL,
        quantity              SMALLINT        NOT NULL,
        gross_revenue         DECIMAL(14, 2)  NOT NULL,
        discount_pct          DECIMAL(6, 4)   NOT NULL,
        refund_flag           BIT             NOT NULL,

        CONSTRAINT pk_fact_transactions
            PRIMARY KEY CLUSTERED (transaction_id),

        CONSTRAINT fk_fact_transactions_customer
            FOREIGN KEY (customer_id)
            REFERENCES dbo.dim_customers (customer_id),

        CONSTRAINT fk_fact_transactions_product
            FOREIGN KEY (product_id)
            REFERENCES dbo.dim_products (product_id),

        CONSTRAINT fk_fact_transactions_campaign
            FOREIGN KEY (campaign_id)
            REFERENCES dbo.dim_campaigns (campaign_id),

        CONSTRAINT ck_fact_transactions_quantity
            CHECK (quantity >= 1),

        CONSTRAINT ck_fact_transactions_discount_pct
            CHECK (discount_pct BETWEEN 0 AND 1)
    );
END;
GO