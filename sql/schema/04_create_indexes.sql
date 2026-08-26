/*==============================================================================
    File: 04_create_indexes.sql
    Purpose: Create indexes for joins, filters, and dashboard queries.
==============================================================================*/

USE marketing_analytics;
GO

/*==============================================================================
    FACT_EVENTS INDEXES
==============================================================================*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ix_fact_events_customer_id'
      AND object_id = OBJECT_ID('dbo.fact_events')
)
BEGIN
    CREATE NONCLUSTERED INDEX ix_fact_events_customer_id
        ON dbo.fact_events (customer_id);
END;
GO


IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ix_fact_events_product_id'
      AND object_id = OBJECT_ID('dbo.fact_events')
)
BEGIN
    CREATE NONCLUSTERED INDEX ix_fact_events_product_id
        ON dbo.fact_events (product_id);
END;
GO


IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ix_fact_events_campaign_id'
      AND object_id = OBJECT_ID('dbo.fact_events')
)
BEGIN
    CREATE NONCLUSTERED INDEX ix_fact_events_campaign_id
        ON dbo.fact_events (campaign_id);
END;
GO


IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ix_fact_events_timestamp'
      AND object_id = OBJECT_ID('dbo.fact_events')
)
BEGIN
    CREATE NONCLUSTERED INDEX ix_fact_events_timestamp
        ON dbo.fact_events (event_timestamp);
END;
GO


IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ix_fact_events_event_type'
      AND object_id = OBJECT_ID('dbo.fact_events')
)
BEGIN
    CREATE NONCLUSTERED INDEX ix_fact_events_event_type
        ON dbo.fact_events (event_type);
END;
GO


/*==============================================================================
    FACT_TRANSACTIONS INDEXES
==============================================================================*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ix_fact_transactions_customer_id'
      AND object_id = OBJECT_ID('dbo.fact_transactions')
)
BEGIN
    CREATE NONCLUSTERED INDEX ix_fact_transactions_customer_id
        ON dbo.fact_transactions (customer_id);
END;
GO


IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ix_fact_transactions_product_id'
      AND object_id = OBJECT_ID('dbo.fact_transactions')
)
BEGIN
    CREATE NONCLUSTERED INDEX ix_fact_transactions_product_id
        ON dbo.fact_transactions (product_id);
END;
GO


IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ix_fact_transactions_campaign_id'
      AND object_id = OBJECT_ID('dbo.fact_transactions')
)
BEGIN
    CREATE NONCLUSTERED INDEX ix_fact_transactions_campaign_id
        ON dbo.fact_transactions (campaign_id);
END;
GO


IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ix_fact_transactions_timestamp'
      AND object_id = OBJECT_ID('dbo.fact_transactions')
)
BEGIN
    CREATE NONCLUSTERED INDEX ix_fact_transactions_timestamp
        ON dbo.fact_transactions (transaction_timestamp);
END;
GO