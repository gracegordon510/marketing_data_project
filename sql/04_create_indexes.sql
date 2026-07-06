CREATE INDEX idx_click_campaign_id
ON click_events(campaign_id);

CREATE INDEX idx_click_user_id
ON click_events(user_id);

CREATE INDEX idx_click_clicked_at
ON click_events(clicked_at);

CREATE INDEX idx_impression_campaign_id
ON impression_events(campaign_id);

CREATE INDEX idx_impression_user_id
ON impression_events(user_id);

CREATE INDEX idx_lead_campaign_id
ON lead_events(campaign_id);

CREATE INDEX idx_lead_user_id
ON lead_events(user_id);

CREATE INDEX idx_lead_created_at
ON lead_events(lead_created_at);

CREATE INDEX idx_conversion_campaign_id
ON conversion_events(campaign_id);

CREATE INDEX idx_conversion_user_id
ON conversion_events(user_id);

CREATE INDEX idx_conversion_converted_at
ON conversion_events(converted_at);