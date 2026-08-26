/*==============================================================================
    File: 02_seed_reference_rows.sql
    Purpose: Insert required warehouse reference rows.
==============================================================================*/

USE marketing_analytics;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.dim_campaigns
    WHERE campaign_id = 0
)
BEGIN
    INSERT INTO dbo.dim_campaigns
    (
        campaign_id,
        channel,
        objective,
        target_segment,
        start_date,
        end_date,
        expected_uplift
    )
    VALUES
    (
        0,
        'Unattributed',
        'Not Applicable',
        'Not Applicable',
        NULL,
        NULL,
        NULL
    );
END;
GO